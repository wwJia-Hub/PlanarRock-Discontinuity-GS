function Positions = initialization(SearchAgents_no, dim1, dim2, ub, lb)
%INITIALIZATION 初始化搜索代理种群（每个代理为 dim1 x dim2 矩阵）
%
%   Positions = initialization(SearchAgents_no, dim1, dim2, ub, lb)
%
% 输入：
%   SearchAgents_no - 代理数量
%   dim1, dim2      - 每个代理矩阵的维度
%   ub, lb          - 每个维度的上/下界（标量或 1 x dim2 向量）
% 输出：
%   Positions       - SearchAgents_no x 1 的 cell 数组

    Boundary_no = size(ub, 2);
    Positions = cell(SearchAgents_no, 1);

    for i = 1:SearchAgents_no
        Position = zeros(dim1, dim2);
        if Boundary_no == 1
            Position = rand(dim1, dim2) * (ub - lb) + lb;
        else
            for j = 1:dim2
                Position(:, j) = rand(dim1, 1) * (ub(j) - lb(j)) + lb(j);
            end
        end
        Positions{i} = Position;
    end
end
