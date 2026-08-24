% 基于现有聚类结果，使用DBSCAN进行进一步聚类
% 提取每个有效聚类的信息
valid_clusters = unique(final_class);
num_clusters = length(valid_clusters);

% 初始化聚类信息存储
cluster_normals = zeros(num_clusters, 3); % 存储每个聚类的平均法线
cluster_areas = zeros(num_clusters, 1);   % 存储每个聚类的总面积
cluster_indices = cell(num_clusters, 1);  % 存储每个聚类包含的三角面片索引

% 收集每个聚类的信息
for i = 1:num_clusters
    cluster_idx = valid_clusters(i);
    cluster_faces = final_index(final_class == cluster_idx);
    
    % 计算聚类的总面积
    cluster_areas(i) = sum(faceAreas(cluster_faces));
    
    % 计算聚类的加权平均法线
    weighted_sum = zeros(1, 3);
    for j = 1:length(cluster_faces)
        face_idx = cluster_faces(j);
        weighted_sum = weighted_sum + faceAreas(face_idx) * normals(face_idx, :);
    end
    cluster_normals(i, :) = weighted_sum / cluster_areas(i);
    cluster_normals(i, :) = cluster_normals(i, :) / norm(cluster_normals(i, :)); % 归一化
    
    % 保存聚类包含的三角面片索引
    cluster_indices{i} = cluster_faces;
end

% 计算SAA距离矩阵（球面角距离，即法线夹角）
distance_matrix = zeros(num_clusters, num_clusters);
for i = 1:num_clusters
    for j = i+1:num_clusters
        % 计算法线点积，限制在[-1,1]范围内以避免数值误差
        dot_product = max(min(dot(cluster_normals(i,:), cluster_normals(j,:)), 1.0), -1.0);
        % 计算夹角（弧度）
        angle = acos(dot_product);
        % 存储对称的距离矩阵
        distance_matrix(i,j) = angle;
        distance_matrix(j,i) = angle;
    end
end

% DBSCAN参数设置
eps = deg2rad(15); % 邻域半径，单位为弧度
minPts = 3;        % 形成核心点所需的最小点数

% 执行DBSCAN聚类
dbscan_labels = dbscan_clustering(distance_matrix, eps, minPts, cluster_areas);

% 可视化最终聚类结果
visualizeFinalClusters(vertices, faces, cluster_indices, dbscan_labels);

% DBSCAN聚类函数实现
function labels = dbscan_clustering(dist_matrix, eps, minPts, weights)
    num_points = size(dist_matrix, 1);
    labels = zeros(num_points, 1); % 0表示未分类
    cluster_id = 0;
    
    for i = 1:num_points
        if labels(i) ~= 0 % 已分类
            continue;
        end
        
        % 找出epsilon邻域内的点
        neighbors = find(dist_matrix(i,:) <= eps);
        
        if length(neighbors) < minPts % 不是核心点
            labels(i) = -1; % 标记为噪声
            continue;
        end
        
        % 是核心点，创建新聚类
        cluster_id = cluster_id + 1;
        labels(i) = cluster_id;
        
        % 扩展聚类
        neighbors_queue = neighbors;
        
        while ~isempty(neighbors_queue)
            j = neighbors_queue(1);
            neighbors_queue = neighbors_queue(2:end);
            
            if labels(j) == -1 % 噪声点变为聚类点
                labels(j) = cluster_id;
            end
            
            if labels(j) ~= 0 % 已分类
                continue;
            end
            
            labels(j) = cluster_id;
            
            % 找出j的邻域点
            j_neighbors = find(dist_matrix(j,:) <= eps);
            
            if length(j_neighbors) >= minPts % j是核心点
                % 将j的邻域点添加到队列
                neighbors_queue = [neighbors_queue; j_neighbors];
            end
        end
    end
    
    % 合并小聚类到最近的大聚类（可选步骤）
    labels = merge_small_clusters(labels, dist_matrix, weights);
end

% 合并小聚类到最近的大聚类
function labels = merge_small_clusters(labels, dist_matrix, weights)
    unique_labels = unique(labels);
    unique_labels = unique_labels(unique_labels > 0); % 只考虑聚类，不考虑噪声
    
    % 计算每个聚类的总权重
    cluster_weights = zeros(max(unique_labels), 1);
    for i = 1:length(unique_labels)
        cluster_idx = unique_labels(i);
        cluster_points = find(labels == cluster_idx);
        cluster_weights(cluster_idx) = sum(weights(cluster_points));
    end
    
    % 确定小聚类的阈值（例如，小于平均权重的10%）
    threshold = 0.1 * mean(cluster_weights(unique_labels));
    
    % 对每个小聚类，找到最近的大聚类并合并
    for i = 1:length(unique_labels)
        cluster_idx = unique_labels(i);
        if cluster_weights(cluster_idx) < threshold % 小聚类
            % 找出所有大聚类
            large_clusters = unique_labels(cluster_weights(unique_labels) >= threshold);
            
            if isempty(large_clusters) % 没有大聚类，跳过
                continue;
            end
            
            % 找出该聚类的所有点
            cluster_points = find(labels == cluster_idx);
            
            % 计算该聚类到每个大聚类的平均距离
            min_avg_dist = inf;
            nearest_cluster = -1;
            
            for j = 1:length(large_clusters)
                large_cluster_idx = large_clusters(j);
                large_cluster_points = find(labels == large_cluster_idx);
                
                % 计算平均距离
                avg_dist = 0;
                count = 0;
                for p = 1:length(cluster_points)
                    for q = 1:length(large_cluster_points)
                        avg_dist = avg_dist + dist_matrix(cluster_points(p), large_cluster_points(q));
                        count = count + 1;
                    end
                end
                
                if count > 0
                    avg_dist = avg_dist / count;
                    if avg_dist < min_avg_dist
                        min_avg_dist = avg_dist;
                        nearest_cluster = large_cluster_idx;
                    end
                end
            end
            
            % 合并到最近的大聚类
            if nearest_cluster ~= -1
                labels(cluster_points) = nearest_cluster;
            end
        end
    end
end

% 可视化最终聚类结果
function visualizeFinalClusters(vertices, faces, cluster_indices, dbscan_labels)
    % 创建图形窗口
    figure;
    hold on;
    
    % 获取唯一的聚类标签
    unique_labels = unique(dbscan_labels);
    % 排除噪声点（标签为-1）
    unique_labels = unique_labels(unique_labels > 0);
    num_clusters = length(unique_labels);
    
    % 为每个聚类生成随机颜色
    colors = hsv(num_clusters);
    
    % 绘制每个聚类
    for i = 1:num_clusters
        cluster_idx = unique_labels(i);
        cluster_faces = [];
        
        % 收集该聚类包含的所有三角面片索引
        for j = 1:length(cluster_indices)
            if dbscan_labels(j) == cluster_idx
                cluster_faces = [cluster_faces; cluster_indices{j}];
            end
        end
        
        if ~isempty(cluster_faces)
            % 提取顶点和面片数据
            cluster_vertices = vertices;
            cluster_faces_idx = faces(cluster_faces, :);
            
            % 绘制聚类
            patch('Vertices', cluster_vertices, 'Faces', cluster_faces_idx, ...
                  'FaceColor', colors(i,:), 'EdgeAlpha', 0.2);
        end
    end
    
    % 绘制噪声点（如果有）
    noise_faces = [];
    for j = 1:length(cluster_indices)
        if dbscan_labels(j) == -1
            noise_faces = [noise_faces; cluster_indices{j}];
        end
    end
    
    if ~isempty(noise_faces)
        noise_vertices = vertices;
        noise_faces_idx = faces(noise_faces, :);
        patch('Vertices', noise_vertices, 'Faces', noise_faces_idx, ...
              'FaceColor', [0.5 0.5 0.5], 'EdgeAlpha', 0.1);
    end
    
    % 设置图形属性
    axis equal;
    view(3);
    grid on;
    title('基于DBSCAN的法线聚类结果');
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    
    % 添加图例
    legend_entries = cell(num_clusters + (any(dbscan_labels == -1)), 1);
    legend_colors = zeros(num_clusters + (any(dbscan_labels == -1)), 3);
    
    idx = 1;
    for i = 1:num_clusters
        legend_entries{idx} = sprintf('聚类 %d', unique_labels(i));
        legend_colors(idx,:) = colors(i,:);
        idx = idx + 1;
    end
    
    if any(dbscan_labels == -1)
        legend_entries{idx} = '噪声';
        legend_colors(idx,:) = [0.5 0.5 0.5];
    end
    
    legend(legend_entries);
end    