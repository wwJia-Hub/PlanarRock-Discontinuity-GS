function [Leader_score, Leader_pos, Convergence_curve] = ...
        WOA(SearchAgents_no, Max_iter, ub, lb, dim1, dim2, fobj)
%WOA 鲸鱼优化算法（Whale Optimization Algorithm）
%
%   [Leader_score, Leader_pos, Convergence_curve] = ...
%       WOA(SearchAgents_no, Max_iter, ub, lb, dim1, dim2, fobj)
%
% 参考：S. Mirjalili, A. Lewis, "The Whale Optimization Algorithm",
%       Advances in Engineering Software, 2016.
%       DOI: 10.1016/j.advengsoft.2016.01.008
%
% 输入：
%   SearchAgents_no - 种群（鲸鱼）数量
%   Max_iter        - 最大迭代次数
%   ub, lb          - 每个维度的上/下界（1 x dim2）
%   dim1            - 搜索代理矩阵行数（聚类中心数 K）
%   dim2            - 搜索代理矩阵列数（每个中心维度，通常为 3）
%   fobj            - 目标函数句柄，输入 dim1 x dim2 矩阵，输出标量
%
% 输出：
%   Leader_score      - 最优目标函数值（最小化）
%   Leader_pos        - 最优位置（dim1 x dim2）
%   Convergence_curve - 每轮迭代的最优值（1 x Max_iter）

    Leader_pos = zeros(dim1, dim2);
    Leader_score = inf;   % 最小化问题，初始化为正无穷

    Positions = initialization(SearchAgents_no, dim1, dim2, ub, lb);
    Convergence_curve = zeros(1, Max_iter);

    t = 0;
    while t < Max_iter
        for i = 1:size(Positions, 1)
            % 越界修正
            position = Positions{i};
            Flag4ub = position > ub;
            Flag4lb = position < lb;
            current_pos = position .* (~(Flag4ub | Flag4lb)) + ub .* Flag4ub + lb .* Flag4lb;
            Positions{i} = current_pos;

            % 计算适应度并更新全局最优
            fitness_val = fobj(Positions{i});
            if fitness_val < Leader_score
                Leader_score = fitness_val;
                Leader_pos = Positions{i};
            end
        end

        % 参数 a 随迭代从 2 递减到 0
        a = (2 - t * ((2) / Max_iter)) * (1 - (t ^ 3) * ((1) / (Max_iter ^ 3)));
        % a2 从 -1 线性递减到 -2
        a2 = -1 + t * ((-1) / Max_iter);

        for i = 1:size(Positions, 1)
            r1 = rand();
            r2 = rand();

            A = 2 * a * r1 - a;   % A ∈ [-a, a]
            C = 2 * r2;           % C ∈ [0, 2]

            b = 1;
            l = (a2 - 1) * rand + 1;   % l ∈ [a2, 1]
            p = rand();

            position = Positions{i};

            for j = 1:size(position, 1)
                for k = 1:size(position, 2)
                    if p < 0.5
                        if abs(A) >= 1
                            rand_leader_index = floor(SearchAgents_no * rand() + 1);
                            X_rand = Positions{rand_leader_index};
                            D_X_rand = abs(C * X_rand(j, k) - position(j, k));
                            position(j, k) = X_rand(j, k) - A * D_X_rand;
                        elseif abs(A) < 1
                            D_Leader = abs(C * Leader_pos(j, k) - position(j, k));
                            position(j, k) = Leader_pos(j, k) - A * D_Leader;
                        end
                    elseif p >= 0.5
                        distance2Leader = abs(Leader_pos(j, k) - position(j, k));
                        position(j, k) = distance2Leader * exp(b .* l) .* cos(l .* 2 * pi) + Leader_pos(j, k);
                    end
                end
            end
            Positions{i} = position;
        end

        t = t + 1;
        Convergence_curve(t) = Leader_score;
    end
end
