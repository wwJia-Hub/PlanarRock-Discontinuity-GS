function plot_convergence_curve(convergence_data, labels, N, M)
    % 绘制收敛曲线，支持单条或多条曲线对比
    % 输入参数：
    %   convergence_data: 收敛数据，可以是单行向量（单条曲线）或矩阵（每行一条曲线）
    %   labels: 每条曲线的标签，字符串数组或单元格数组
    %   N: 参数 N，用于图形显示
    %   M: 参数 M，用于图形显示
    
    % 确保输入数据格式正确
    if isvector(convergence_data)
        convergence_data = convergence_data(:)';  % 转为行向量
    end
    [num_curves, max_iter] = size(convergence_data);
    
    % 检查标签数量是否匹配
    if nargin < 2 || isempty(labels)
        labels = cell(1, num_curves);
        for i = 1:num_curves
            labels{i} = ['曲线 ', num2str(i)];
        end
    elseif length(labels) ~= num_curves
        error('标签数量与曲线数量不匹配');
    end
    
    % 创建图形，设置图形比例为长 4 宽 3
    figure('NumberTitle', 'off', 'Position', [100 100 400 300]);
    
    % 定义颜色，所有曲线使用实线
    colors = lines(num_curves);  % 自动生成颜色
    
    % 检查数据是否包含 NaN 或 Inf
    if any(isnan(convergence_data(:))) || any(isinf(convergence_data(:)))
        disp('Data contains NaN or Inf values');
        convergence_data(isnan(convergence_data)) = 0;  % 用 0 填充 NaN 值
        convergence_data(isinf(convergence_data)) = 0;  % 用 0 填充 Inf 值
    end
    
    % 对每条曲线进行归一化处理
    for i = 1:num_curves
        % 获取当前曲线的数据
        curve_data = convergence_data(i, :);
        
        % 归一化处理 (将数据映射到 [0, 1] 区间)
        curve_min = min(curve_data);
        curve_max = max(curve_data);
        if curve_max > curve_min  % 防止除以零
            normalized_curve = (curve_data - curve_min) / (curve_max - curve_min);
        else
            normalized_curve = curve_data;  % 如果曲线值没有变化，跳过归一化
        end
        
        % 仅绘制 0 到 100 轮的图像
        max_iter_to_plot = min(max_iter, 100);
        plot(1:max_iter_to_plot, normalized_curve(1:max_iter_to_plot), ...
             'Color', colors(i,:), ...  % 设置颜色
             'LineStyle', '-', ...      % 使用实线
             'LineWidth', 1.5);         % 设置线宽
        hold on;
    end
    
    % 在横坐标标签后面显示 N 和 M
    xlabel_str = strcat('Iteration number (N=', num2str(N), ', M=', num2str(M), ')');
    xlabel(xlabel_str, 'FontSize', 12, 'FontName', 'Times New Roman');
    ylabel('Mean normalized fitness', 'FontSize', 12, 'FontName', 'Times New Roman');
    
    % 图例设置，去除图例框
    legend(labels, 'Location', 'best', 'FontSize', 10, 'Box', 'off', 'FontName', 'Times New Roman');
    
    % 设置字体和样式
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 12);  % 使用Times New Roman字体
    axis tight;
    ylim([0, 1]);  % 设置y轴范围为0到1
    box on;  % 显示坐标轴边框
    
    % 取消显示网格
    grid off;
    
    hold off;
end
