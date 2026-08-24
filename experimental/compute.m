function [final_index,final_class,indices_normals,indices_area,vertices,faces,normals]=compute(fn,a0,b0,min_component_size)
mesh = readMesh_ply(fn);
vertices=mesh.vertices;
faces=mesh.faces;
% [vertices, faces] = meshSmoothing(vertices, faces, 10, 0.1);
faceAreas = meshFaceAreas(vertices, faces);
normals = meshFaceNormals(vertices, faces);
mesh_size = length(faces);
marked_indices = zeros(1,mesh_size);
tag_num = 1;
T_normals = zeros(mesh_size, 3); % 存平均法向量（向量）
S_all = zeros(1, mesh_size);    % 存总面积（标量）
SN_all = zeros(mesh_size, 3);   % 存法向量加权和（向量）
%neighbor_list = cell(mesh_size, 1);
% for i = 1:mesh_size
%     neighbor_list{i} = findVertexSharingFaces(faces, i);
% end


for i=1:mesh_size



    if marked_indices(i)==0%寻找邻域点

        %indices = neighbor_list{i};%indices:1*n
        indices = findVertexSharingFaces(faces, i);
        normal_i = normals(i, :); % 当前的法线
        cos_angles = sum(repmat(normal_i, length(indices), 1) .* normals(indices, :), 2);
        valid_mask = 1-cos_angles.^2 < a0^2;
        valid_neighbors = indices(valid_mask);
        % [~, sorted_idx] = sort(valid_neighbors);
        % valid_neighbors = indices(sorted_idx);
        min_tag_num = tag_num;
        S_all(min_tag_num) = faceAreas(i) + sum(faceAreas(valid_neighbors));
        if isempty(valid_neighbors)
            SN_all(min_tag_num,:) = faceAreas(i) .* normals(i,:);
        else
            SN_all(min_tag_num,:) = faceAreas(i).*normals(i,:) + faceAreas(valid_neighbors).'*normals(valid_neighbors,:);
        end

        if S_all(min_tag_num) > 0
            T_normals(min_tag_num, :) = SN_all(min_tag_num, :) / norm(SN_all(min_tag_num, :));
        end

        %tag_list_b0=zeros(1,length(valid_neighbors));

        for j = 1:length(valid_neighbors)
            neighbor_idx = valid_neighbors(j);%领域面面索引
            tag = marked_indices(neighbor_idx);%第一个领域面的标签

            if (tag > 0) && (tag < min_tag_num) && (1 - (dot(T_normals(min_tag_num, :), T_normals(tag, :))^2) < b0^2)
                total_area = S_all(min_tag_num) + S_all(tag) - faceAreas(neighbor_idx);  % 总面积
                total_sn = SN_all(min_tag_num, :) + SN_all(tag, :) - faceAreas(neighbor_idx) * normals(neighbor_idx, :);  % 加权法向量和

                if total_area > 0
                    merged_normal = total_sn / norm(total_sn);  % 合并后的法向量归一化
                else
                    merged_normal = [0, 0, 0];  % 异常处理
                end
                SN_all(tag, :) = total_sn;
                S_all(tag) = total_area;
                T_normals(tag, :) = merged_normal;
                if min_tag_num ~= tag  % 若标签发生变化
                    marked_indices(marked_indices == min_tag_num) = tag;  % 向量操作替代循环，效率更高
                end
                min_tag_num = tag;  % 更新最小标签
            elseif (tag > min_tag_num) && (1 - (dot(T_normals(min_tag_num, :), T_normals(tag, :))^2) < b0^2)
                total_area = S_all(min_tag_num) + S_all(tag) - faceAreas(neighbor_idx);
                total_sn = SN_all(min_tag_num, :) + SN_all(tag, :) - faceAreas(neighbor_idx) * normals(neighbor_idx, :);

                if total_area > 0
                    merged_normal = total_sn / norm(total_sn);  % 合并后的法向量归一化
                else
                    merged_normal = [0, 0, 0];  % 异常处理
                end

                S_all(min_tag_num) = total_area;
                SN_all(min_tag_num, :) = total_sn;
                T_normals(min_tag_num, :) = merged_normal;


                marked_indices(marked_indices == tag) = min_tag_num; 



            end
        end

        unmarked_idx = valid_neighbors(marked_indices(valid_neighbors) == 0);
        marked_indices(unmarked_idx) = min_tag_num;
        marked_indices(i) = min_tag_num;
        tag_num = tag_num + 1;  % 增加标签编号

    end



end



    %求解平均法向量
%     for j = 1:length(valid_neighbors)
%         neighbor_idx = valid_neighbors(j);
%         SN_all(min_tag_num, :) = SN_all(min_tag_num, :) + faceAreas(neighbor_idx) .* normals(neighbor_idx, :);
%     end 
% 
%     %将平均法向量归一化
%     if S_all(min_tag_num) > 0  % 避免除以0（无有效面时）
%         %T_nolmals(min_tag_num, :) = SN_all(min_tag_num, :) / S_all(min_tag_num);
%         %T_nolmals(min_tag_num, :) = T_nolmals(min_tag_num, :) / norm(T_nolmals(min_tag_num, :));
%         T_nolmals(min_tag_num, :) = SN_all(min_tag_num, :)/ norm(SN_all(min_tag_num, :));
%     end
% 
% 
%     %判断相邻簇集合是否合并
%     for j=1:length(valid_neighbors)
%         tag=marked_indices(valid_neighbors(j));
% 
%         if (tag>0) && (tag<min_tag_num)&&(1-(dot(T_nolmals(min_tag_num, :), T_nolmals(tag, :))^2)<b0^2)
%             total_area = S_all(min_tag_num) + S_all(tag)-faceAreas(valid_neighbors(j));  % 总面积（标量）
% % 改total_sn = SN_all(min_tag_num, :) + S_all(tag).*SN_all(tag, :);  % 加权法向量和（3维向量，需指定行索引）
%             total_sn = SN_all(min_tag_num, :) + SN_all(tag, :)-faceAreas(valid_neighbors(j)) .* normals(valid_neighbors(j), :);
% 
%             if total_area > 0
%                 %merged_normal = total_sn / total_area;  % 未归一化的平均向量
%                 merged_normal = total_sn / norm(total_sn);  % 归一化为单位向量
%             else
%                 merged_normal = [0, 0, 0];  % 异常处理（避免NaN）
%             end
%             SN_all(tag, :) = total_sn;  % 更新加权法向量和
%             S_all(tag) = total_area;    % 更新总面积
%             T_nolmals(tag, :) = merged_normal;  % 更新平均法向量
%             % 5. 更新当前最小标签（合并到更小的标签）
%             min_tag_num = tag;
%         end
%     end
% 
% 
% 
% 
% 
%     for j=1:length(valid_neighbors)
%         temp_tag_num = marked_indices(valid_neighbors(j));
%         if (temp_tag_num > min_tag_num) && (1-(dot(T_nolmals(min_tag_num, :), T_nolmals(temp_tag_num, :))^2) < b0^2)
%             %将所有点云中的该标签赋值最小标签
%             total_area = S_all(min_tag_num) + S_all(temp_tag_num)-faceAreas(valid_neighbors(j));
%             total_sn = SN_all(min_tag_num, :) + SN_all(temp_tag_num, :)-faceAreas(valid_neighbors(j)) .* normals(valid_neighbors(j), :);
%             % 改total_sn = SN_all(min_tag_num, :) + S_all(temp_tag_num).*SN_all(temp_tag_num, :);
%             if total_area > 0
%                 %merged_normal = total_sn / total_area;
%                 merged_normal = total_sn / norm(total_sn);  % 归一化
%             else
%                 merged_normal = [0, 0, 0];  % 防御性处理
%             end
%             % 更新当前聚类的参数
%             S_all(min_tag_num) = total_area;
%             SN_all(min_tag_num, :) = total_sn;
%             T_nolmals(min_tag_num, :) = merged_normal;
%             for k=1:mesh_size
%                 if marked_indices(k)==temp_tag_num
%                     marked_indices(k) = min_tag_num;
%                 end
%             end
%         end
%         %marked_indices(valid_neighbors(j)) = min_tag_num;
%     end
%     marked_indices(i)=min_tag_num;
%     tag_num = tag_num+1;





indices_tags = zeros(mesh_size+1,2);
for i = 1:mesh_size+1
    if(i== (1+mesh_size))
        indices_tags(i,:) = [mesh_size+1,mesh_size+1];
    else
        indices_tags(i,2) = i;
        indices_tags(i,1) = marked_indices(i);
    end
end

indices_tags = sortrows(indices_tags);%按行根据索引进行升序排列
final_index = zeros(mesh_size,1);
final_class = zeros(mesh_size,1);
clustering_index = zeros(mesh_size,1);
begin_index = 1;
class = 0;
kk=1;
for i =1:mesh_size+1
    if indices_tags(i,1) ~= indices_tags(begin_index,1)
        if i-begin_index>=min_component_size
            for j=begin_index:(i-1)
                final_index(kk) = indices_tags(j,2);
                final_class(kk) = class;
                kk=kk+1;
            end
            class = class+1;
            clustering_index(class)=indices_tags(begin_index,1);
        end
        begin_index = i;
    end
end
% indices_tags = indices_tags(1:mesh_size,1);
final_class(kk:end)=[];
final_index(kk:end)=[];
clustering_index(class+1:end)=[];
 


% 调用可视化函数
% visualizeClusters(vertices, faces, final_index, final_class);


S_all=S_all';
indices_area=S_all(clustering_index);
indices_normals=T_normals(clustering_index,:);
% indices_normals= computeCategoryNormals(final_index, final_class, normals);


end