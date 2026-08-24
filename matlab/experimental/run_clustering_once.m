function [fig1, fig2, fig3, out] = run_clustering_once(full_path, a0, b0, min_component_size, cluster_num, SearchAgents_no, Max_iteration)
%RUN_CLUSTERING_ONCE  单次运行：读PLY、分簇、WOA寻优、出三张图，并返回统计信息
%
% [fig1, fig2, fig3, out] = run_clustering_once(full_path, a0, b0, min_component_size, ...
%                               cluster_num, SearchAgents_no, Max_iteration)
%
% 依赖外部函数（与你现有保持一致）：
%   compute, visualizeClusters, WOA, fitness, dip_distance, plotPoleFigure(或 plotPoleFigureClusters)
%
% 输出：
%   fig1: 初始三角簇可视化（final_class）
%   fig2: 极点图（indices_normals 的聚类 + WOA 中心）
%   fig3: 最终三角簇可视化（cluster）
%   out : 结构体：
%         .Best_pos(K,3)
%         .Best_score(1,1)
%         .labels(N_normals,1)                 % 每个法向→最近中心
%         .cluster(N_faces,1)                  % 每个三角面→簇号
%         .counts_normals(K,1)                 % 每簇法向数
%         .counts_faces(K,1)                   % 每簇三角面数
%         .final_index, .final_class, .indices_normals, .indices_area, .vertices, .faces

    % ====== 计算网格/法向/初簇 ======
    [final_index, final_class, indices_normals, indices_area, vertices, faces] = ...
        compute_num(full_path, a0, b0, min_component_size);

    % 图1：原始 final_class 可视化
    visualizeClusters(vertices, faces, final_index, final_class);
    fig1 = gcf;

    % 注意：原脚本里将 final_class +1 后用于索引（保持一致）
    final_class = final_class + 1;

    % ====== WOA 参数与适应度 ======
    X = indices_normals;
    ub = [1, 1, 0];      % 沿用你的上下界
    lb = [-1, -1, -1];
    %dim1 = cluster_num;  % 簇数
    dim2 = 3;            % 每个中心的维度
    sc=zeros(8, 1);
    %fobj = @(x) fitness(x, X, indices_area);

    % WOA 寻优
    % [Best_score, Best_pos, ~] = WOA(SearchAgents_no, Max_iteration, ub, lb, dim1, dim2, fobj);
    % 
    % % ====== 基于距离进行归属 ======
    % distances = dip_distance(X, Best_pos);
    % [~, labels] = min(distances, [], 2);    % 每个法向 → 最近中心的簇号
    % cluster = labels(final_class);          % 每个三角形的簇号

    for k = 2:8

dim1=k;

fobj = @(x)fitness(x,X,indices_area);
%fobj = @(x)fitness(x,X);


[Best_score,Best_pos,WOA_cg_curve]=WOA(SearchAgents_no,Max_iteration,ub,lb,dim1,dim2,fobj);

distances = dip_distance(X, Best_pos);
[~, labels] = min(distances, [], 2);
cluster = labels(final_class); 
%weights=indices_area;
% sc(k)=silhouetteCoefficient(X, labels,weights);
sc(k)=silhouetteCoefficient(X, labels);


% 在初始化时或k>=3时更新最优结果
if k == 2 || (k >= 3 && sc(k) > max_sc)
% if k >= 2
    final_Best_score = Best_score;
    final_Best_pos = Best_pos;
    final_WOA_cg_curve = WOA_cg_curve;
    final_num_k = k;
    final_cluster = cluster;
    final_labels=labels;
    max_sc = sc(k);  % 更新最大轮廓系数
    final_indices_normals=X;
end

end

    % 图2：极点图（如果你用的是我给你的 plotPoleFigureClusters，请替换下一行）
    % plotPoleFigureClusters(indices_normals, labels, Best_pos, 'Legend', false, 'CrossAtOrigin', false);
    plotPoleFigure(final_indices_normals, final_labels, final_Best_pos);
    fig2 = gcf;

    % 图3：最终三角簇可视化
    visualizeClusters(vertices, faces, final_index, final_cluster);
    fig3 = gcf;

    % ====== 统计信息 ======
    K = final_num_k;
    counts_normals = accumarray(final_labels, 1, [K,1]);   % 每簇法向个数
    counts_faces   = accumarray(final_cluster, 1, [K,1]);  % 每簇三角面个数

    % ====== 打包输出 ======
    out = struct( ...
        'Best_pos',        final_Best_pos, ...
        'Best_score',      final_Best_score, ...
        'labels',          final_labels, ...
        'cluster',         final_cluster, ...
        'counts_normals',  counts_normals, ...
        'counts_faces',    counts_faces, ...
        'final_index',     final_index, ...
        'final_class',     final_class, ...
        'indices_normals', indices_normals, ...
        'indices_area',    indices_area, ...
        'vertices',        vertices, ...
        'faces',           faces ...
    );
end
