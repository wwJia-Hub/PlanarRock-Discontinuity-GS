function visualizeClusters2(vertices, faces, final_index)
    % VISUALIZECLUSTERS 可视化网格聚类结果（无光照、方向不影响颜色）
    %   vertices: 顶点坐标矩阵（N×3）
    %   faces: 面索引矩阵（M×3）
    %   final_index: 有效面索引（P×1）

    % --------------------------
    % 1. 检查数据有效性
    % --------------------------
    if isempty(final_index)
        error('聚类结果为空！请检查 min_component_size 是否设置过大');
    end

    % 确保 final_index 中的面索引在有效范围内
    face_count = size(faces, 1);
    if max(final_index) > face_count || min(final_index) < 1
        warning('存在无效面索引，已自动过滤');
        valid_mask = (final_index >= 1) & (final_index <= face_count);
        final_index = final_index(valid_mask);
        if isempty(final_index)
            error('过滤无效索引后为空，请检查输入数据。');
        end
    end

    % --------------------------
    % 2. 提取聚类对应的面
    % --------------------------
    clustered_faces = faces(final_index, :);  % 聚类后的面（P×3）

    % --------------------------
    % 3. 提取不在 final_index 中的面
    % --------------------------
    all_indices = 1:face_count;
    remaining_index = setdiff(all_indices, final_index);  % 剩余未被索引的面
    remaining_faces = faces(remaining_index, :);           % 未被索引的面（Q×3）

    % --------------------------
    % 4. 绘制聚类结果（无光照）
    % --------------------------
    figure('Name', '网格聚类可视化', 'Position', [100, 100, 1200, 800]);

    hold on;
    
    % 颜色转换为 [0,1] 范围内的 RGB
    color_with_index = [114, 254, 15] / 255;  % 有索引的颜色
    color_without_index = [0, 0, 252] / 255; % 没有索引的颜色

    % 绘制有索引的面（类别面）
    h1 = patch('Vertices', vertices, ...
               'Faces', clustered_faces, ...
               'FaceColor', color_with_index, ... % 使用颜色 [114, 254, 15]
               'EdgeColor', 'k', ...
               'EdgeAlpha', 0.2, ...
               'FaceLighting', 'none', ...     % 关键：关闭面光照
               'EdgeLighting', 'none', ...     % 关键：关闭边光照
               'AmbientStrength', 1.0, ...     % 仅环境分量（即使有默认灯，也不受影响）
               'DiffuseStrength', 0.0, ...
               'SpecularStrength', 0.0);

    % 绘制未索引的面
    h2 = patch('Vertices', vertices, ...
               'Faces', remaining_faces, ...
               'FaceColor', color_without_index, ...  % 使用颜色 [0, 0, 252]
               'EdgeColor', 'k', ...
               'EdgeAlpha', 0.2, ...
               'FaceLighting', 'none', ...
               'EdgeLighting', 'none', ...
               'AmbientStrength', 1.0, ...
               'DiffuseStrength', 0.0, ...
               'SpecularStrength', 0.0);

    % 3D 视图属性
    view(0, 30);
    axis equal;

    xlabel('X'); ylabel('Y'); zlabel('Z');

    % 重要：不要添加任何光源，不调用 camlight / lightangle
    % 同时确保全局 lighting 关闭（对已有对象也生效）
    lighting none;

    % 不需要颜色条（因为只有两类颜色）
    title('网格聚类结果');
    
    % 交互
    rotate3d on;
    zoom on;
end
