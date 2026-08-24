% 初始化并行池
if isempty(gcp('nocreate'))
    parpool('local');
end
tic;

%% 参数设置
a0 = cos(deg2rad(10));       % 相邻三角面法线夹角阈值
b0 = cos(deg2rad(30));       % 簇间法线夹角阈值
min_component_size = 50;     % 最小三角簇大小
num_blocks = 4;              % 分块数量（建议等于CPU核心数）
overlap = 20;                % 子块重叠区域大小（避免边界信息丢失）


%% 1. 读取网格数据
mesh = readMesh_ply('C:\Users\wwJia\Desktop\Mesh5.ply');
vertices = mesh.vertices;
faces = mesh.faces;
faceAreas = meshFaceAreas(vertices, faces);
normals = meshFaceNormals(vertices, faces);
mesh_size = length(faces);


%% 2. 网格分块（带重叠）
block_size = floor(mesh_size / num_blocks);
blocks = cell(num_blocks, 1);  % 存储每个子块的面索引

for k = 1:num_blocks
    start_idx = (k-1)*block_size + 1;
    end_idx = min(k*block_size, mesh_size);
    % 扩展边界（重叠区域）
    start_idx = max(1, start_idx - overlap);
    end_idx = min(mesh_size, end_idx + overlap);
    blocks{k} = start_idx:end_idx;  % 子块面索引（含重叠）
end


%% 3. 并行处理各子块（返回局部结果，不修改全局变量）
% 预分配存储每个子块的局部结果
local_results = cell(num_blocks, 1);

parfor k = 1:num_blocks  % parfor 中只生成局部结果，不修改全局变量
    block_faces = blocks{k};  % 当前子块的面索引
    block_size_k = length(block_faces);
    
    % 子块内局部变量（仅在当前worker中有效）
    local_marked = zeros(1, mesh_size);  % 局部标记（全局面索引）
    local_tag = 1;
    local_T = cell(1, block_size_k);    % 局部簇的平均法线
    local_S = zeros(1, block_size_k);   % 局部簇的总面积
    local_SN = cell(1, block_size_k);   % 局部簇的法线加权和
    
    % 子块内聚类（与原逻辑一致）
    for i = 1:block_size_k
        face_idx = block_faces(i);
        if local_marked(face_idx) == 0
            % 查找子块内的相邻面
            neighbors = findVertexSharingFaces(faces, face_idx);
            neighbors_in_block = intersect(neighbors, block_faces);  % 仅保留子块内的面
            
            % 筛选符合条件的相邻面
            normal_i = normals(face_idx, :);
            cos_angles = sum(repmat(normal_i, length(neighbors_in_block), 1) .* normals(neighbors_in_block, :), 2);
            valid_neighbors = neighbors_in_block(cos_angles > a0);
            
            % 初始化当前簇
            min_tag = local_tag;
            local_S(min_tag) = faceAreas(face_idx);
            local_SN{min_tag} = faceAreas(face_idx) .* normals(face_idx, :);
            
            % 累加相邻面到簇
            for j = 1:length(valid_neighbors)
                n_idx = valid_neighbors(j);
                local_S(min_tag) = local_S(min_tag) + faceAreas(n_idx);
                local_SN{min_tag} = local_SN{min_tag} + faceAreas(n_idx) .* normals(n_idx, :);
            end
            
            % 计算平均法线
            if local_S(min_tag) > 0
                local_T{min_tag} = local_SN{min_tag} / local_S(min_tag);
                local_T{min_tag} = local_T{min_tag} / norm(local_T{min_tag});
            else
                local_T{min_tag} = [0, 0, 0];
            end
            
            % 合并子块内的小簇
            for j = 1:length(valid_neighbors)
                n_idx = valid_neighbors(j);
                n_tag = local_marked(n_idx);
                if n_tag > 0 && n_tag < min_tag && dot(local_T{min_tag}, local_T{n_tag}) > b0
                    % 合并到更小的标签
                    local_S(n_tag) = local_S(n_tag) + local_S(min_tag);
                    local_SN{n_tag} = local_SN{n_tag} + local_SN{min_tag};
                    local_T{n_tag} = local_SN{n_tag} / local_S(n_tag);
                    local_T{n_tag} = local_T{n_tag} / norm(local_T{n_tag});
                    min_tag = n_tag;
                end
            end
            
            % 更新局部标记
            local_marked(face_idx) = min_tag;
            for j = 1:length(valid_neighbors)
                local_marked(valid_neighbors(j)) = min_tag;
            end
            local_tag = local_tag + 1;
        end
    end
    
    % 存储当前子块的局部结果（使用更明确的字段名）
    local_results{k} = struct(...
        'markedFaces', local_marked, ...
        'clusterNormals', local_T, ...
        'clusterAreas', local_S, ...
        'weightedNormals', local_SN, ...
        'processedFaces', block_faces ...
    );
end


%% 4. 合并局部结果（解决重叠区域冲突）
% 初始化全局标记和簇信息
global_marked = zeros(1, mesh_size);
global_T = cell(1, 0);
global_S = [];
global_SN = cell(1, 0);
global_tag = 1;

% 遍历所有子块的局部结果，合并到全局
for k = 1:num_blocks
    res = local_results{k};
    block_faces = res.processedFaces;
    local_marked = res.markedFaces;
    local_T = res.clusterNormals;
    local_S = res.clusterAreas;
    local_SN = res.weightedNormals;
    
    % 处理当前子块的面
    for i = 1:length(block_faces)
        face_idx = block_faces(i);
        local_tag = local_marked(face_idx);
        if local_tag == 0
            continue;  % 未标记的面跳过
        end
        
        % 若该面已被其他子块标记，检查是否需要合并
        if global_marked(face_idx) > 0
            global_tag_exist = global_marked(face_idx);
            % 比较两个簇的法线，决定是否合并
            if dot(global_T{global_tag_exist}, local_T{local_tag}) > b0
                % 合并到已存在的全局标签
                global_S(global_tag_exist) = global_S(global_tag_exist) + local_S(local_tag);
                global_SN{global_tag_exist} = global_SN{global_tag_exist} + local_SN{local_tag};
                global_T{global_tag_exist} = global_SN{global_tag_exist} / global_S(global_tag_exist);
                global_T{global_tag_exist} = global_T{global_tag_exist} / norm(global_T{global_tag_exist});
            end
        else
            % 该面未被标记，新增全局标签
            global_marked(face_idx) = global_tag;
            global_T{global_tag} = local_T{local_tag};
            global_S(global_tag) = local_S(local_tag);
            global_SN{global_tag} = local_SN{local_tag};
            global_tag = global_tag + 1;
        end
    end
end


%% 5. 全局聚类（合并跨子块的簇）
all_tags = unique(global_marked(global_marked > 0));
num_global_tags = length(all_tags);

% 合并满足条件的全局簇
for i = 1:num_global_tags
    tag1 = all_tags(i);
    if tag1 > length(global_S) || global_S(tag1) == 0
        continue;
    end
    for j = i+1:num_global_tags
        tag2 = all_tags(j);
        if tag2 > length(global_S) || global_S(tag2) == 0
            continue;
        end
        % 检查法线夹角
        if dot(global_T{tag1}, global_T{tag2}) > b0
            % 合并到较小的标签
            if tag1 < tag2
                global_S(tag1) = global_S(tag1) + global_S(tag2);
                global_SN{tag1} = global_SN{tag1} + global_SN{tag2};
                global_T{tag1} = global_SN{tag1} / global_S(tag1);
                global_T{tag1} = global_T{tag1} / norm(global_T{tag1});
                % 更新标记
                global_marked(global_marked == tag2) = tag1;
                global_S(tag2) = 0;  % 标记为已合并
            else
                global_S(tag2) = global_S(tag2) + global_S(tag1);
                global_SN{tag2} = global_SN{tag2} + global_SN{tag1};
                global_T{tag2} = global_SN{tag2} / global_S(tag2);
                global_T{tag2} = global_T{tag2} / norm(global_T{tag2});
                % 更新标记
                global_marked(global_marked == tag1) = tag2;
                global_S(tag1) = 0;  % 标记为已合并
            end
        end
    end
end


%% 6. 过滤小簇并可视化
final_tags = unique(global_marked(global_marked > 0));
final_class = [];
final_index = [];
class = 0;

for tag = final_tags
    cluster_faces = find(global_marked == tag);
    if length(cluster_faces) >= min_component_size
        final_class = [final_class; repmat(class, length(cluster_faces), 1)];
        final_index = [final_index; cluster_faces'];
        class = class + 1;
    end
end

% 可视化
visualizeClusters(vertices, faces, final_index, final_class);
toc;
delete(gcp);  % 关闭并行池