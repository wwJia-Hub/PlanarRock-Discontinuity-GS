function plotPoleRose(samples, varargin)
% 在极点投影上绘制玫瑰图（按 azimuth 分布）
%
% samples: n×3 [x,y,z] 或 n×2 [az°,dip°]
%
% 可选参数:
%   'NumBins'     (默认 18 → 20° 一格)
%   'Normalization' {'count','probability'} 默认 count
%   'FaceColor'   (默认 [0.3 0.6 0.9])
%   'EdgeColor'   (默认 [0 0 0])
%   'FaceAlpha'   (默认 0.7)
%   'Title'       (默认 '极点玫瑰图')

    p = inputParser;
    addParameter(p,'NumBins',18);
    addParameter(p,'Normalization','count');
    addParameter(p,'FaceColor',[0.3 0.6 0.9]);
    addParameter(p,'EdgeColor',[0 0 0]);
    addParameter(p,'FaceAlpha',0.7);
    % addParameter(p,'Title','极点玫瑰图');
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
        N = N / sum(N);
    end

    %% 极点投影图背景
    Rmax = 90;
    figure('Color','w'); hold on; axis equal off
    th = linspace(0,2*pi,361);
    plot(Rmax*cos(th), Rmax*sin(th),'k');

    %% 画玫瑰瓣
    for i=1:o.NumBins
        th1 = deg2rad(edges(i));
        th2 = deg2rad(edges(i+1));
        t   = linspace(th1,th2,30);
        r   = (N(i)/max(N))*Rmax;  % 频数映射到 [0,Rmax]

        x = [0 r*cos(t)];
        y = [0 r*sin(t)];

        patch(x,y,o.FaceColor, ...
            'EdgeColor',o.EdgeColor,'FaceAlpha',o.FaceAlpha);
    end

    %% 方位刻度
    for a=0:45:315
        x = [0 Rmax*cosd(90-a)];
        y = [0 Rmax*sind(90-a)];
        plot(x,y,'k:');
        text(1.05*x(2),1.05*y(2),sprintf('%d°',a), ...
             'HorizontalAlignment','center');
    end


end

%% 工具：转 az-dip
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

