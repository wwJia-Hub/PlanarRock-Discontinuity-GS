function D = computeSAADistanceMatrix(normals)
%COMPUTESAADISTANCEMATRIX 计算 SAA 距离矩阵（球面角距离 = 法向量夹角，弧度）
%
%   D = computeSAADistanceMatrix(normals)
%
% 输入：
%   normals - Nx3 单位法向量
% 输出：
%   D       - NxN 对称距离矩阵

    n = size(normals, 1);
    D = zeros(n, n);

    for i = 1:n
        for j = i + 1:n
            dot_product = dot(normals(i, :), normals(j, :));
            dot_product = max(min(dot_product, 1.0), -1.0);   % 避免 acos 数值误差
            angle = acos(dot_product);
            D(i, j) = angle;
            D(j, i) = angle;
        end
    end
end
