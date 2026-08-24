function SC = silhouetteCoefficient(X, labels)
%SILHOUETTECOEFFICIENT 计算平均轮廓系数（基于 SSA 距离）
%
%   SC = silhouetteCoefficient(X, labels)
%
% 输入：
%   X      - Nx3 样本法向量
%   labels - Nx1 聚类标签（从 1 开始）
% 输出：
%   SC     - 平均轮廓系数

    N = size(X, 1);
    k = max(labels);
    a = zeros(N, 1);
    b = zeros(N, 1);

    for i = 1:N
        % 簇内平均距离 a(i)
        sameCluster = X(labels == labels(i), :);
        sameCluster = sameCluster(~all(sameCluster == X(i, :), 2), :);
        a(i) = mean(dip_distance(X(i, :), sameCluster));

        % 到最近其他簇的平均距离 b(i)
        minDistance = Inf;
        for j = 1:k
            if j ~= labels(i)
                otherCluster = X(labels == j, :);
                minDistance = min(minDistance, mean(dip_distance(X(i, :), otherCluster)));
            end
        end
        b(i) = minDistance;
    end

    SC = mean((b - a) ./ max(a, b));
end
