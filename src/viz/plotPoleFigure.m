function plotPoleFigure(samples, labels, centers, varargin)
%PLOTPOLEFIGURE 在极点图上绘制带聚类标签的样本与聚类中心
%
%   plotPoleFigure(samples, labels, centers, Name, Value)
%
% 输入：
%   samples : Nx3 法向量 [x,y,z] 或 Nx2 [az°, dip°]
%   labels  : Nx1 样本簇标签（任意类型）
%   centers : Kx3 或 Kx2 聚类中心（可空 []）
%
% 可选参数（Name-Value）：
%   'Colormap'        （默认 'lines'）
%   'SampleSize'      （默认 12）
%   'CenterSize'      （默认 28）
%   'CenterMarker'    （默认 {'s','^','d','v','o'}）
%   'Legend'          （默认 true）
%   'Title'           （默认 '极点图 (Clusters & Centers)'）
%   'ShowDensity'     （默认 true）
%   'GridResolution'  （默认 [90,180]）
%   'SmoothSigma'     （默认 [1.5,2]）
%   'CrossAtOrigin'   （默认 false）
%   'CenterScale'     （默认 4）
%   'CenterVivid'     （默认 [100,100]）

    p = inputParser;
    addParameter(p, 'Colormap', 'lines');
    addParameter(p, 'SampleSize', 12);
    addParameter(p, 'CenterSize', 28);
    addParameter(p, 'CenterMarker', {'s', '^', 'd', 'v', 'o'});
    addParameter(p, 'Legend', true);
    addParameter(p, 'Title', '极点图 (Clusters & Centers)');
    addParameter(p, 'ShowDensity', true);
    addParameter(p, 'GridResolution', [90, 180]);
    addParameter(p, 'SmoothSigma', [1.5, 2]);
    addParameter(p, 'CrossAtOrigin', false);
    addParameter(p, 'CrossRadius', 3);
    addParameter(p, 'CenterScale', 4);
    addParameter(p, 'CenterVivid', [100, 100]);
    parse(p, varargin{:});
    o = p.Results;

    if nargin < 2, error('至少需要 samples 与 labels'); end
    if size(samples, 1) ~= numel(labels)
        error('samples 行数与 labels 长度不一致');
    end
    if isempty(centers), centers = []; end

    % 统一到 (az°, dip°)
    [az_s, dp_s, mask_s] = toAzDip(samples);
    labels = labels(mask_s);
    if isempty(az_s), warning('没有有效样本'); return; end

    if ~isempty(centers)
        [az_c, dp_c, mask_c] = toAzDip(centers);
        az_c = az_c(mask_c); dp_c = dp_c(mask_c);
    else
        az_c = []; dp_c = [];
    end

    [~, ~, L] = unique(labels, 'stable');
    K = max(1, numel(unique(L)));
    cmap = buildColormap(o.Colormap, K);

    % 底层 Cartesian 轴做密度填充
    Rmax = 90;
    fig = figure('Color', 'w');
    axB = axes('Parent', fig); %#ok<LAXES>
    axis(axB, 'equal'); axis(axB, 'off'); hold(axB, 'on');
    xlim(axB, [-Rmax Rmax]); ylim(axB, [-Rmax Rmax]);

    if o.ShowDensity
        try
            drawDensityFill(axB, dp_s, az_s, o);
        catch ME
            warning(ME.identifier, '%s', ME.message);
        end
    end

    % 上层 polaraxes
    axP = polaraxes('Parent', fig, 'Color', 'none'); %#ok<LAXES>
    axP.Position = axB.Position;
    set(axP, 'ThetaZeroLocation', 'top', 'ThetaDir', 'clockwise');
    rlim(axP, [0 90]);
    rticks(axP, [0 30 60 90]);
    thetaticks(axP, 0:45:315);
    grid(axP, 'on'); hold(axP, 'on');
    title(axP, o.Title);

    % 隐藏径向 30/60/90 标签（仅保留 0）
    lbl = arrayfun(@num2str, rticks(axP), 'UniformOutput', false);
    if ~isempty(lbl)
        lbl(:) = {''};
        rticklabels(axP, lbl);
    end

    if o.CrossAtOrigin
        r0 = o.CrossRadius;
        polarplot(axP, [0 0], [0 r0], 'k-', 'LineWidth', 1.1);
        polarplot(axP, [pi/2 pi/2], [0 r0], 'k-', 'LineWidth', 1.1);
    end

    % 绘制样本
    usePS = ~isempty(which('polarscatter'));
    for k = 1:K
        m = (L == k);
        if ~any(m), continue; end
        th = deg2rad(az_s(m)); rr = dp_s(m);
        if usePS
            polarscatter(axP, th, rr, o.SampleSize, cmap(k, :), ...
                'filled', 'MarkerEdgeColor', [0 0 0], ...
                'MarkerFaceAlpha', 0.9, 'MarkerEdgeAlpha', 0.7);
        else
            polarplot(axP, th, rr, 'o', 'LineStyle', 'none', ...
                'MarkerSize', max(4, round(sqrt(o.SampleSize) / 1.6)), ...
                'MarkerFaceColor', cmap(k, :), 'MarkerEdgeColor', [0 0 0]);
        end
    end

    % 每簇均值方向（用于中心匹配）
    mu = zeros(K, 3);
    for k = 1:K
        mu(k, :) = mean(unit3D_from_azdip(az_s(L == k), dp_s(L == k)), 1);
        nrm = norm(mu(k, :));
        if nrm > 0, mu(k, :) = mu(k, :) / nrm; end
    end

    % 绘制中心（与样本同色系，更鲜艳、稍大）
    if ~isempty(az_c)
        C = unit3D_from_azdip(az_c, dp_c);
        M = size(C, 1);
        if M > 0
            S = mu * C.';
            if M == K
                center_to_cluster = zeros(M, 1);
                Swork = S;
                usedK = false(K, 1); usedM = false(M, 1);
                for t = 1:K
                    Swork(usedK, :) = -Inf; Swork(:, usedM) = -Inf;
                    [~, idx] = max(Swork(:));
                    [ik, im] = ind2sub(size(Swork), idx);
                    center_to_cluster(im) = ik;
                    usedK(ik) = true; usedM(im) = true;
                end
            else
                [~, center_to_cluster] = max(S, [], 1);
                center_to_cluster = center_to_cluster(:);
            end

            for i = 1:M
                th = deg2rad(az_c(i)); rr = dp_c(i);
                k = center_to_cluster(i);
                baseColor = cmap(k, :);
                vividColor = vividifyColor(baseColor, o.CenterVivid(1), o.CenterVivid(2));

                sz_eff = max(o.CenterSize, o.SampleSize * 2.4);
                sz_eff = round(sz_eff * o.CenterScale);

                mk = o.CenterMarker{1 + mod(i - 1, numel(o.CenterMarker))};
                if usePS
                    polarscatter(axP, th, rr, sz_eff, vividColor, ...
                        'filled', 'Marker', mk, ...
                        'MarkerEdgeColor', [0 0 0], ...
                        'MarkerFaceAlpha', 1.0, 'MarkerEdgeAlpha', 0.9);
                else
                    polarplot(axP, th, rr, mk, 'LineStyle', 'none', ...
                        'MarkerSize', max(5, round(sqrt(sz_eff) / 1.4)), ...
                        'MarkerFaceColor', vividColor, 'MarkerEdgeColor', [0 0 0], ...
                        'LineWidth', 1.0);
                end
            end
        else
            warning('centers 经筛选后为空，跳过中心绘制。');
        end
    end

    % 图例
    if o.Legend
        hold(axP, 'on');
        hS = gobjects(K, 1);
        hC = gobjects(K, 1);
        hasCenter = false(K, 1);
        if exist('center_to_cluster', 'var') && ~isempty(center_to_cluster)
            for k = 1:K
                hasCenter(k) = any(center_to_cluster == k);
            end
        end
        for k = 1:K
            hS(k) = polarplot(axP, NaN, NaN, 'o', ...
                'MarkerFaceColor', cmap(k, :), 'MarkerEdgeColor', [0 0 0], ...
                'DisplayName', sprintf('J%d', k));
            if hasCenter(k)
                baseColor = cmap(k, :);
                vividColor = vividifyColor(baseColor, o.CenterVivid(1), o.CenterVivid(2));
                mk = o.CenterMarker{1 + mod(k - 1, numel(o.CenterMarker))};
                hC(k) = polarplot(axP, NaN, NaN, mk, ...
                    'MarkerFaceColor', vividColor, 'MarkerEdgeColor', [0 0 0], ...
                    'LineWidth', 1.0, 'DisplayName', sprintf('JC_{%d}', k));
            else
                hC(k) = gobjects(1);
            end
        end
        hAll = [hS(:); hC(hasCenter)];
        legend(axP, hAll, 'Location', 'eastoutside');
    end
end

%% ===== 工具：samples/centers 转 az-dip =====
function [azimuth, dip, valid_mask] = toAzDip(X)
    [~, m] = size(X);
    if m == 3
        nrm = sqrt(sum(X .^ 2, 2));
        valid_mask = nrm > 1e-12 & all(isfinite(X), 2);
        if ~any(valid_mask), azimuth = []; dip = []; return; end
        V = X(valid_mask, :) ./ nrm(valid_mask);
        V(V(:, 3) < 0, :) = -V(V(:, 3) < 0, :);
        azimuth = atan2d(V(:, 2), V(:, 1)); azimuth(azimuth < 0) = azimuth(azimuth < 0) + 360;
        dip = asind(max(-1, min(1, V(:, 3))));
    elseif m == 2
        valid_mask = all(isfinite(X), 2);
        if ~any(valid_mask), azimuth = []; dip = []; return; end
        azimuth = mod(X(valid_mask, 1), 360);
        dip = max(0, min(90, X(valid_mask, 2)));
    else
        error('输入必须为 n×3 或 n×2');
    end
end

%% ===== 工具：构建色图 =====
function cmap = buildColormap(spec, K)
    if isnumeric(spec)
        if size(spec, 2) ~= 3, error('Colormap 必须为 k×3 RGB'); end
        if size(spec, 1) < K
            rep = ceil(K / size(spec, 1));
            cmap = repmat(spec, rep, 1);
            cmap = cmap(1:K, :);
        else
            cmap = spec(1:K, :);
        end
        return;
    end
    switch lower(char(spec))
        case 'lines',  cmap = lines(K);
        case 'hsv',    cmap = hsv(K);
        case 'parula', t = parula(max(K, 64)); cmap = t(round(linspace(1, size(t, 1), K)), :);
        case 'turbo',  t = turbo(max(K, 64));  cmap = t(round(linspace(1, size(t, 1), K)), :);
        otherwise,     warning('未知 Colormap "%s"，使用 lines', spec); cmap = lines(K);
    end
end

%% ===== 工具：az-dip -> 单位 3D 向量（上半球） =====
function V = unit3D_from_azdip(az, dp)
    x = cosd(az) .* cosd(dp);
    y = sind(az) .* cosd(dp);
    z = sind(dp);
    V = [x y z];
    V(V(:, 3) < 0, :) = -V(V(:, 3) < 0, :);
    n = sqrt(sum(V .^ 2, 2)); n(n == 0) = 1;
    V = V ./ n;
end

%% ===== 工具：密度填充 =====
function drawDensityFill(ax, dip_samp, az_samp, o)
    Nr = o.GridResolution(1); Nt = o.GridResolution(2);
    edgesR = linspace(0, 90, Nr + 1);
    edgesT = linspace(0, 360, Nt + 1);
    H = histcounts2(dip_samp, az_samp, edgesR, edgesT);

    sigR = max(0.5, o.SmoothSigma(1));
    sigT = max(0.5, o.SmoothSigma(2));
    kr = gauss1d(sigR); kt = gauss1d(sigT);
    Hs = conv2(kr', 1, H, 'same');
    w = floor(numel(kt) / 2);
    Hp = [Hs(:, end - w + 1:end), Hs, Hs(:, 1:w)];
    Hs = conv2(1, kt, Hp, 'same');
    Hs = Hs(:, w + 1:end - w);

    rC = 0.5 * (edgesR(1:end - 1) + edgesR(2:end));
    tC = 0.5 * (edgesT(1:end - 1) + edgesT(2:end));
    [tG, rG] = meshgrid(tC, rC);
    phi = deg2rad(90 - tG);
    X = rG .* cos(phi); Y = rG .* sin(phi);

    vals = Hs(:); vals = vals(isfinite(vals));
    if isempty(vals) || max(vals) <= 0, return; end
    Hn = (Hs - min(vals)) / (max(vals) - min(vals) + eps);
    Hn = Hn .^ 0.7;
    A = 0.45 * Hn;

    S = surface(ax, X, Y, zeros(size(Hn)), Hn, ...
        'EdgeColor', 'none', 'FaceAlpha', 'flat', 'AlphaData', A, 'AlphaDataMapping', 'none');
    colormap(ax, parula(64));
    caxis(ax, [0 1]);
    uistack(S, 'bottom');
end

function g = gauss1d(sigma)
    hw = max(1, ceil(3 * sigma));
    x = -hw:hw;
    g = exp(-0.5 * (x ./ max(sigma, eps)) .^ 2);
    g = g / sum(g);
end

function c2 = vividifyColor(c, satFactor, valFactor)
    c = min(max(c, 0), 1);
    hsv = rgb2hsv(c);
    hsv(2) = min(1, hsv(2) * max(satFactor, 0));
    hsv(3) = min(1, hsv(3) * max(valFactor, 0));
    c2 = hsv2rgb(hsv);
end
