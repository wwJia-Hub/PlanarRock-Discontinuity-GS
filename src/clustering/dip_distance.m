function dist_matrix = dip_distance(samples, centers)
%DIP_DISTANCE 计算样本法向量到聚类中心的 SSA 距离
%
%   dist_matrix = dip_distance(samples, centers)
%
% 定义：d(i,j) = 1 - (Xi · Xj')^2，即法线夹角的正弦平方。
% 输入与输出均先归一化为单位向量。
%
% 输入：
%   samples - Mx3 样本法向量
%   centers - Nx3 聚类中心法向量
% 输出：
%   dist_matrix - MxN 距离矩阵

    samples = samples ./ sqrt(sum(samples .^ 2, 2));
    centers = centers ./ sqrt(sum(centers .^ 2, 2));

    dot_product = samples * centers';
    dist_matrix = 1 - dot_product .^ 2;
    dist_matrix = max(dist_matrix, 0);
end
