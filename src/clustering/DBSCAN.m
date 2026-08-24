function [IDX, isnoise] = DBSCAN(X, Eps, MinPts)
%DBSCAN 基于 SAA 距离（法线夹角）的 DBSCAN 聚类
%
%   [IDX, isnoise] = DBSCAN(X, Eps, MinPts)
%
% 输入：
%   X       - Nx3 单位法向量 [nx, ny, nz]
%   Eps     - 邻域半径阈值（弧度，法线夹角）
%   MinPts  - 核心点所需的最小邻域点数
% 输出：
%   IDX     - 簇标签（0 为未分配，-1 为噪声，>0 为簇编号）
%   isnoise - 噪声标记（逻辑向量）

    n = size(X, 1);
    IDX = zeros(n, 1);
    visited = false(n, 1);
    isnoise = false(n, 1);
    C = 0;

    % 预计算 SAA 距离矩阵（对称，法线夹角）
    D = computeSAADistanceMatrix(X);

    for i = 1:n
        if ~visited(i)
            visited(i) = true;
            Neighbors = RegionQuery(i);
            if numel(Neighbors) < MinPts
                isnoise(i) = true;
            else
                C = C + 1;
                ExpandCluster(i, Neighbors, C);
            end
        end
    end

    function ExpandCluster(i, Neighbors, C)
        IDX(i) = C;
        k = 1;
        while k <= numel(Neighbors)
            j = Neighbors(k);
            if ~visited(j)
                visited(j) = true;
                Neighbors2 = RegionQuery(j);
                if numel(Neighbors2) >= MinPts
                    Neighbors = [Neighbors Neighbors2]; %#ok<AGROW>
                end
            end
            if IDX(j) == 0
                IDX(j) = C;
            end
            k = k + 1;
        end
    end

    function Neighbors = RegionQuery(i)
        Neighbors = find(D(i, :) <= Eps);
    end
end
