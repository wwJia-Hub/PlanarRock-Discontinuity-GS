% 批处理主程序：遍历 a0、b0（角度，内部转 sind）、min_component_size 的所有组合
clear; clc;

% === 输入PLY路径与输出目录 ===
full_path = 'C:\Users\wwJia\Desktop\论文\数据\data1.ply';
outdir    = 'C:\Users\wwJia\Desktop\mesh_parts\batch_figs4';
if ~exist(outdir, 'dir'), mkdir(outdir); end

% === 其他参数（保持你的默认值，可调整） ===
cluster_num      = 3;
SearchAgents_no  = 200;
Max_iteration    = 300;

% === 参数列表 ===
a0_deg_list = [5 10 15 20];                 % a0 的角度值（度）
b0_deg_list = [5 10 15 20];                 % b0 的角度值（度）
mcs_list    = [25 50 75 100 125 150 175 200];          % min_component_size

% === CSV 汇总：每个组合的每个中心占一行 ===
csv_rows = {};   % 以 cell 累加，最后转 table
var_names = {'a0_deg','b0_deg','min_component_size', ...
             'center_id', ...
             'center_x','center_y','center_z', ...
             'center_az_deg','center_dip_deg', ...
             'normals_count','faces_count', ...
             'best_score'};

combo_count = numel(a0_deg_list)*numel(b0_deg_list)*numel(mcs_list);
fprintf('总组合数：%d\n', combo_count);

% === 三重循环 ===
for ia = 1:numel(a0_deg_list)
    for ib = 1:numel(b0_deg_list)
        for ic = 1:numel(mcs_list)

            a_deg = a0_deg_list(ia);
            b_deg = b0_deg_list(ib);
            mcs   = mcs_list(ic);

            % 实际传入 compute 的阈值：sin(角度)
            a0 = sind(a_deg);
            b0 = sind(b_deg);

            try
                [f1, f2, f3, out] = run_clustering_once( ...
                    full_path, a0, b0, mcs, ...
                    cluster_num, SearchAgents_no, Max_iteration);

                % === 保存 .fig，文件名格式：a0-b0-min_component_size-图n.fig（a0/b0用角度便于识别） ===
                base = sprintf('%d-%d-%d', a_deg, b_deg, mcs);
                savefig(f1, fullfile(outdir, sprintf('%s-图1.fig', base)));
                savefig(f2, fullfile(outdir, sprintf('%s-图2.fig', base)));
                savefig(f3, fullfile(outdir, sprintf('%s-图3.fig', base)));

                % === 组装 CSV 行（每个中心一行） ===
                K = cluster_num;
                C = out.Best_pos;                                 % K×3
                % 规范化到上半球并转 az/dip，便于人读
                nrm = sqrt(sum(C.^2,2)); nrm(nrm==0) = 1;
                Cn = C ./ nrm;
                Cn(Cn(:,3) < 0, :) = -Cn(Cn(:,3) < 0, :);
                az = atan2d(Cn(:,2), Cn(:,1)); az(az<0) = az(az<0)+360;
                dp = asind(max(-1,min(1,Cn(:,3))));

                for k = 1:K
                    csv_rows(end+1,1:12) = { ...
                        a_deg, b_deg, mcs, ...
                        k, ...
                        C(k,1), C(k,2), C(k,3), ...
                        az(k), dp(k), ...
                        out.counts_normals(k), out.counts_faces(k), ...
                        out.Best_score};
                end

            catch ME
                warning('组合 %d-%d-%d 运行失败：%s', a_deg, b_deg, mcs, ME.message);
            end

            % 关闭图窗以节省内存
            try, close(f1); catch, end
            try, close(f2); catch, end
            try, close(f3); catch, end
        end
    end
end

% === 写 CSV ===
T = cell2table(csv_rows, 'VariableNames', var_names);
csv_path = fullfile(outdir, 'summary.csv');
writetable(T, csv_path);
fprintf('已写出 CSV：%s\n', csv_path);

disp('批处理完成。');

