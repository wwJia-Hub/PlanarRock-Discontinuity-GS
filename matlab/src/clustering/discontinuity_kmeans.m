function [clusters, centers, iterations] = discontinuity_kmeans(data, k, max_iter, tolerance,max_inices)
% DISCONTINUITY_KMEANS Optimized K-means clustering for rock discontinuity data
%
% Inputs:
%   data - N x 3 matrix of unit normal vectors for discontinuities
%   k - number of clusters
%   max_iter - maximum number of iterations (default: 100)
%   tolerance - convergence tolerance (default: 1e-6)
%
% Outputs:
%   clusters - N x 1 vector of cluster assignments
%   centers - k x 3 matrix of final cluster centers
%   iterations - number of iterations until convergence
% 
% if nargin < 3, max_iter = 100; end
% if nargin < 4, tolerance = 1e-6; end
%判断输入的参数的个数，进行参数补充

[n_points, ~] = size(data);%读取数据的大小

% Normalize input vectors to ensure they are unit vectors归一化
data = data ./ sqrt(sum(data.^2, 2));

% Step 1: Select initial cluster centers using the proposed algorithm
initial_centers = select_initial_centers(data, k, max_inices);

% Initialize variables
centers = initial_centers;
prev_centers = zeros(size(centers));
clusters = zeros(n_points, 1);
iterations = 0;

% Main K-means iteration loop
while iterations < max_iter
    iterations = iterations + 1;
    
    % Assign each point to the nearest cluster center
    distances = calculate_sa_distance_matrix(data, centers);
    [~, clusters] = min(distances, [], 2);
    
    % Update cluster centers
    prev_centers = centers;
    for i = 1:k
        cluster_points = data(clusters == i, :);
        if ~isempty(cluster_points)
            % Calculate new center as the mean of assigned points
            new_center = mean(cluster_points, 1);
            % Normalize to unit vector
            centers(i, :) = new_center / norm(new_center);
        end
    end
    
    % Check for convergence
    center_change = max(sqrt(sum((centers - prev_centers).^2, 2)));
    if center_change < tolerance
        break;
    end
end

fprintf('Converged after %d iterations\n', iterations);
end

function initial_centers = select_initial_centers(data, k,max_inices)
% SELECT_INITIAL_CENTERS Select initial cluster centers using farthest point sampling
%
% This implements the algorithm described in Section 2.4.1

[n_points, ~] = size(data);

% Step 1: Initialize empty set M for storing initial cluster centers
M = [];
selected_indices = [];%选择聚类的索引号

% Step 2: Select the discontinuity with the largest number of point clouds
% Since we don't have point cloud information, we'll select the first point
% In practice, this should be the discontinuity with most associated points

first_center_idx=max_inices;
% This could be modified based on point cloud counts
M = [M; data(first_center_idx, :)];
selected_indices = [selected_indices; first_center_idx];

% Step 3: Find the farthest point from the first center
if k > 1
    remaining_indices = setdiff(1:n_points, selected_indices);
    distances = calculate_sa_distances(data(remaining_indices, :), M(1, :));
    [~, max_idx] = max(distances);
    second_center_idx = remaining_indices(max_idx);
    M = [M; data(second_center_idx, :)];
    selected_indices = [selected_indices; second_center_idx];
end

% Steps 4-5: Iteratively select remaining centers
for i = 3:k
    remaining_indices = setdiff(1:n_points, selected_indices);
    
    if isempty(remaining_indices)
        break;
    end
    
    % Calculate average distances from remaining points to all selected centers
    avg_distances = zeros(length(remaining_indices), 1);
    
    for j = 1:length(remaining_indices)
        point_idx = remaining_indices(j);
        distances_to_centers = calculate_sa_distances(data(point_idx, :), M);
        avg_distances(j) = mean(distances_to_centers);
    end
    
    % Select the point with the largest average distance
    [~, max_avg_idx] = max(avg_distances);
    next_center_idx = remaining_indices(max_avg_idx);
    M = [M; data(next_center_idx, :)];
    selected_indices = [selected_indices; next_center_idx];
end

initial_centers = M;
end

function distances = calculate_sa_distances(points, centers)
% CALCULATE_SA_DISTANCES Calculate SA distance between points and centers
%
% Implements Equation (7): d(i,j) = sin²θ = 1 - (Xi · XjT)²


dot_products = points * centers';
distances = 1 - dot_products.^2;

% Ensure distances are non-negative (handle numerical errors)
distances = max(distances, 0);
end

function distance_matrix = calculate_sa_distance_matrix(points, centers)
% CALCULATE_SA_DISTANCE_MATRIX Calculate SA distance matrix
%point为保留索引，centers为已有聚类
% Returns n_points x n_centers matrix of distances

[n_points, ~] = size(points);
[n_centers, ~] = size(centers);

distance_matrix = zeros(n_points, n_centers);

for i = 1:n_centers
    distance_matrix(:, i) = calculate_sa_distances(points, centers(i, :));
end
end

function visualize_clustering_results(data, clusters, centers, k)
% VISUALIZE_CLUSTERING_RESULTS Plot the clustering results
%
% This function creates visualizations for the discontinuity clustering

figure('Position', [100, 100, 1200, 400]);

% Plot 1: 3D scatter plot of normal vectors
subplot(1, 3, 1);
colors = lines(k);
hold on;
for i = 1:k
    cluster_points = data(clusters == i, :);
    if ~isempty(cluster_points)
        scatter3(cluster_points(:, 1), cluster_points(:, 2), cluster_points(:, 3), ...
                30, colors(i, :), 'filled', 'MarkerEdgeColor', 'k');
    end
    % Plot cluster centers
    scatter3(centers(i, 1), centers(i, 2), centers(i, 3), ...
            100, colors(i, :), 'p', 'MarkerEdgeColor', 'k', 'LineWidth', 2);
end
xlabel('X'); ylabel('Y'); zlabel('Z');
title('3D Normal Vectors and Cluster Centers');
grid on; axis equal;
legend_entries = cell(2*k, 1);
for i = 1:k
    legend_entries{2*i-1} = sprintf('Cluster %d', i);
    legend_entries{2*i} = sprintf('Center %d', i);
end
legend(legend_entries, 'Location', 'best');

% Plot 2: Stereographic projection (lower hemisphere)
subplot(1, 3, 2);
hold on;
for i = 1:k
    cluster_points = data(clusters == i, :);
    if ~isempty(cluster_points)
        % Project to lower hemisphere if needed
        projected_points = cluster_points;
        projected_points(projected_points(:, 3) > 0, :) = ...
            -projected_points(projected_points(:, 3) > 0, :);
        
        % Stereographic projection
        x_proj = projected_points(:, 1) ./ (1 - projected_points(:, 3));
        y_proj = projected_points(:, 2) ./ (1 - projected_points(:, 3));
        
        scatter(x_proj, y_proj, 30, colors(i, :), 'filled', 'MarkerEdgeColor', 'k');
    end
end
xlabel('X projection'); ylabel('Y projection');
title('Stereographic Projection (Lower Hemisphere)');
grid on; axis equal;

% Plot 3: Cluster size distribution
subplot(1, 3, 3);
cluster_sizes = zeros(k, 1);
for i = 1:k
    cluster_sizes(i) = sum(clusters == i);
end
bar(1:k, cluster_sizes, 'FaceColor', [0.7, 0.7, 0.7], 'EdgeColor', 'k');
xlabel('Cluster Number');
ylabel('Number of Discontinuities');
title('Cluster Size Distribution');
grid on;
for i = 1:k
    text(i, cluster_sizes(i) + max(cluster_sizes)*0.02, ...
         sprintf('%d', cluster_sizes(i)), 'HorizontalAlignment', 'center');
end
end

% Example usage and demonstration
function demo_discontinuity_clustering()
% DEMO_DISCONTINUITY_CLUSTERING Demonstrate the clustering algorithm

fprintf('=== Discontinuity Set Clustering Demo ===\n\n');

% Generate synthetic discontinuity data (unit normal vectors)
rng(42); % For reproducible results
n_sets = 3;
points_per_set = [50, 40, 30];
total_points = sum(points_per_set);

% Create three distinct discontinuity sets with different orientations
set1_normal = [0.707, 0.707, 0]; % 45° dip direction
set2_normal = [0, 0.866, 0.5];   % 30° dip
set3_normal = [0.5, 0, 0.866];   % 60° dip

data = [];
true_labels = [];

% Generate points around each set with some noise
noise_level = 0.1;

for i = 1:n_sets
    if i == 1, base_normal = set1_normal; n_points = points_per_set(1);
    elseif i == 2, base_normal = set2_normal; n_points = points_per_set(2);
    else, base_normal = set3_normal; n_points = points_per_set(3);
    end
    
    % Add noise to the base normal vector
    noise = noise_level * randn(n_points, 3);
    set_data = repmat(base_normal, n_points, 1) + noise;
    
    % Normalize to unit vectors
    set_data = set_data ./ sqrt(sum(set_data.^2, 2));
    
    data = [data; set_data];
    true_labels = [true_labels; i * ones(n_points, 1)];
end

fprintf('Generated %d discontinuity normal vectors in %d sets\n', total_points, n_sets);
fprintf('Set sizes: %s\n\n', mat2str(points_per_set));

% Apply the clustering algorithm
k = n_sets;
fprintf('Running optimized K-means clustering with k = %d...\n', k);
tic;
[clusters, centers, iterations] = discontinuity_kmeans(data, k);
elapsed_time = toc;

fprintf('Clustering completed in %.3f seconds (%d iterations)\n\n', elapsed_time, iterations);

% Calculate clustering accuracy (assuming we know the true labels)
accuracy = calculate_clustering_accuracy(true_labels, clusters);
fprintf('Clustering accuracy: %.1f%%\n\n', accuracy * 100);

% Display cluster centers
fprintf('Final cluster centers (unit normal vectors):\n');
for i = 1:k
    fprintf('Cluster %d: [%.3f, %.3f, %.3f]\n', i, centers(i, :));
end
fprintf('\n');

% Visualize results
visualize_clustering_results(data, clusters, centers, k);

% Calculate and display within-cluster sum of squares
wcss = calculate_wcss(data, clusters, centers);
fprintf('Within-cluster sum of squares: %.6f\n', wcss);
end

function accuracy = calculate_clustering_accuracy(true_labels, predicted_labels)
% CALCULATE_CLUSTERING_ACCURACY Calculate clustering accuracy using Hungarian algorithm
% This is a simplified version - in practice, you'd use the Hungarian algorithm

k = max(true_labels);
n = length(true_labels);

% Try all possible permutations for small k
if k <= 6
    perms = perms(1:k);
    best_accuracy = 0;
    
    for i = 1:size(perms, 1)
        perm = perms(i, :);
        mapped_labels = predicted_labels;
        for j = 1:k
            mapped_labels(predicted_labels == j) = perm(j);
        end
        accuracy = sum(mapped_labels == true_labels) / n;
        best_accuracy = max(best_accuracy, accuracy);
    end
    accuracy = best_accuracy;
else
    % For larger k, use a simpler mapping
    accuracy = 0;
    fprintf('Warning: Simplified accuracy calculation for k > 6\n');
end
end

function wcss = calculate_wcss(data, clusters, centers)
% CALCULATE_WCSS Calculate within-cluster sum of squares using SA distance

wcss = 0;
k = size(centers, 1);

for i = 1:k
    cluster_points = data(clusters == i, :);
    if ~isempty(cluster_points)
        distances = calculate_sa_distances(cluster_points, centers(i, :));
        wcss = wcss + sum(distances);
    end
end
end