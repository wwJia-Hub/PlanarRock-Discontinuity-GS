function [vertices, faces] = meshSmoothing(vertices, faces, iterations, lambda)
    % 网格平滑算法（拉普拉斯平滑）
    % 输入：
    %   vertices - 顶点坐标矩阵，每行是一个顶点的(x,y,z)
    %   faces - 面索引矩阵，每行是一个面的三个顶点索引
    %   iterations - 平滑迭代次数
    %   lambda - 平滑因子（0~1之间）
    % 输出：
    %   vertices - 平滑后的顶点坐标
    %   faces - 面索引（不变）
    
    % 构建顶点邻接表
    numVertices = size(vertices, 1);
    adjacency = cell(numVertices, 1);
    
    % 从面信息构建邻接关系
    for i = 1:size(faces, 1)
        v1 = faces(i, 1);
        v2 = faces(i, 2);
        v3 = faces(i, 3);
        
        adjacency{v1} = unique([adjacency{v1}; v2; v3]);
        adjacency{v2} = unique([adjacency{v2}; v1; v3]);
        adjacency{v3} = unique([adjacency{v3}; v1; v2]);
    end
    
    % 执行平滑迭代
    for iter = 1:iterations
        newVertices = vertices;  % 保存新位置，避免影响当前迭代
        
        for v = 1:numVertices
            neighbors = adjacency{v};
            if isempty(neighbors)
                continue;  % 孤立顶点不处理
            end
            
            % 计算邻域顶点的平均位置
            avgPos = mean(vertices(neighbors, :), 1);
            
            % 拉普拉斯更新：新位置 = 原位置 + 因子*(平均位置 - 原位置)
            newVertices(v, :) = vertices(v, :) + lambda * (avgPos - vertices(v, :));
        end
        
        vertices = newVertices;  % 更新顶点位置
    end
end

% 示例用法
% 读取网格数据（假设obj格式，这里简化处理）
% [vertices, faces] = readObj('input.obj');
% 
% % 平滑参数
% iterations = 10;  % 迭代次数
% lambda = 0.5;     % 平滑因子
% 
% % 执行平滑
% [smoothedVertices, faces] = meshSmoothing(vertices, faces, iterations, lambda);
% 
% % 写入结果
% writeObj('smoothed.obj', smoothedVertices, faces);