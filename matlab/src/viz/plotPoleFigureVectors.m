function plotPoleFigureVectors(vectors, varargin)
% 在极点图上绘制一组向量（无聚类标签，无中心）
%
% vectors : n×3 法向量 [x,y,z] 或 n×2 [az°, dip°]
%
% 可选参数(Name-Value):
%   'Colormap'       (默认 'lines')     % 点的颜色
%   'SampleSize'     (默认 12)          % 点的大小
%   'Title'          (默认 '极点图 (All Vectors)')
%   'ShowDensity'    (默认 true)        % 是否绘制底图密度填充
%   'GridResolution' (默认 [90,180])    % 密度网格 [Nr,Ntheta]
%   'SmoothSigma'    (默认 [1.5,2])     % 高斯平滑 [σr,σθ]

    %% 参数解析
    p = inputParser;
    addParameter(p, 'Colormap', 'lines');
    addParameter(p, 'SampleSize', 8);
    addParameter(p, 'Title', '极点图 (All Vectors)');
    addParameter(p, 'ShowDensity', true);
    addParameter(p, 'GridResolution', [90,180]);
    addParameter(p, 'SmoothSigma', [1.5,2]);
    parse(p, varargin{:});
    o = p.Results;

    %% 转换到 (az°, dip°)
    [az, dp, mask] = toAzDip(vectors);
    if isempty(az)
        warning('没有有效向量'); return;
    end

    %% 颜色方案
    cmap = buildColormap(o.Colormap, 1);

    %% 底层 Cartesian 密度填充
    Rmax = 90;
    fig = figure('Color','w');
    axB = axes('Parent',fig);
    axis(axB,'equal'); axis(axB,'off'); hold(axB,'on');
    xlim(axB,[-Rmax Rmax]); ylim(axB,[-Rmax Rmax]);

    if o.ShowDensity
        try
            drawDensityFill(axB, dp, az, o);
        catch ME
            warning(ME.identifier, '%s', ME.message);
        end
    end

    %% 极坐标轴
    axP = polaraxes('Parent',fig,'Color','none');
    axP.Position = axB.Position;
    set(axP,'ThetaZeroLocation','top','ThetaDir','clockwise');
    rlim(axP,[0 90]);
    rticks(axP,[0 30 60 90]);
    thetaticks(axP,0:45:315);
    grid(axP,'on'); hold(axP,'on');
    title(axP, o.Title);

    % 隐藏径向 30/60/90 标签，只保留 0
    lbl = arrayfun(@num2str, rticks(axP), 'UniformOutput', false);
    for i = 2:numel(lbl), lbl{i} = ''; end
    rticklabels(axP, lbl);

    %% 绘制所有点
    usePS = ~(isempty(which('polarscatter')));
    th = deg2rad(az); rr = dp;
    if usePS
        polarscatter(axP, th, rr, o.SampleSize, cmap(1,:), ...
                     'filled','MarkerEdgeColor',[0 0 0], ...
                     'MarkerFaceAlpha',0.9,'MarkerEdgeAlpha',0.7);
    else
        polarplot(axP, th, rr, 'o','LineStyle','none', ...
                  'MarkerSize', max(4, round(sqrt(o.SampleSize)/1.6)), ...
                  'MarkerFaceColor', cmap(1,:), 'MarkerEdgeColor',[0 0 0]);
    end
end

%% ===== 工具函数 =====

% 向量 → (azimuth, dip)
function [azimuth, dip, valid_mask] = toAzDip(X)
    [~, m] = size(X);
    if m == 3
        nrm = sqrt(sum(X.^2,2));
        valid_mask = nrm > 1e-12 & all(isfinite(X),2);
        if ~any(valid_mask), azimuth=[]; dip=[]; return; end
        V = X(valid_mask,:)./nrm(valid_mask);
        V(V(:,3)<0,:) = -V(V(:,3)<0,:);  % 上半球
        azimuth = atan2d(V(:,2), V(:,1));
        azimuth(azimuth<0)=azimuth(azimuth<0)+360;
        dip = asind(max(-1,min(1,V(:,3))));
    elseif m == 2
        valid_mask = all(isfinite(X),2);
        if ~any(valid_mask), azimuth=[]; dip=[]; return; end
        azimuth = mod(X(valid_mask,1), 360);
        dip     = max(0, min(90, X(valid_mask,2)));
    else
        error('输入必须为 n×3 或 n×2');
    end
end

% 构建 colormap
function cmap = buildColormap(spec, K)
    if isnumeric(spec)
        if size(spec,2)~=3, error('Colormap 必须为 k×3 RGB'); end
        if size(spec,1)<K
            rep = ceil(K/size(spec,1));
            cmap = repmat(spec,rep,1);
            cmap = cmap(1:K,:);
        else
            cmap = spec(1:K,:);
        end
        return;
    end
    switch lower(char(spec))
        case 'lines',   cmap = lines(K);
        case 'hsv',     cmap = hsv(K);
        case 'parula',  t=parula(max(K,64)); cmap=t(round(linspace(1,size(t,1),K)),:);
        case 'turbo',   t=turbo(max(K,64));  cmap=t(round(linspace(1,size(t,1),K)),:);
        otherwise,      warning('未知 Colormap "%s"，使用 lines', spec); cmap = lines(K);
    end
end

% 绘制密度底图
function drawDensityFill(ax, dip_samp, az_samp, o)
    Nr = o.GridResolution(1); Nt = o.GridResolution(2);
    edgesR = linspace(0,90,Nr+1);
    edgesT = linspace(0,360,Nt+1);
    H = histcounts2(dip_samp, az_samp, edgesR, edgesT); % Nr×Nt

    % 高斯平滑（theta循环）
    sigR = max(0.5, o.SmoothSigma(1));
    sigT = max(0.5, o.SmoothSigma(2));
    kr = gauss1d(sigR); kt = gauss1d(sigT);
    Hs = conv2(kr', 1, H, 'same');
    w = floor(numel(kt)/2);
    Hp = [Hs(:, end-w+1:end), Hs, Hs(:, 1:w)];
    Hs = conv2(1, kt, Hp, 'same');
    Hs = Hs(:, w+1:end-w);

    % 网格中心 → Cartesian
    rC = 0.5*(edgesR(1:end-1) + edgesR(2:end));
    tC = 0.5*(edgesT(1:end-1) + edgesT(2:end));
    [tG, rG] = meshgrid(tC, rC);
    phi = deg2rad(90 - tG);
    X = rG .* cos(phi); Y = rG .* sin(phi);

    % 归一化
    vals = Hs(:); vals = vals(isfinite(vals));
    if isempty(vals) || max(vals)<=0, return; end
    Hn = (Hs - min(vals)) / (max(vals) - min(vals) + eps);
    Hn = Hn .^ 0.7;   % 提亮低密度
    A  = 0.45 * Hn;   % 透明度

    % 绘制
    S = surface(ax, X, Y, zeros(size(Hn)), Hn, ...
        'EdgeColor','none','FaceAlpha','flat','AlphaData',A,'AlphaDataMapping','none');
    colormap(ax, parula(64));
    caxis(ax, [0 1]);
    uistack(S, 'bottom');
end

% 一维高斯核
function g = gauss1d(sigma)
    hw = max(1, ceil(3*sigma));
    x = -hw:hw;
    g = exp(-0.5*(x./max(sigma,eps)).^2);
    g = g / sum(g);
end
