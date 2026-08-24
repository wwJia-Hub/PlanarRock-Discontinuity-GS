function result = runDiscontinuityAnalysis(plyPath, params)
%RUNDISCONTINUITYANALYSIS 岩石结构面识别与分组完整流程（核心引擎）
%
%   result = runDiscontinuityAnalysis(plyPath)
%   result = runDiscontinuityAnalysis(plyPath, params)
%
% 流程：读取 PLY 网格 → 拉普拉斯平滑 → 面法线 → 区域生长分割
%       → WOA 鲸鱼算法聚类 → 轮廓系数确定最优分组数 K → 结果统计。
%
% 输入：
%   plyPath - PLY 网格文件路径（字符串）
%   params  - 可选参数结构体（缺省字段使用默认值）：
%       a0_deg              - 相邻面法线夹角阈值（度），默认 10
%       b0_deg              - 簇间法线夹角阈值（度），默认 10
%       min_component_size  - 最小结构面候选区域的面数，默认 85
%       smooth              - 是否平滑，默认 true
%       smooth_iterations   - 平滑迭代次数，默认 15
%       smooth_lambda       - 平滑因子，默认 0.3
%       SearchAgents_no     - WOA 种群数量，默认 300
%       Max_iteration       - WOA 最大迭代次数，默认 500
%       k_min, k_max        - 分组数搜索范围，默认 [2, 8]
%       verbose             - 是否打印过程信息，默认 true
%
% 输出：
%   result - 结构体，含 vertices/faces/normals/final_index/final_class/
%            indices_normals/indices_area/labels/cluster/Best_pos/Best_score/
%            num_k/counts_normals/counts_faces/silhouette/convergence/centers_azdip

    addpath(genpath(fileparts(mfilename('fullpath'))));

    % ---------- 参数默认值 ----------
    defaults = struct( ...
        'a0_deg', 10, ...
        'b0_deg', 10, ...
        'min_component_size', 85, ...
        'smooth', true, ...
        'smooth_iterations', 15, ...
        'smooth_lambda', 0.3, ...
        'SearchAgents_no', 300, ...
        'Max_iteration', 500, ...
        'k_min', 2, ...
        'k_max', 8, ...
        'verbose', true);

    if nargin < 2 || isempty(params)
        params = struct();
    end
    params = mergeStruct(defaults, params);
    params.k_min = max(2, round(params.k_min));
    params.k_max = max(params.k_min, round(params.k_max));

    if params.verbose
        fprintf('[1/4] 读取网格：%s\n', plyPath);
    end

    % ---------- 1. 读取网格 ----------
    mesh = readMesh_ply(plyPath);
    vertices = mesh.vertices;
    faces = mesh.faces;

    % ---------- 2. 平滑 ----------
    if params.smooth
        if params.verbose
            fprintf('[2/4] 拉普拉斯平滑（迭代 %d，λ=%.2f）...\n', ...
                params.smooth_iterations, params.smooth_lambda);
        end
        [vertices, faces] = meshSmoothing(vertices, faces, ...
            params.smooth_iterations, params.smooth_lambda);
    end

    % ---------- 3. 区域生长分割 ----------
    a0 = sind(params.a0_deg);
    b0 = sind(params.b0_deg);
    [final_index, final_class, indices_normals, indices_area, normals] = ...
        segmentMesh(vertices, faces, a0, b0, params.min_component_size);

    nRegions = size(indices_normals, 1);
    if params.verbose
        fprintf('[3/4] 分割得到 %d 个候选区域，%d 个有效面\n', ...
            nRegions, numel(final_index));
    end
    if nRegions < params.k_min
        warning('候选区域数（%d）少于最小分组数 k_min（%d），无法聚类。', ...
            nRegions, params.k_min);
        result = struct();
        return;
    end
    params.k_max = min(params.k_max, nRegions);   % 分组数不超过候选区域数

    % ---------- 4. WOA 聚类 + 轮廓系数选最优 K ----------
    final_class1 = final_class + 1;      % 转为 1-based 用于索引
    X = indices_normals;
    ub = [1, 1, 0];
    lb = [-1, -1, -1];
    dim2 = 3;

    sc = zeros(params.k_max, 1);
    max_sc = -inf;
    final_Best_score = inf;
    final_Best_pos = [];
    final_WOA_cg_curve = [];
    final_num_k = params.k_min;
    final_cluster = [];
    final_labels = [];

    if params.verbose
        fprintf('[4/4] WOA 聚类，K ∈ [%d, %d]...\n', params.k_min, params.k_max);
    end

    for k = params.k_min:params.k_max
        fobj = @(x) fitness(x, X, indices_area);
        [Best_score, Best_pos, WOA_cg_curve] = WOA(params.SearchAgents_no, ...
            params.Max_iteration, ub, lb, k, dim2, fobj);

        distances = dip_distance(X, Best_pos);
        [~, labels] = min(distances, [], 2);
        cluster = labels(final_class1);        % 每个三角面 -> 分组号
        sc(k) = silhouetteCoefficient(X, labels);

        if k == params.k_min || (k >= params.k_min + 1 && sc(k) > max_sc)
            final_Best_score = Best_score;
            final_Best_pos = Best_pos;
            final_WOA_cg_curve = WOA_cg_curve;
            final_num_k = k;
            final_cluster = cluster;
            final_labels = labels;
            max_sc = sc(k);
        end

        if params.verbose
            fprintf('    K = %d，轮廓系数 = %.4f\n', k, sc(k));
        end
    end

    % ---------- 5. 统计与打包 ----------
    K = final_num_k;
    counts_normals = accumarray(final_labels, 1, [K, 1]);
    counts_faces = accumarray(final_cluster, 1, [K, 1]);

    % 中心法向量 -> 倾向/倾角（上半球，与 plotPoleFigure 一致）
    Cn = final_Best_pos;
    nrm = sqrt(sum(Cn .^ 2, 2)); nrm(nrm == 0) = 1;
    Cn = Cn ./ nrm;
    Cn(Cn(:, 3) < 0, :) = -Cn(Cn(:, 3) < 0, :);
    az = atan2d(Cn(:, 2), Cn(:, 1)); az(az < 0) = az(az < 0) + 360;
    dp = asind(max(-1, min(1, Cn(:, 3))));

    result = struct( ...
        'vertices',        vertices, ...
        'faces',           faces, ...
        'normals',         normals, ...
        'final_index',     final_index, ...
        'final_class',     final_class, ...      % 0-based 区域标签
        'indices_normals', indices_normals, ...
        'indices_area',    indices_area, ...
        'labels',          final_labels, ...
        'cluster',         final_cluster, ...
        'Best_pos',        final_Best_pos, ...
        'Best_score',      final_Best_score, ...
        'num_k',           final_num_k, ...
        'counts_normals',  counts_normals, ...
        'counts_faces',    counts_faces, ...
        'silhouette',      sc, ...
        'convergence',     final_WOA_cg_curve, ...
        'centers_azdip',   [az, dp]);

    if params.verbose
        fprintf('完成：最优分组数 K = %d，最优轮廓系数 = %.4f\n', ...
            final_num_k, max_sc);
    end
end

function s = mergeStruct(defaults, overrides)
% 用 overrides 覆盖 defaults 中同名字段，返回合并后的结构体
    s = defaults;
    fn = fieldnames(overrides);
    for i = 1:numel(fn)
        s.(fn{i}) = overrides.(fn{i});
    end
end
