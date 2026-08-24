function normals = meshFaceNormals(vertices, faces)
%MESHFACENORMALS 计算每个三角面的单位法向量（向量化）
%
%   normals = meshFaceNormals(vertices, faces)
%
% 输入：
%   vertices - Nx3 顶点坐标
%   faces    - Mx3 三角面索引（1-based）
% 输出：
%   normals  - Mx3 单位面法向量

    v1 = vertices(faces(:, 1), :);
    v2 = vertices(faces(:, 2), :);
    v3 = vertices(faces(:, 3), :);

    % 两条边叉积得到法向量（未归一化）
    normals = cross(v2 - v1, v3 - v1, 2);

    % 归一化，退化面（面积为 0）给零向量，避免除零
    len = sqrt(sum(normals .^ 2, 2));
    len(len < 1e-12) = 1;
    normals = normals ./ len;
end
