function areas = meshFaceAreas(vertices, faces)
%MESHFACEAREAS 计算每个三角面的面积（向量化）
%
%   areas = meshFaceAreas(vertices, faces)
%
% 输入：
%   vertices - Nx3 顶点坐标
%   faces    - Mx3 三角面索引（1-based）
% 输出：
%   areas    - Mx1 面面积

    v1 = vertices(faces(:, 1), :);
    v2 = vertices(faces(:, 2), :);
    v3 = vertices(faces(:, 3), :);

    % 面积 = 0.5 * |(v2-v1) x (v3-v1)|
    crossVec = cross(v2 - v1, v3 - v1, 2);
    areas = 0.5 * sqrt(sum(crossVec .^ 2, 2));
end
