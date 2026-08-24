tic % 计时开始

a0 = cos(deg2rad(10)); % 相邻三角面法线夹角阈值
b0 = cos(deg2rad(30)); % 类似三角簇法线夹角阈值
min_component_size = 50; % 最小三角簇阈值

% 读取网格数据
mesh = readMesh_ply('C:\Users\wwJia\Desktop\Mesh5.ply');
vertices = mesh.vertices;
faces = mesh.faces;
mesh_size = length(faces);

% ==================== GPU数据准备 ====================
% 将核心数据转移到GPU
vertices_gpu = gpuArray(vertices);
faces_gpu = gpuArray(faces);

% 在GPU上计算面面积和法线（假设函数支持GPU，若不支持需替换为向量化实现）
faceAreas_gpu = meshFaceAreas(vertices_gpu, faces_gpu);
normals_gpu = meshFaceNormals(vertices_gpu, faces_gpu);

% 预分配GPU内存（与CPU版本结构一致，但存储在GPU上）
marked_indices_gpu = gpuArray.zeros(1, mesh_size); % 标记聚类标签
tag_num = 1;
T_normals_gpu = gpuArray.zeros(mesh_size, 3); % 平均法向量
S_all_gpu = gpuArray.zeros(1, mesh_size); % 聚类总面积
SN_all_gpu = gpuArray.zeros(mesh_size, 3); % 法向量加权和



% ==================== 主聚类循环（GPU加速） ====================
for i = 1:mesh_size
    if marked_indices_gpu(i) == 0
        % 1. GPU上查找共享顶点的相邻面（无循环）
        indices = findVertexSharingFaces(faces_gpu, i);
        normal_i = normals_gpu(i, :); % 当前面法线（1×3行向量）
        
        % 2. GPU上筛选有效邻居（法线夹角满足条件）
        valid_neighbors = [];
        if ~isempty(indices)
            % 向量化计算所有相邻面的法线点积（GPU并行）
            neighbor_normals = normals_gpu(indices, :); % n×3矩阵
            cos_angles = dot(repmat(normal_i, length(indices), 1), neighbor_normals, 2); % n×1向量
            valid_mask = cos_angles > a0; % 逻辑筛选（GPU并行）
            valid_neighbors = indices(valid_mask); % 有效邻居索引（行向量）
        end
        
        min_tag_num = tag_num;
        
        % 3. 计算总面积（GPU向量化求和）
        tic
        S_all_gpu(min_tag_num) = faceAreas_gpu(i) + sum(faceAreas_gpu(valid_neighbors));


        % 4. 计算法向量加权和（修复维度匹配，GPU并行）
        current_weighted = faceAreas_gpu(i) .* normal_i; % 当前面贡献（1×3）
        if ~isempty(valid_neighbors)
            % 邻居面贡献：m×1列向量 .* m×3矩阵 → m×3（GPU广播机制）
            neighbor_weighted = faceAreas_gpu(valid_neighbors).* normals_gpu(valid_neighbors, :);
            neighbor_sum = sum(neighbor_weighted, 1); % 求和为1×3向量
        else
            neighbor_sum = [0, 0, 0];
        end
        SN_all_gpu(min_tag_num, :) = current_weighted + neighbor_sum;
        toc
        
        % 5. 计算平均法向量（GPU上归一化）
        if S_all_gpu(min_tag_num) > 0
            T_normals_gpu(min_tag_num, :) = SN_all_gpu(min_tag_num, :) / S_all_gpu(min_tag_num);
            T_normals_gpu(min_tag_num, :) = T_normals_gpu(min_tag_num, :) / norm(T_normals_gpu(min_tag_num, :));
        end
        
        % 6. 合并小标签聚类（GPU上逻辑判断）
        if ~isempty(valid_neighbors)
            neighbor_tags = marked_indices_gpu(valid_neighbors);
            existing_tags = unique(neighbor_tags(neighbor_tags > 0)); % 去重已有标签
            
            % 合并小于当前标签的聚类
            for tag = existing_tags'
                aaa=sum(T_normals_gpu(min_tag_num, :) .* T_normals_gpu(tag, :), 2);
                if isempty(tag)
                    break
                else 
                    valid_idx = (tag < min_tag_num) & (aaa > b0);
                    valid_tag = tag(valid_idx);  % 提取a中符合条件的元素（列向量）
                    for tag1=valid_tag
                        total_area = S_all_gpu(min_tag_num) + S_all_gpu(tag1);
                        total_sn = SN_all_gpu(min_tag_num, :) + SN_all_gpu(tag1, :);
                        if total_area > 0
                            merged_normal = total_sn / total_area;
                            merged_normal = merged_normal / norm(merged_normal);
                        else
                            merged_normal = [0, 0, 0];
                        end
                        % GPU上更新聚类参数
                        SN_all_gpu(tag1, :) = total_sn;
                        S_all_gpu(tag1) = total_area;
                        T_normals_gpu(tag1, :) = merged_normal;
                        min_tag_num = tag1;
                    end
                end
            end





            
            % 7. 合并大于当前标签的聚类（GPU逻辑索引加速）
            for tag = existing_tags'

                aaa=sum(T_normals_gpu(min_tag_num, :) .* T_normals_gpu(tag, :), 2);
                if isempty(tag)
                    break
                else 
                    bbb=aaa(1,1);
                end


                if (tag > min_tag_num) && (bbb > b0)
                    total_area = S_all_gpu(min_tag_num) + S_all_gpu(tag);
                    total_sn = SN_all_gpu(min_tag_num, :) + SN_all_gpu(tag, :);
                    
                    if total_area > 0
                        merged_normal = total_sn / total_area;
                        merged_normal = merged_normal / norm(merged_normal);
                    else
                        merged_normal = [0, 0, 0];
                    end
                    
                    % GPU上更新聚类参数
                    S_all_gpu(min_tag_num) = total_area;
                    SN_all_gpu(min_tag_num, :) = total_sn;
                    T_normals_gpu(min_tag_num, :) = merged_normal;
                    
                    % 关键加速：用逻辑索引一次性更新所有标签（替代循环）
                    marked_indices_gpu(marked_indices_gpu == tag) = min_tag_num;
                end
            end
        end
        
        % 8. 标记当前面及有效邻居（GPU上赋值）
        marked_indices_gpu(i) = min_tag_num;
        marked_indices_gpu(valid_neighbors) = min_tag_num;
        
        tag_num = tag_num + 1;
    end
end

% 将结果从GPU转回CPU（仅一次数据传输）
marked_indices = gather(marked_indices_gpu);

toc % 计时结束（GPU计算部分）

tic % 计时开始（后处理部分，CPU执行）
% 后处理：筛选有效聚类并整理标签
unique_tags = unique(marked_indices);
tag_counts = histcounts(marked_indices, [unique_tags; unique_tags(end)+1]); % 统计标签数量

% 筛选大于最小组件大小的标签
valid_tags = unique_tags(tag_counts >= min_component_size);
tag_map = containers.Map(valid_tags, 0:length(valid_tags)-1); % 映射到连续类别

% 生成最终索引和类别（CPU向量化操作）
final_mask = ismember(marked_indices, valid_tags);
final_index = find(final_mask);
final_class = arrayfun(@(x) tag_map(x), marked_indices(final_mask));

% 可视化（CPU执行）
visualizeClusters(vertices, faces, final_index, final_class);

toc % 计时结束（总计时）