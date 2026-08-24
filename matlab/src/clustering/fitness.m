function fit = fitness(x, data, weights)
%FITNESS 聚类目标函数：加权 SSA 距离之和（越小越好）
%
%   fit = fitness(x, data, weights)
%
% 输入：
%   x       - 聚类中心矩阵（K x 3，单位法向量）
%   data    - 样本法向量矩阵（N x 3）
%   weights - 每个样本的权重（N x 1，通常为对应区域的面数）
% 输出：
%   fit     - 加权后的距离总和（缩放 1000 倍）

    distances = dip_distance(data, x);
    min_values = min(distances, [], 2);
    fit = 1000 * sum(min_values .* weights);

    if isnan(fit)
        fit = inf;
    end
end
