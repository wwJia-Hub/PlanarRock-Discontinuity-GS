function DiscontinuityAnalyzer()
%DISCONTINUITYANALYZER 岩石结构面识别与分组 图形界面
%
% 在 MATLAB 命令行运行：  DiscontinuityAnalyzer
% 或直接双击本文件。
%
% 功能：
%   - 选择 PLY 网格文件
%   - 设置分割与 WOA 聚类参数
%   - 运行完整流程，展示分组结果表
%   - 按需绘制三维分组图、极点图、玫瑰图、收敛曲线
%   - 导出结果（.mat 与 CSV）
%
% 依赖：MATLAB R2018b 及以上（核心算法可在 R2016b+ 下通过 main.m 运行）。

    addpath(genpath(fileparts(mfilename('fullpath'))));

    % ---------- 共享状态 ----------
    app = struct();
    app.result = [];      % 最近一次分析结果
    app.plyPath = '';

    % ---------- 主窗口 ----------
    fig = uifigure('Name', '岩石结构面识别与分组', ...
        'Position', [100 100 1080 720], 'HandleVisibility', 'on');
    app.fig = fig;

    mainGrid = uigridlayout(fig, [1 2]);
    mainGrid.ColumnWidth = {420, '1x'};
    mainGrid.RowHeight = {'1x'};
    mainGrid.Padding = [10 10 10 10];
    mainGrid.ColumnSpacing = 12;

    % ================= 左：控制面板 =================
    leftPanel = uipanel(mainGrid, 'Title', '参数设置', 'FontWeight', 'bold');
    left = uigridlayout(leftPanel, [15 1]);
    left.RowHeight = repmat({'fit'}, 1, 15);
    left.RowSpacing = 5;
    left.Padding = [12 12 12 12];

    % --- 文件选择 ---
    uilabel(left, 'Text', 'PLY 网格文件', 'FontWeight', 'bold');
    fileGrid = uigridlayout(left, [1 2]);
    fileGrid.ColumnWidth = {'1x', 70};
    fileGrid.ColumnSpacing = 6;
    app.fileEdit = uieditfield(fileGrid, 'text', 'Value', '');
    app.browseBtn = uibutton(fileGrid, 'push', 'Text', '浏览...', ...
        'ButtonPushedFcn', @(src, evt) onBrowse());

    % --- 参数 ---
    app.a0Deg   = addParamRow(left, 'a0 相邻面夹角阈值 (度)', '10');
    app.b0Deg   = addParamRow(left, 'b0 簇间夹角阈值 (度)', '10');
    app.minSize = addParamRow(left, 'min_component_size 最小面数', '85');
    app.smoothChk = uicheckbox(left, 'Text', '启用拉普拉斯平滑', 'Value', 1);
    app.smoothIt = addParamRow(left, '平滑迭代次数', '15');
    app.smoothLa = addParamRow(left, '平滑因子 lambda', '0.3');
    app.nAgents  = addParamRow(left, 'WOA 种群数量', '300');
    app.maxIter  = addParamRow(left, 'WOA 最大迭代次数', '500');
    app.kMin     = addParamRow(left, '分组数下界 K_min', '2');
    app.kMax     = addParamRow(left, '分组数上界 K_max', '8');

    % --- 图形选项 ---
    uilabel(left, 'Text', '运行后绘制（弹出独立图窗）', 'FontWeight', 'bold');
    chkGrid = uigridlayout(left, [2 3]);
    chkGrid.RowHeight = {22, 22};
    app.chk3D   = uicheckbox(chkGrid, 'Text', '三维分组图', 'Value', 1);
    app.chkPole = uicheckbox(chkGrid, 'Text', '极点图', 'Value', 1);
    app.chkRose = uicheckbox(chkGrid, 'Text', '玫瑰图', 'Value', 1);
    app.chkNger = uicheckbox(chkGrid, 'Text', '南丁格尔图', 'Value', 0);
    app.chkConv = uicheckbox(chkGrid, 'Text', '收敛曲线', 'Value', 1);

    % --- 运行 / 导出 ---
    runGrid = uigridlayout(left, [1 2]);
    runGrid.ColumnWidth = {'1x', '1x'};
    runGrid.ColumnSpacing = 8;
    app.runBtn = uibutton(runGrid, 'push', 'Text', '运行分析', ...
        'BackgroundColor', [0.30 0.55 0.90], 'FontColor', [1 1 1], ...
        'FontWeight', 'bold', 'ButtonPushedFcn', @(src, evt) onRun());
    app.exportBtn = uibutton(runGrid, 'push', 'Text', '导出结果', ...
        'Enable', 'off', 'ButtonPushedFcn', @(src, evt) onExport());

    % ================= 右：结果面板 =================
    rightPanel = uipanel(mainGrid, 'Title', '结果', 'FontWeight', 'bold');
    right = uigridlayout(rightPanel, [2 1]);
    right.RowHeight = {110, '1x'};
    right.Padding = [12 12 12 12];
    right.RowSpacing = 8;

    app.statusArea = uitextarea(right, 'Value', {'就绪。请选择 PLY 文件并点击"运行分析"。'}, ...
        'Editable', 'off', 'FontName', 'Consolas');
    app.table = uitable(right, 'ColumnName', ...
        {'组号', '倾向(°)', '倾角(°)', '区域数', '面数'}, ...
        'ColumnWidth', {50, 80, 80, 80, 80});

    % ================= 回调 =================
    function onBrowse()
        [file, path] = uigetfile({'*.ply', 'PLY 网格文件 (*.ply)'}, '选择 PLY 网格文件');
        if isequal(file, 0)
            return;
        end
        app.plyPath = fullfile(path, file);
        app.fileEdit.Value = app.plyPath;
        setStatus(sprintf('已选择：%s', app.plyPath));
    end

    function onRun()
        app.plyPath = strtrim(app.fileEdit.Value);
        if isempty(app.plyPath) || ~exist(app.plyPath, 'file')
            errordlg('请先选择有效的 PLY 文件。', '输入错误');
            return;
        end

        params = readParams();
        app.runBtn.Enable = 'off';
        app.exportBtn.Enable = 'off';
        setStatus('正在运行分析，请稍候…（详细过程见命令行窗口）');
        drawnow;

        try
            app.result = runDiscontinuityAnalysis(app.plyPath, params);
            if isempty(app.result)
                errordlg('分析失败：候选区域数量不足，请降低 min_component_size 或调整阈值。', '运行失败');
                return;
            end
            updateTable();
            setStatus(sprintf('完成：最优分组数 K = %d，最优轮廓系数 = %.4f', ...
                app.result.num_k, max(app.result.silhouette(app.result.num_k))));
            drawPlots(params);
        catch ME
            setStatus(sprintf('运行出错：%s', ME.message));
            errordlg(ME.message, '运行出错');
        end
        app.runBtn.Enable = 'on';
        app.exportBtn.Enable = 'on';
    end

    function params = readParams()
        params = struct( ...
            'a0_deg',             readNum(app.a0Deg, 10), ...
            'b0_deg',             readNum(app.b0Deg, 10), ...
            'min_component_size', readNum(app.minSize, 85), ...
            'smooth',             app.smoothChk.Value, ...
            'smooth_iterations',  readNum(app.smoothIt, 15), ...
            'smooth_lambda',      readNum(app.smoothLa, 0.3), ...
            'SearchAgents_no',    readNum(app.nAgents, 300), ...
            'Max_iteration',      readNum(app.maxIter, 500), ...
            'k_min',              readNum(app.kMin, 2), ...
            'k_max',              readNum(app.kMax, 8));
    end

    function updateTable()
        r = app.result;
        data = cell(r.num_k, 5);
        for k = 1:r.num_k
            data(k, :) = {k, r.centers_azdip(k, 1), r.centers_azdip(k, 2), ...
                r.counts_normals(k), r.counts_faces(k)};
        end
        app.table.Data = data;
    end

    function drawPlots(params)
        r = app.result;
        if app.chk3D.Value
            visualizeClusters(r.vertices, r.faces, r.final_index, r.final_class);
            visualizeClusters(r.vertices, r.faces, r.final_index, r.cluster);
        end
        if app.chkPole.Value
            plotPoleFigure(r.indices_normals, r.labels, r.Best_pos, 'Legend', true);
        end
        if app.chkRose.Value
            plotPoleRose(r.indices_normals);
        end
        if app.chkNger.Value
            plotpoleNDGER(r.indices_normals);
        end
        if app.chkConv.Value
            plot_convergence_curve(r.convergence, {'WOA'}, ...
                params.Max_iteration, params.SearchAgents_no);
        end
    end

    function onExport()
        if isempty(app.result)
            return;
        end
        [file, path] = uiputfile({'*.mat', 'MATLAB 数据 (*.mat)'; '*.csv', 'CSV 表格 (*.csv)'}, ...
            '导出结果', 'discontinuity_results.mat');
        if isequal(file, 0)
            return;
        end
        outPath = fullfile(path, file);
        r = app.result;
        if strcmpi(regexprep(file, '.*\.', ''), 'csv')
            T = table((1:r.num_k)', r.centers_azdip(:, 1), r.centers_azdip(:, 2), ...
                r.counts_normals, r.counts_faces, ...
                'VariableNames', {'Group', 'Azimuth_deg', 'Dip_deg', 'NumRegions', 'NumFaces'});
            writetable(T, outPath);
        else
            save(outPath, 'r');
        end
        setStatus(sprintf('已导出：%s', outPath));
    end

    function setStatus(msg)
        app.statusArea.Value = {msg};
        drawnow;
    end
end

%% ================= 工具（文件级局部函数） =================
function field = addParamRow(parent, labelText, defaultText)
% 在父布局中新增一行（标签 + 数值文本框），返回编辑框句柄
    row = uigridlayout(parent, [1 2]);
    row.ColumnWidth = {'1x', 90};
    row.ColumnSpacing = 6;
    uilabel(row, 'Text', labelText);
    field = uieditfield(row, 'text', 'Value', defaultText);
end

function v = readNum(field, defaultVal)
% 读取文本框数值，失败时返回默认值
    v = str2double(strtrim(field.Value));
    if isnan(v) || isempty(v)
        v = defaultVal;
        field.Value = num2str(defaultVal);
    end
end
