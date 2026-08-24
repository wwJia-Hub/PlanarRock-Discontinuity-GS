% 结果显示子函数
function PlotClusterinResult(X, IDX)
    k=max(IDX);
    Colors=hsv(k);
    Legends = {};
    for i=0:k
        Xi=X(IDX==i,:);
        if i~=0
            Style = 'ro';
            MarkerSize = 4;
            Color = Colors(i,:);
            Legends{end+1} = ['Cluster #' num2str(i)];
        else
            Style = 'k^';
            MarkerSize = 6;
            Color = [0 0 0];
            if ~isempty(Xi)
                Legends{end+1} = 'Noise';
            end
        end
        if ~isempty(Xi)
            plot(Xi(:,1),Xi(:,2),Style,'MarkerSize',MarkerSize,'Color',Color,'MarkerFaceColor',Color);
        end
        hold on;
    end
    hold off;
    axis equal;
    grid on;
    legend(Legends);
    legend('Location', 'NorthEastOutside');

    set(gca,'fontname','Times New Roman')
end