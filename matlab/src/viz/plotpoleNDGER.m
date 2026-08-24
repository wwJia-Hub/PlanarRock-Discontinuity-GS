function plotpoleNDGER(samples, varargin)
% 在极点投影上绘制南丁格尔玫瑰图（按 azimuth 分布，面积∝频数）
%
% samples: n×3 [x,y,z] 或 n×2 [az°,dip°]
%
% 可选参数:
%   'NumBins'         (默认 18 → 20° 一格)
%   'Normalization'    {'count','probability'} 默认 count
%   'FaceColor'        (默认 [0.3 0.6 0.9])
%   'EdgeColor'        (默认 [0 0 0])
%   'FaceAlpha'        (默认 0.7)
%   'Title'            (默认 '极点南丁格尔玫瑰图')
%   'InnerRadiusFrac'  (默认 0，取值 [0,0.95]，为 Rmax 的比例；>0 时做成中空环形)

    p = inputParser;
    addParameter(p,'NumBins',18);
    addParameter(p,'Normalization','count');
    addParameter(p,'FaceColor',[0.3 0.6 0.9]);
    addParameter(p,'EdgeColor',[0 0 0]);
    addParameter(p,'FaceAlpha',0.7);
    addParameter(p,'Title','极点南丁格尔玫瑰图');
    addParameter(p,'InnerRadiusFrac',0);
    parse(p,varargin{:});
    o = p.Results;

    %% 数据
    [az, ~, valid] = toAzDip(samples);
    if isempty(az), warning('无有效样本'); return; end
    az = az(valid);

    %% 分箱
    edges = linspace(0,360,o.NumBins+1);
    N = histcounts(az,edges);

    if strcmpi(o.Normalization,'probability')
        s = sum(N);
        if s>0, N = N / s; end
    end

    %% 极点投影图背景
    Rmax = 90;                      % 画布半径（与极点投影一致）
    r0frac = max(0,min(0.95,o.InnerRadiusFrac));
    r0 = r0frac * Rmax;

    figure('Color','w'); hold on; axis equal off
    th = linspace(0,2*pi,361);
    plot(Rmax*cos(th), Rmax*sin(th),'k');           % 外圈
    if r0>0
        plot(r0*cos(th), r0*sin(th),'k:');          % 内圈（中空）
    end

    %% 画南丁格尔扇区（面积∝频数 → 半径∝sqrt(N)）
    maxN = max(N);
    if maxN==0
        warning('所有分箱计数为 0'); 
    end

    for i=1:o.NumBins
        if maxN==0 || N(i)==0
            % 若中空，N=0 仍显示为内半径；若不想显示可 continue
            r = r0;
        else
            r = r0 + (Rmax - r0) * sqrt(N(i)/maxN);
        end

        th1 = deg2rad(edges(i));
        th2 = deg2rad(edges(i+1));
        t   = linspace(th1,th2,40);

        if r0>0
            % 画环形扇区
            x = [r*cos(t),  r0*cos(fliplr(t))];
            y = [r*sin(t),  r0*sin(fliplr(t))];
        else
            % 从中心到外缘的实心扇区
            x = [0, r*cos(t)];
            y = [0, r*sin(t)];
        end

        patch(x,y,o.FaceColor,'EdgeColor',o.EdgeColor,'FaceAlpha',o.FaceAlpha);
    end

    %% 方位刻度（与原函数一致）
    for a=0:45:315
        x = [r0 Rmax]*cosd(90-a);
        y = [r0 Rmax]*sind(90-a);
        plot(x,y,'k:');
        text(1.05*Rmax*cosd(90-a), 1.05*Rmax*sind(90-a), sprintf('%d°',a), ...
             'HorizontalAlignment','center');
    end

    title(o.Title);
end

%% 工具：转 az-dip（与原版一致）
function [azimuth,dip,mask] = toAzDip(X)
    [~,m] = size(X);
    if m==3
        nrm = sqrt(sum(X.^2,2));
        mask = nrm>1e-12 & all(isfinite(X),2);
        V = X(mask,:)./nrm(mask);
        V(V(:,3)<0,:) = -V(V(:,3)<0,:);
        azimuth = atan2d(V(:,2),V(:,1));
        azimuth(azimuth<0)=azimuth(azimuth<0)+360;
        dip = asind(V(:,3));
    elseif m==2
        mask = all(isfinite(X),2);
        azimuth = mod(X(mask,1),360);
        dip = max(0,min(90,X(mask,2)));
    else
        error('输入必须是 n×3 或 n×2');
    end
end
