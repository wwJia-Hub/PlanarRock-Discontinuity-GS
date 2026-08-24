
a0 = sin(deg2rad(10)); %相邻三角面法线夹角阈值
b0 = sin(deg2rad(10)); %类似三角簇法线夹角阈值
min_component_size=20; %最小三角簇阈值


fn = 'C:\Users\wwJia\Desktop\论文\数据\data2.ply';  

% 
% mesh = readMesh_ply(fn);
% vertices=mesh.vertices;
% faces=mesh.faces;
% % [vertices, faces] = meshSmoothing(vertices, faces, 10, 0.1);
% faceAreas = meshFaceAreas(vertices, faces);
% normals = meshFaceNormals(vertices, faces);
% mesh_size = length(faces);
% marked_indices = zeros(1,mesh_size);
% tag_num = 1;
% T_nolmals = zeros(mesh_size, 3); % 存平均法向量（向量）
% S_all = zeros(1,mesh_size);    % 存总面积（标量）
% SN_all = zeros(mesh_size, 3);   % 存法向量加权和（向量） 
% 
% for i=1:mesh_size
%     if marked_indices(i)==0%寻找邻域点
%         indices= findVertexSharingFaces(faces,i);%indices:1*n
%         normal_i = normals(i, :); % 当前的法线
%         cos_angles = sum(repmat(normal_i, length(indices), 1) .* normals(indices, :), 2);
%         valid_mask = 1-cos_angles.^2 < a0^2;
%         valid_neighbors = indices(valid_mask);
% 
% 
%         min_tag_num = tag_num;
%         S_all(min_tag_num) = faceAreas(i) + sum(faceAreas(valid_neighbors));
%         SN_all(min_tag_num,:)=faceAreas(i).*normals(i,:)+faceAreas(valid_neighbors).'*normals(valid_neighbors,:); 
%         T_nolmals(min_tag_num, :) = SN_all(min_tag_num, :) / norm(SN_all(min_tag_num, :));
%         tag_mask=zeros(length(valid_neighbors),1);
%         tag_list=zeros(length(valid_neighbors),1);
% 
%         for j = 1:length(valid_neighbors)
% 
%             neighbor_idx = valid_neighbors(j);%领域面面索引
%             tag = marked_indices(neighbor_idx);%领域面的标签
% 
%             if (tag > 0) && (tag < min_tag_num) && (1 - (dot(T_nolmals(min_tag_num, :), T_nolmals(tag, :))^2) < b0^2)
%                 % total_area = S_all(min_tag_num) + S_all(tag) - faceAreas(neighbor_idx);  % 总面积
%                 % total_sn = SN_all(min_tag_num, :) + SN_all(tag, :) - faceAreas(neighbor_idx) * normals(neighbor_idx, :);  % 加权法向量和
%                 % merged_normal = total_sn / norm(total_sn);  % 合并后的法向量归一化
%                 % SN_all(tag, :) = total_sn;
%                 % S_all(tag) = total_area;
%                 % T_nolmals(tag, :) = merged_normal;
%                 % min_tag_num = tag;  % 更新最小标签
%                 tag_mask(j)=1;
%             else
% 
%             end
% 
%         end
% 
% 
%         tag_list = marked_indices(indices(tag_mask==1));
%         tag_list = unique(tag_list);
%         tag_list = tag_list(tag_list > 0);
%         indices_tag_0=indices(tag_mask==0);
% 
%         if ~isempty(tag_list)
% 
%             total_area = S_all(min_tag_num)+sum(S_all(tag_list))-sum(faceAreas(indices(tag_mask==1)));
%             total_sn = SN_all(min_tag_num, :) + sum(SN_all(tag_list, :)) - faceAreas(indices(tag_mask==1)).'* normals(indices(tag_mask==1), :);
%             merged_normal = total_sn / norm(total_sn); 
%             min_tag_num=min(tag_list);
%             SN_all(min_tag_num, :) = total_sn;
%             S_all(min_tag_num) = total_area;
%             T_nolmals(min_tag_num, :) = merged_normal;
% 
%         end
% 
%         marked_indices(indices_tag_0)=min_tag_num;
% 
%         for k = 1:mesh_size
%             if  ismember(marked_indices(k), tag_list)
%                 marked_indices(k) = min_tag_num;
%             end
%         end
% 
%     end
% 
%     marked_indices(i) = min_tag_num;
%     tag_num = tag_num + 1;  % 增加标签编号
% 
% end
% 
% 
% 
% 
% 
% 
% indices_tags = zeros(mesh_size+1,2);
% for i = 1:mesh_size+1
%     if(i== (1+mesh_size))
%         indices_tags(i,:) = [mesh_size+1,mesh_size+1];
%     else
%         indices_tags(i,2) = i;
%         indices_tags(i,1) = marked_indices(i);
%     end
% end
% 
% indices_tags = sortrows(indices_tags);%按行根据索引进行升序排列
% final_index = zeros(mesh_size,1);
% final_class = zeros(mesh_size,1);
% clustering_index = zeros(mesh_size,1);
% begin_index = 1;
% class = 0;
% kk=1;
% for i =1:mesh_size+1
%     if indices_tags(i,1) ~= indices_tags(begin_index,1)
%         if i-begin_index>=min_component_size
%             for j=begin_index:(i-1)
%                 final_index(kk) = indices_tags(j,2);
%                 final_class(kk) = class;
%                 kk=kk+1;
%             end
%             class = class+1;
%             clustering_index(class)=indices_tags(begin_index,1);
%         end
%         begin_index = i;
%     end
% end
% % indices_tags = indices_tags(1:mesh_size,1);
% final_class(kk:end)=[];
% final_index(kk:end)=[];
% clustering_index(class+1:end)=[];
% 
% 
% 
% % 调用可视化函数
% % visualizeClusters(vertices, faces, final_index, final_class);
% 
% 
% S_all=S_all';
% indices_area=S_all(clustering_index);
% indices_normals=T_nolmals(clustering_index,:);
% % indices_normals= computeCategoryNormals(final_index, final_class, normals);





mesh = readMesh_ply(fn);
vertices=mesh.vertices;
faces=mesh.faces;
% [vertices, faces] = meshSmoothing(vertices, faces, 10, 0.1);
faceAreas = meshFaceAreas(vertices, faces);
normals = meshFaceNormals(vertices, faces);
mesh_size = length(faces);
marked_indices = zeros(1,mesh_size);
tag_num = 1;
T_nolmals = zeros(mesh_size, 3); % 存平均法向量（向量）
S_all = zeros(1, mesh_size);    % 存总面积（标量）
SN_all = zeros(mesh_size, 3);   % 存法向量加权和（向量） 

for i=1:mesh_size

    
    if marked_indices(i)==0%寻找邻域点

        indices= findVertexSharingFaces(faces,i);%indices:1*n
        normal_i = normals(i, :); % 当前的法线
        cos_angles = sum(repmat(normal_i, length(indices), 1) .* normals(indices, :), 2);
        valid_mask = 1-cos_angles.^2 < a0^2;
        valid_neighbors = indices(valid_mask);
        % [~, sorted_idx] = sort(valid_neighbors);
        % valid_neighbors = indices(sorted_idx);
        min_tag_num = tag_num;
        S_all(min_tag_num) = faceAreas(i) + sum(faceAreas(valid_neighbors));
        SN_all(min_tag_num,:)=faceAreas(i).*normals(i,:)+faceAreas(valid_neighbors).'*normals(valid_neighbors,:); 

        if S_all(min_tag_num) > 0
            T_nolmals(min_tag_num, :) = SN_all(min_tag_num, :) / norm(SN_all(min_tag_num, :));
        end
        
        for j = 1:length(valid_neighbors)
            neighbor_idx = valid_neighbors(j);%领域面面索引
            tag = marked_indices(neighbor_idx);%第一个领域面的标签
            
            if (tag > 0) && (tag < min_tag_num) && (1 - (dot(T_nolmals(min_tag_num, :), T_nolmals(tag, :))^2) < b0^2)
                total_area = S_all(min_tag_num) + S_all(tag) - faceAreas(neighbor_idx);  % 总面积
                total_sn = SN_all(min_tag_num, :) + SN_all(tag, :) - faceAreas(neighbor_idx) * normals(neighbor_idx, :);  % 加权法向量和
                
                if total_area > 0
                    merged_normal = total_sn / norm(total_sn);  % 合并后的法向量归一化
                else
                    merged_normal = [0, 0, 0];  % 异常处理
                end
                SN_all(tag, :) = total_sn;
                S_all(tag) = total_area;
                T_nolmals(tag, :) = merged_normal;
                % if min_tag_num~=tag_num
                %     for k = 1:mesh_size
                %         if marked_indices(k) == min_tag_num
                %             marked_indices(k) = tag;
                %         end
                %     end
                % end
                min_tag_num = tag;  % 更新最小标签
            elseif (tag > min_tag_num) && (1 - (dot(T_nolmals(min_tag_num, :), T_nolmals(tag, :))^2) < b0^2)
                total_area = S_all(min_tag_num) + S_all(tag) - faceAreas(neighbor_idx);
                total_sn = SN_all(min_tag_num, :) + SN_all(tag, :) - faceAreas(neighbor_idx) * normals(neighbor_idx, :);
                
                if total_area > 0
                    merged_normal = total_sn / norm(total_sn);  % 合并后的法向量归一化
                else
                    merged_normal = [0, 0, 0];  % 异常处理
                end
                
                S_all(min_tag_num) = total_area;
                SN_all(min_tag_num, :) = total_sn;
                T_nolmals(min_tag_num, :) = merged_normal;

                for k = 1:mesh_size
                    if marked_indices(k) == tag
                        marked_indices(k) = min_tag_num;
                    end
                end

            end
        end
    end

% 更新当前面标签

marked_indices(marked_indices(valid_neighbors==0)) = min_tag_num;
marked_indices(i) = min_tag_num;
tag_num = tag_num + 1;  % 增加标签编号

end
