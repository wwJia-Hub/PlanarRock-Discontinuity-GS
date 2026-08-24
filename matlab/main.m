% main.m — 岩石结构面识别与分组（非 GUI 脚本入口示例）
%
% 用法：
%   1) 在 MATLAB 中直接运行本脚本；
%   2) 或先修改下方参数与 PLY 路径，再运行；
%   3) 如需图形界面，运行 DiscontinuityAnalyzer。
%
% 流程：读 PLY → 平滑 → 区域生长分割 → WOA 聚类 → 轮廓系数选最优 K → 可视化。

clear; clc;
addpath(genpath(fileparts(mfilename('fullpath'))));

%% ================= 参数 =================
params = struct( ...
    'a0_deg', 10, ...            % 相邻面法线夹角阈值（度）
    'b0_deg', 10, ...            % 簇间法线夹角阈值（度）
    'min_component_size', 10, ...% 最小结构面区域的面数（示例网格较小，故设为 10）
    'smooth', true, ...          % 是否拉普拉斯平滑
    'smooth_iterations', 15, ... % 平滑迭代次数
    'smooth_lambda', 0.3, ...    % 平滑因子
    'SearchAgents_no', 100, ...  % WOA 种群数量
    'Max_iteration', 200, ...    % WOA 最大迭代次数
    'k_min', 2, ...              % 分组数下界
    'k_max', 8, ...              % 分组数上界
    'verbose', true);

% PLY 网格路径（默认使用随附的示例数据）
plyPath = fullfile(fileparts(mfilename('fullpath')), 'data', 'example_rock_slope.ply');

%% ================= 运行 =================
result = runDiscontinuityAnalysis(plyPath, params);

if isempty(result)
    error('分析失败，请检查输入数据与参数。');
end

%% ================= 可视化 =================
% 图1：初始区域分割（按区域着色）
visualizeClusters(result.vertices, result.faces, result.final_index, result.final_class);

% 图2：最终分组结果（按 WOA 分组着色）
visualizeClusters(result.vertices, result.faces, result.final_index, result.cluster);

% 图3：极点图（分组样本 + 聚类中心）
plotPoleFigure(result.indices_normals, result.labels, result.Best_pos, 'Legend', true);

% 图4：玫瑰图
plotPoleRose(result.indices_normals);

% 图5：南丁格尔玫瑰图
plotpoleNDGER(result.indices_normals);

% 图6：收敛曲线
plot_convergence_curve(result.convergence, {'WOA'}, ...
    params.Max_iteration, params.SearchAgents_no);

%% ================= 结果汇总（命令行） =================
fprintf('\n================ 结果汇总 ================\n');
fprintf('最优分组数 K = %d\n', result.num_k);
fprintf('最优轮廓系数 = %.4f\n', max(result.silhouette(result.num_k)));
fprintf('%-4s %8s %8s %10s %10s\n', '组号', '倾向(°)', '倾角(°)', '区域数', '面数');
for k = 1:result.num_k
    fprintf('%-4d %8.1f %8.1f %10d %10d\n', ...
        k, result.centers_azdip(k, 1), result.centers_azdip(k, 2), ...
        result.counts_normals(k), result.counts_faces(k));
end
fprintf('=========================================\n');
