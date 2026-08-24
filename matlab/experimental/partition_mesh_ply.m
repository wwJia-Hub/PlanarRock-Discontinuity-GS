function [part, info] = partition_mesh_ply(in_ply, nparts, outdir, addGhost)
% PARTITION_MESH_PLY
% 读取 ASCII PLY（带顶点与面），构建对偶图（面=节点，共边=边），
% 进行谱聚类图划分到 nparts 个子块，并尽量均衡。可选添加一圈幽灵层。
%
% 依赖：MATLAB R2018a+（需要 sparse/eigs/kmeans），无第三方工具箱。

if nargin < 4, addGhost = false; end
if nargin < 3 || isempty(outdir), outdir = 'parts_out'; end
if ~exist(outdir,'dir'), mkdir(outdir); end

% 1) 读取 PLY（ASCII）
[V, F] = read_ply_ascii(in_ply);      % V: Nx3, F: cell array of face vertex indices

% 将多边形统一三角化（用于后续稳健性；若已三角网可直接跳过）
[Ftri, faceMap] = triangulate_faces(F);  %#ok<NASGU> % faceMap 可用于回溯

% 以“面”为节点构建对偶图
A = dual_adjacency(Ftri);              % 稀疏对称邻接矩阵 (m x m), m=三角面数

% 2) 谱嵌入 + kmeans 划分
m = size(A,1);
if nparts <= 1 || m==0
    part = ones(m,1);
else
    D = spdiags(sum(A,2), 0, m, m);
    % 归一化拉普拉斯 L = I - D^{-1/2} A D^{-1/2}
    Dinvsq = spdiags(1./sqrt(max(sum(A,2),eps)),0,m,m);
    L = speye(m) - Dinvsq*A*Dinvsq;

    k = min(nparts, max(2, min(15, m))); % 取前 k 个最小特征向量
    try
        % 取最小的 k 个特征向量（去掉平凡特征向量）
        [U, ~] = eigs(L, k, 'smallestreal', 'Tolerance',1e-4, 'MaxIterations',5000);
    catch
        % 退化到稍大的公差
        [U, ~] = eigs(L, k, 'smallestreal');
    end
    % 常做法：去掉第一列（常量方向），若 k==2 则只用第2列
    if k > 1
        X = U(:,2:k);
    else
        X = U; % 极小图时也容错
    end
    % 归一化行向量
    X = bsxfun(@rdivide, X, sqrt(sum(X.^2,2))+eps);

    % 初始 kmeans（重复多次求稳）
    rng(42);
    raw = kmeans(full(X), nparts, 'Replicates',8, 'MaxIter',500, 'Display','off');
    % 3) 轻量“容量约束”平衡（近似均衡每块面数）
    target = ceil(m / nparts);
    part = balance_partition(raw, A, target);
end

% 4) 统计接口、幽灵层
[interfaces, ghosts] = build_interfaces_and_ghosts(part, A, nparts, addGhost);

% 5) 导出子网格（PLY）
write_parts_ply(V, Ftri, part, outdir, ghosts);

% 汇总信息
info = struct();
info.A = A;                % 对偶图
info.interfaces = interfaces;
info.ghosts = ghosts;
info.outdir = outdir;

fprintf('Done. Faces: %d, Parts: %d\n', size(Ftri,1), nparts);
end

% ---------- 工具函数们 ----------

function [V, F] = read_ply_ascii(fname)
% 仅支持常见 ASCII PLY，包含：
% element vertex N
%  property float x/y/z
% element face M
%  property list uchar int vertex_indices
fid = fopen(fname,'r');
assert(fid>0, 'Cannot open %s', fname);
cleanup = onCleanup(@() fclose(fid));

% 读头
line = fgetl(fid);
assert(startsWith(line,'ply'), 'Not a PLY file');
format = '';
nV = 0; nF = 0; propV = {};
while true
    line = fgetl(fid);
    assert(ischar(line), 'Unexpected EOF in header');
    if startsWith(line,'format')
        format = strtrim(line);
        assert(contains(format,'ascii'), 'Only ASCII PLY supported in this reader.');
    elseif startsWith(line,'element vertex')
        tok = textscan(line, 'element vertex %d'); nV = tok{1};
    elseif startsWith(line,'element face')
        tok = textscan(line, 'element face %d'); nF = tok{1};
    elseif startsWith(line,'property') && nF==0
        propV{end+1} = line; %#ok<AGROW>
    elseif strcmp(line,'end_header')
        break;
    end
end

% 读顶点
V = zeros(nV,3);
for i=1:nV
    vals = sscanf(fgetl(fid), '%f');
    V(i,1:3) = vals(1:3);
end

% 读面
F = cell(nF,1);
for i=1:nF
    vals = sscanf(fgetl(fid), '%d');
    c = vals(1);
    idx = vals(2:1+c) + 1; % 0-based -> 1-based
    F{i} = idx(:)';
end
end

function [Ftri, faceMap] = triangulate_faces(F)
% 将任意多边形面扇形三角化；若本身是三角面则保持。
% 返回 Ftri: (m x 3) 三角索引，faceMap: 每个三角对应原始面的编号
m = 0;
for i=1:numel(F)
    c = numel(F{i});
    if c<3, continue; end
    m = m + (c-2);
end
Ftri = zeros(m,3,'uint32');
faceMap = zeros(m,1,'uint32');
ptr = 1;
for i=1:numel(F)
    verts = F{i};
    c = numel(verts);
    if c==3
        Ftri(ptr,:) = uint32(verts);
        faceMap(ptr) = i;
        ptr = ptr+1;
    elseif c>3
        % 简单扇形三角化 (v1, vj, vj+1)
        for j=2:c-1
            Ftri(ptr,:) = uint32([verts(1), verts(j), verts(j+1)]);
            faceMap(ptr) = i;
            ptr = ptr+1;
        end
    end
end
end

function A = dual_adjacency(Ftri)
% 构建对偶图邻接：两个三角面共享一条边则相邻
m = size(Ftri,1);
% 为每条边创建键（有向两次 -> 再去重）
E = [Ftri(:,[1 2]); Ftri(:,[2 3]); Ftri(:,[3 1])];
E = sort(E,2); % 无向边
% 用 containers.Map 聚合边 -> 面列表
key = uint64(E(:,1)) * uint64(2^32-5) + uint64(E(:,2));
[ukey,~,ic] = unique(key);
cellsPerEdge = accumarray(ic, (1:numel(ic))', [], @(v){v});
% 建立邻接集合
I = []; J = [];
for k=1:numel(ukey)
    idx = cellsPerEdge{k};
    % idx 是边出现的位置；映射回三角编号
    triIdx = mod(idx-1, size(Ftri,1)) + 1;
    triIdx = unique(triIdx);
    if numel(triIdx)==2
        I(end+1:end+2) = triIdx;         %#ok<AGROW>
        J(end+1:end+2) = triIdx([2 1]);  %#ok<AGROW>
    end
end
A = sparse(I, J, 1, m, m);
A = spones(triu(A,1)) + spones(triu(A,1))'; % 对称 0/1
end

function part = balance_partition(raw, A, target)
% 轻量均衡：先用 raw，若某些簇超额，就把其“边界面”优先移动到欠额簇。
m = numel(raw);
k = max(raw);
part = raw;
slack = 1; % 容差
sizes = accumarray(part,1,[k,1]);

% 预计算每个面的邻居列表
[N_i, N_j, ~] = find(A);
nbrs = accumarray(N_i, N_j, [], @(v){v});

% 循环直到所有簇 <= target+slack 或无法改进
changed = true; it=0; itMax=20;
while changed && it<itMax
    changed = false; it=it+1;
    over = find(sizes > target+slack);
    under = find(sizes < target);
    if isempty(over) || isempty(under), break; end

    for oc = over(:)'
        % 候选：属于 oc 且在边界的面
        members = find(part==oc);
        isBoundary = false(size(members));
        cutLoss = zeros(size(members));
        for t=1:numel(members)
            f = members(t);
            nb = nbrs{f};
            if any(part(nb) ~= oc)
                isBoundary(t) = true;
                % 迁出 oc 会减少多少跨边？估计：与 oc 外邻居的数量 - 与 oc 内邻居数量差
                cutLoss(t) = sum(part(nb)~=oc) - sum(part(nb)==oc);
            end
        end
        cand = members(isBoundary);
        loss = cutLoss(isBoundary);

        % 优先移动 cutLoss 大的（减少割边），并尝试送往最欠额的 under 簇
        [~,ord] = sort(loss,'descend');
        for t=ord(:)'
            f = cand(t);
            if isempty(under), break; end
            % 选择一个“近邻 under 簇”，否则就选当前最欠额簇
            nb = nbrs{f};
            nbParts = unique(part(nb));
            targetChoices = intersect(nbParts, under);
            if isempty(targetChoices)
                continue;  % 没有邻域内的欠额簇就别移动
            end
            % 选当前最欠额的
            [~,ix] = min(sizes(targetChoices));
            tc = targetChoices(ix);

            % 迁移
            part(f) = tc;
            sizes(oc) = sizes(oc)-1;
            sizes(tc) = sizes(tc)+1;
            changed = true;

            % 更新 under/over 集合
            under = find(sizes < target);
            if sizes(oc) <= target+slack, break; end
        end
    end
end
end

function [interfaces, ghosts] = build_interfaces_and_ghosts(part, A, nparts, addGhost)
% 接口：跨分区的相邻对；幽灵层：为每个分区添加一圈邻接面
m = numel(part);

% 接口边（跨分区的三角面对偶边）
[ri, rj] = find(triu(A,1));
cross = part(ri) ~= part(rj);
ri = ri(cross); rj = rj(cross);

interfaces = cell(nparts,1);
for p=1:nparts
    mask = (part(ri)==p) | (part(rj)==p);
    e = [ri(mask), rj(mask)];
    interfaces{p} = e;
end

ghosts = cell(nparts,1);
if addGhost
    % 对每个分区：所有与该分区拥有面相邻的面，减去自身拥有的面 -> 幽灵层
    for p=1:nparts
        own = find(part==p);
        if isempty(own), ghosts{p} = []; continue; end
        nb = find(A(:,own)*ones(numel(own),1) > 0);  % 与 own 相邻的所有面
        ghosts{p} = setdiff(nb, own);                % 去掉本区拥有面
    end
end
end


function write_parts_ply(V, Ftri, part, outdir, ghosts)
% 为每个分区写一个 ASCII PLY：仅包含该分区拥有的面（不含幽灵）
nparts = max(part);
for p=1:nparts
    owns = find(part==p);
    if isempty(owns), continue; end
    % 提取相关顶点并重建局部索引
    faces = Ftri(owns,:);
    vids = unique(faces(:));
    map = zeros(size(V,1),1); map(vids) = 1:numel(vids);
    faces_mapped = [map(faces(:,1)), map(faces(:,2)), map(faces(:,3))];

    fout = fullfile(outdir, sprintf('part_%02d.ply', p));
    write_ply_ascii(fout, V(vids,:), faces_mapped);

    % 可选：幽灵层也另存一份索引清单
    if ~isempty(ghosts) && numel(ghosts)>=p && ~isempty(ghosts{p})
        gfile = fullfile(outdir, sprintf('part_%02d_ghost_faces.txt', p));
        dlmwrite(gfile, ghosts{p}, 'delimiter','\t');
    end
end
end

function write_ply_ascii(fname, V, Ftri)
fid = fopen(fname,'w'); assert(fid>0);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'ply\n');
fprintf(fid, 'format ascii 1.0\n');
fprintf(fid, 'element vertex %d\n', size(V,1));
fprintf(fid, 'property float x\nproperty float y\nproperty float z\n');
fprintf(fid, 'element face %d\n', size(Ftri,1));
fprintf(fid, 'property list uchar int vertex_indices\n');
fprintf(fid, 'end_header\n');
fprintf(fid, '%.9f %.9f %.9f\n', V');
fprintf(fid, '3 %d %d %d\n', (Ftri-1)'); % 转回 0-based
end
