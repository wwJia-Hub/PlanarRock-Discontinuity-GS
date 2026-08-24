function [final_index, final_class, indices_normals, indices_area, normals] = ...
        segmentMesh(vertices, faces, a0, b0, min_component_size)
%SEGMENTMESH 基于法线夹角的区域生长，将网格分割为若干"结构面候选区域"
%
%   [final_index, final_class, indices_normals, indices_area, normals] = ...
%       segmentMesh(vertices, faces, a0, b0, min_component_size)
%
% 输入：
%   vertices            - Nx3 顶点坐标
%   faces               - Mx3 三角面索引（1-based）
%   a0                  - 相邻三角面法线夹角阈值（sin 值，内部比较 1-cos^2 < a0^2）
%   b0                  - 三角簇间法线夹角阈值（sin 值）
%   min_component_size  - 最小三角簇尺寸（面数），小于该值的簇被丢弃
%
% 输出：
%   final_index     - 有效面索引（Px1）
%   final_class     - 有效面对应的区域标签（Px1，从 0 开始）
%   indices_normals - 每个区域的平均单位法向量（Kx3）
%   indices_area    - 每个区域包含的面数量（Kx1）
%   normals         - 每个面的单位法向量（Mx3）
%
% 说明：本函数实现的是"计数加权"版本（区域面积以面数计，均值法线按面数求和），
%       与文献/论文中默认使用的 compute_num 逻辑一致。

    normals = meshFaceNormals(vertices, faces);
    mesh_size = size(faces, 1);
    marked_indices = zeros(1, mesh_size);   % 每个面的区域标签
    tag_num = 1;                            % 下一个可用标签号
    T_normals = zeros(mesh_size, 3);        % 每个区域的均值法向量
    S_all = zeros(1, mesh_size);            % 每个区域的面数
    SN_all = zeros(mesh_size, 3);           % 每个区域的法向量之和

    for i = 1:mesh_size
        if marked_indices(i) == 0
            % 寻找与当前面共享顶点的邻接面
            indices = findVertexSharingFaces(faces, i);
            normal_i = normals(i, :);

            % 筛选法线夹角满足阈值的邻接面
            cos_angles = sum(repmat(normal_i, length(indices), 1) .* normals(indices, :), 2);
            valid_mask = 1 - cos_angles .^ 2 < a0 ^ 2;
            valid_neighbors = indices(valid_mask);

            min_tag_num = tag_num;

            % 区域面数 = 当前面 + 有效邻接面
            S_all(min_tag_num) = 1 + length(valid_neighbors);

            % 区域法向量之和 = 当前面法线 + 有效邻接面法线之和
            if isempty(valid_neighbors)
                SN_all(min_tag_num, :) = normals(i, :);
            else
                SN_all(min_tag_num, :) = normals(i, :) + sum(normals(valid_neighbors, :), 1);
            end

            % 归一化均值法向量
            if S_all(min_tag_num) > 0
                T_normals(min_tag_num, :) = SN_all(min_tag_num, :) / norm(SN_all(min_tag_num, :));
            end

            % 与相邻已标记区域合并
            for j = 1:length(valid_neighbors)
                neighbor_idx = valid_neighbors(j);
                tag = marked_indices(neighbor_idx);

                if (tag > 0) && (tag < min_tag_num) && ...
                        (1 - (dot(T_normals(min_tag_num, :), T_normals(tag, :)) ^ 2) < b0 ^ 2)
                    % 合并到更小的标签
                    total_area = S_all(min_tag_num) + S_all(tag) - 1;
                    total_sn = SN_all(min_tag_num, :) + SN_all(tag, :) - normals(neighbor_idx, :);
                    merged_normal = safeNormalize(total_sn);
                    SN_all(tag, :) = total_sn;
                    S_all(tag) = total_area;
                    T_normals(tag, :) = merged_normal;
                    if min_tag_num ~= tag
                        marked_indices(marked_indices == min_tag_num) = tag;
                    end
                    min_tag_num = tag;
                elseif (tag > min_tag_num) && ...
                        (1 - (dot(T_normals(min_tag_num, :), T_normals(tag, :)) ^ 2) < b0 ^ 2)
                    % 将更大的标签合并到当前标签
                    total_area = S_all(min_tag_num) + S_all(tag) - 1;
                    total_sn = SN_all(min_tag_num, :) + SN_all(tag, :) - normals(neighbor_idx, :);
                    merged_normal = safeNormalize(total_sn);
                    S_all(min_tag_num) = total_area;
                    SN_all(min_tag_num, :) = total_sn;
                    T_normals(min_tag_num, :) = merged_normal;
                    marked_indices(marked_indices == tag) = min_tag_num;
                end
            end

            % 标记当前面及其有效邻接面
            unmarked_idx = valid_neighbors(marked_indices(valid_neighbors) == 0);
            marked_indices(unmarked_idx) = min_tag_num;
            marked_indices(i) = min_tag_num;
            tag_num = tag_num + 1;
        end
    end

    % ---------- 整理区域标签，过滤小簇 ----------
    indices_tags = zeros(mesh_size + 1, 2);
    for i = 1:mesh_size + 1
        if i == (1 + mesh_size)
            indices_tags(i, :) = [mesh_size + 1, mesh_size + 1];
        else
            indices_tags(i, 2) = i;
            indices_tags(i, 1) = marked_indices(i);
        end
    end

    indices_tags = sortrows(indices_tags);   % 按标签升序排列
    final_index = zeros(mesh_size, 1);
    final_class = zeros(mesh_size, 1);
    clustering_index = zeros(mesh_size, 1);
    begin_index = 1;
    class = 0;
    kk = 1;

    for i = 1:mesh_size + 1
        if indices_tags(i, 1) ~= indices_tags(begin_index, 1)
            if i - begin_index >= min_component_size
                for j = begin_index:(i - 1)
                    final_index(kk) = indices_tags(j, 2);
                    final_class(kk) = class;
                    kk = kk + 1;
                end
                class = class + 1;
                clustering_index(class) = indices_tags(begin_index, 1);
            end
            begin_index = i;
        end
    end

    final_class(kk:end) = [];
    final_index(kk:end) = [];
    clustering_index(class + 1:end) = [];

    S_all = S_all';
    indices_area = S_all(clustering_index);        % 每个区域的面数
    indices_normals = T_normals(clustering_index, :); % 每个区域的均值法向量
end

function v = safeNormalize(v)
% 归一化为单位向量，零向量返回零向量（避免 NaN）
    n = norm(v);
    if n > 0
        v = v / n;
    else
        v = [0 0 0];
    end
end
