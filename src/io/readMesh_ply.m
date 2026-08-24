function mesh = readMesh_ply(filename)
%READMESH_PLY 读取 PLY 网格文件，返回含 vertices 与 faces 的结构体
%
%   mesh = readMesh_ply(filename)
%
% 支持：
%   - ASCII PLY 与 binary PLY（little/big endian）
%   - 顶点属性 x/y/z
%   - 面属性 vertex_indices（list 类型），多边形自动扇形三角化
%
% 返回：
%   mesh.vertices - Nx3 顶点坐标
%   mesh.faces    - Mx3 三角面索引（1-based）
%
% 说明：仅解析项目需要的顶点坐标与面拓扑；其余属性被忽略。

    fid = fopen(filename, 'r');
    if fid < 0
        error('readMesh_ply:openFailed', '无法打开文件：%s', filename);
    end
    cleanup = onCleanup(@() fclose(fid));

    % ---------- 解析文件头 ----------
    line = fgetl(fid);
    if ~ischar(line) || ~strncmpi(strtrim(line), 'ply', 3)
        error('readMesh_ply:notPly', '不是有效的 PLY 文件：%s', filename);
    end

    format = 'ascii';           % ascii | binary_little_endian | binary_big_endian
    nVertices = 0;
    nFaces = 0;
    vertexPropNames = {};       % 顶点属性名（按顺序）
    facePropNames = {};         % 面属性名（按顺序）

    while true
        line = fgetl(fid);
        if ~ischar(line)
            break;
        end
        line = strtrim(line);
        if isempty(line)
            continue;
        end
        lowerLine = lower(line);

        if startsWith(lowerLine, 'format')
            if contains(lowerLine, 'ascii')
                format = 'ascii';
            elseif contains(lowerLine, 'binary_little_endian')
                format = 'binary_little_endian';
            elseif contains(lowerLine, 'binary_big_endian')
                format = 'binary_big_endian';
            else
                error('readMesh_ply:badFormat', '不支持的 PLY 格式：%s', line);
            end
        elseif startsWith(lowerLine, 'element vertex')
            tok = sscanf(line, 'element vertex %d');
            nVertices = tok(1);
        elseif startsWith(lowerLine, 'element face')
            tok = sscanf(line, 'element face %d');
            nFaces = tok(1);
        elseif startsWith(lowerLine, 'property')
            % 属性行：property <type> <name>
            parts = strsplit(line);
            propName = parts{end};
            if nFaces == 0
                vertexPropNames{end+1} = propName; %#ok<AGROW>
            else
                facePropNames{end+1} = propName; %#ok<AGROW>
            end
        elseif strcmpi(lowerLine, 'end_header')
            break;
        end
    end

    % 定位 x/y/z 顶点属性的列号
    ix = find(strcmpi(vertexPropNames, 'x'), 1);
    iy = find(strcmpi(vertexPropNames, 'y'), 1);
    iz = find(strcmpi(vertexPropNames, 'z'), 1);
    if isempty(ix) || isempty(iy) || isempty(iz)
        error('readMesh_ply:noXYZ', 'PLY 顶点缺少 x/y/z 属性：%s', filename);
    end
    nVertexProps = numel(vertexPropNames);

    % 定位 face vertex_indices 属性（list 类型）
    % 由于 list 属性占两列（count + indices），通过"该属性是否是 list"来识别列偏移。
    % 这里约定：vertex_indices 必须是 list 属性；据此重建面索引。
    ivert = find(strcmpi(facePropNames, 'vertex_indices'), 1);
    if isempty(ivert)
        error('readMesh_ply:noFaces', 'PLY 面缺少 vertex_indices 属性：%s', filename);
    end

    if strcmp(format, 'ascii')
        % ---------- ASCII ----------
        vertices = zeros(nVertices, 3);
        for i = 1:nVertices
            vals = sscanf(fgetl(fid), '%f');
            vertices(i, 1) = vals(ix);
            vertices(i, 2) = vals(iy);
            vertices(i, 3) = vals(iz);
        end

        faceCells = cell(nFaces, 1);
        for i = 1:nFaces
            vals = sscanf(fgetl(fid), '%d');
            c = vals(1);                    % 顶点个数
            idx = vals(2:1+c) + 1;          % 0-based -> 1-based
            faceCells{i} = idx(:)';
        end
    else
        % ---------- binary ----------
        machine = 'ieee-le';
        if strcmp(format, 'binary_big_endian')
            machine = 'ieee-be';
        end
        % 读取顶点块（假定标量属性全为 float，本函数只关心 x/y/z）
        % 逐行用 fread 按 float 读取更稳健，兼容常见的 float 属性。
        vData = fread(fid, nVertices * nVertexProps, 'float32', 0, machine);
        vData = reshape(vData, nVertexProps, nVertices)';
        vertices = [vData(:, ix), vData(:, iy), vData(:, iz)];

        % 读取面块：每个面先读一个 uchar count，再读 count 个 int32 索引
        faceCells = cell(nFaces, 1);
        for i = 1:nFaces
            c = fread(fid, 1, 'uint8=>double', 0, machine);
            idx = fread(fid, c, 'int32=>double', 0, machine) + 1; %#ok<FREAD>
            faceCells{i} = idx(:)';
        end
    end

    % ---------- 扇形三角化 ----------
    faces = triangulateFaces(faceCells);

    mesh = struct('vertices', vertices, 'faces', faces);
end

function faces = triangulateFaces(faceCells)
% 将任意多边形面扇形三角化；三角形保持不变
    nTri = 0;
    for i = 1:numel(faceCells)
        c = numel(faceCells{i});
        if c >= 3
            nTri = nTri + (c - 2);
        end
    end
    faces = zeros(nTri, 3);
    ptr = 1;
    for i = 1:numel(faceCells)
        v = faceCells{i};
        c = numel(v);
        if c == 3
            faces(ptr, :) = v;
            ptr = ptr + 1;
        elseif c > 3
            for j = 2:c-1
                faces(ptr, :) = [v(1), v(j), v(j+1)];
                ptr = ptr + 1;
            end
        end
    end
end
