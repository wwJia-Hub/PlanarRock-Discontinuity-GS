function [vertices, faces, normals] = FaceNormals(vertices, faces)
    % 计算面法线并移除退化三角形
    
    % 计算法线（不处理退化情况）
    v1 = vertices(faces(:,1), :);
    v2 = vertices(faces(:,2), :);
    v3 = vertices(faces(:,3), :);
    
    edge1 = v2 - v1;
    edge2 = v3 - v1;
    normals = cross(edge1, edge2);
    normal_lengths = sqrt(sum(normals.^2, 2));
    
    % 归一化法线
    normals = normals ./ normal_lengths;
    
    % 找出有效三角形（非退化）
    valid_faces = normal_lengths > 1e-10;
    
    % 统计并警告
    num_invalid = sum(~valid_faces);
    if num_invalid > 0
        warning('移除了 %d 个退化三角形 (共 %d 个)', num_invalid, size(faces, 1));
        
        % 过滤数据
        faces = faces(valid_faces, :);
        normals = normals(valid_faces, :);
        
        % 移除未使用的顶点
        if ~isempty(faces)
            used_vertices = unique(faces(:));
            
            % 创建正确的顶点映射（使用ismember替代直接索引）
            [~, vertex_map] = ismember(faces, used_vertices);
            faces = reshape(vertex_map, size(faces));
            
            % 更新顶点
            vertices = vertices(used_vertices, :);
        else
            warning('所有三角形均为退化，返回空网格');
            vertices = zeros(0, 3);
            faces = zeros(0, 3);
            normals = zeros(0, 3);
        end
    end
end