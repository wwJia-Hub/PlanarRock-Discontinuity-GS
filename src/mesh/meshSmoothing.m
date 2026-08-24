function [vertices, faces] = meshSmoothing(vertices, faces, iterations, lambda)
%MESHSMOOTHING 拉普拉斯网格平滑
%
%   [vertices, faces] = meshSmoothing(vertices, faces, iterations, lambda)
%
% 输入：
%   vertices   - Nx3 顶点坐标
%   faces      - Mx3 三角面索引（1-based）
%   iterations - 平滑迭代次数
%   lambda     - 平滑因子（0~1 之间）
% 输出：
%   vertices   - 平滑后的顶点坐标
%   faces      - 面索引（不变）

    numVertices = size(vertices, 1);
    adjacency = cell(numVertices, 1);

    % 由面信息构建顶点邻接关系
    for i = 1:size(faces, 1)
        v1 = faces(i, 1);
        v2 = faces(i, 2);
        v3 = faces(i, 3);
        adjacency{v1} = unique([adjacency{v1}; v2; v3]);
        adjacency{v2} = unique([adjacency{v2}; v1; v3]);
        adjacency{v3} = unique([adjacency{v3}; v1; v2]);
    end

    % 迭代平滑
    for iter = 1:iterations
        newVertices = vertices;
        for v = 1:numVertices
            neighbors = adjacency{v};
            if isempty(neighbors)
                continue;   % 孤立顶点跳过
            end
            avgPos = mean(vertices(neighbors, :), 1);
            newVertices(v, :) = vertices(v, :) + lambda * (avgPos - vertices(v, :));
        end
        vertices = newVertices;
    end
end
