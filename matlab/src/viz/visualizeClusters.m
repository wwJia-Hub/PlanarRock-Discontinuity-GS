function visualizeClusters(vertices, faces, final_index, final_class)
%VISUALIZECLUSTERS 三维可视化网格聚类结果（按类别着色，无光照）
%
%   visualizeClusters(vertices, faces, final_index, final_class)
%
% 输入：
%   vertices    - Nx3 顶点坐标
%   faces       - Mx3 三角面索引（1-based）
%   final_index - Px1 有效面索引
%   final_class - Px1 对应面的类别标签（从 0 开始）

    if isempty(final_index) || isempty(final_class)
        error('聚类结果为空！请检查 min_component_size 是否设置过大');
    end
    if length(final_index) ~= length(final_class)
        error('final_index 与 final_class 长度不匹配！');
    end

    face_count = size(faces, 1);
    if max(final_index) > face_count || min(final_index) < 1
        warning('存在无效面索引，已自动过滤');
        valid_mask = (final_index >= 1) & (final_index <= face_count);
        final_index = final_index(valid_mask);
        final_class = final_class(valid_mask);
        if isempty(final_index)
            error('过滤无效索引后为空，请检查输入数据。');
        end
    end

    % 类别标签重映射为 0..K-1
    unique_tags = unique(final_class);
    [~, final_class] = ismember(final_class, unique_tags);
    final_class = final_class - 1;
    nClasses = numel(unique(final_class));

    clustered_faces = faces(final_index, :);

    figure('Name', '网格聚类可视化', 'Position', [100, 100, 1200, 800]);
    patch('Vertices', vertices, ...
        'Faces', clustered_faces, ...
        'FaceColor', 'flat', ...
        'CData', final_class, ...
        'EdgeColor', 'k', ...
        'EdgeAlpha', 0.2, ...
        'FaceLighting', 'none', ...
        'EdgeLighting', 'none', ...
        'AmbientStrength', 1.0, ...
        'DiffuseStrength', 0.0, ...
        'SpecularStrength', 0.0);

    view(0, 30);
    axis equal;
    xlabel('X'); ylabel('Y'); zlabel('Z');
    lighting none;

    if nClasses <= 1
        colormap(lines(1));
        caxis([-0.5, 0.5]);
        colorbar;
    else
        colormap(lines(nClasses));
        caxis([-0.5, nClasses - 0.5]);
        cb = colorbar;
        set(cb, 'Ticks', 0:nClasses - 1, 'TickDirection', 'out');
    end

    title(['网格聚类结果（类别数：', num2str(nClasses), '）']);
    rotate3d on;
    zoom on;
end
