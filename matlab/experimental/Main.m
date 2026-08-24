tic
a0 = sin(deg2rad(10)); %相邻三角面法线夹角阈值
b0 = sin(deg2rad(10)); %类似三角簇法线夹角阈值
min_component_size=85; %最小三角簇阈值

% SearchAgents_no=200;
% Max_iteration=500; 

full_path = 'C:\Users\wwJia\Desktop\论文\数据\data3.ply';      % 你刚上传的文件路径
% outdir = 'C:\Users\wwJia\Desktop\mesh_parts';     % 输出目录
% N = 8;
% addGhost = true;           % 是否生成幽灵层
% 
% [part, info] = partition_mesh_ply(in_ply, N, outdir, addGhost);
% 
% 
% 
% ensurePool(N);                   % 或 parpool('threads')
% parts = dir("C:\Users\wwJia\Desktop\mesh_parts/part_*.ply");
% results = cell(numel(parts),1);%numel是返回数组元素的总数

% tic;
% parfor k = 1:numel(parts)

    
    % fn = parts(k).folder;  % 获取文件夹路径
    % file_name = parts(k).name;  % 获取文件名
    % full_path = fullfile(fn, file_name);  % 合并成完整路径

    % 调用 compute 函数，得到 4 个输出
    [final_index, final_class, indices_normals, indices_area,vertices,faces,all_normal] = compute_num(full_path, a0, b0, min_component_size);

    % result = all_normal(final_index,:);
    


%     data_with_index = data(index, :);  % 使用索引行提取数据
% 
% % 获取没有索引的行
% all_indices = 1:size(data, 1);     % 所有行的索引
% no_index = setdiff(all_indices, index);  % 没有索引的行位置
% data_without_index = data(no_index, :);  % 提取没有索引的行


    % 将计算结果存入结果结构体
%     results{k} = struct('final_index', final_index, ...
%                         'final_class', final_class, ...
%                         'indices_normals', indices_normals, ...
%                         'indices_area', indices_area, ...
%                         'vertices', vertices, ...
%                         'faces', faces);
% 
% 
% 
% 
% end
% toc;





% % 假设 results{k} 包含的内容：final_index, final_class, indices_normals, indices_area
% num_results = numel(results);  % 分块数量
% all_indices_normals = [];      % 用于存储合并后的法向量
% all_indices_area = []; 
% all_vertices= []; 
% all_faces= []; 
% all_final_index=[];
% all_final_class=[];

% 全局索引偏移量（确保每个分块的索引不会冲突）


% 遍历所有分块
% for k = 1:num_results
%     % 获取当前分块的法向量
%     indices_normals_k = results{k}.indices_normals;  % 假设 indices_normals 存储在第 3 个位置
%     indices_area_k= results{k}.indices_area;
%     vertices_k= results{k}.vertices;
%     faces_k= results{k}.faces;
%     final_index_k=results{k}.final_index;
%     final_class_k=results{k}.final_class;
% 
%     num_class_k = size(indices_normals_k, 1);
%     %直接合并
%     all_indices_normals = [all_indices_normals; indices_normals_k];
%     all_indices_area = [all_indices_area; indices_area_k];
%     all_vertices=[all_vertices; vertices_k];
% 
% 
% 
% 
%     num_vertices_k = size(vertices_k, 1);
%     num_face_k= size(faces_k, 1);
%     faces_k = faces_k + size(all_vertices, 1) - num_vertices_k;
%     all_faces=[all_faces;faces_k];
% 
% 
%     final_index_k= final_index_k + size(all_faces, 1) - num_face_k;
%     final_class_k=final_class_k+size(all_indices_normals, 1)-num_class_k+1;
% 
%      %考虑全局偏移
%     all_final_index=[all_final_index; final_index_k];
% 
%     all_final_class=[all_final_class; final_class_k];
% 
% 
% end

%visualizeClusters(vertices, faces,final_index, final_class);

% fobj = @(x)fitness(x,X,indices_area);
% % fobj = @(x)fitness(x,X);
% 
% [Best_score,Best_pos,WOA_cg_curve]=WOA(SearchAgents_no,Max_iteration,ub,lb,dim1,dim2,fobj);
% plotPoleFigure(Best_pos);




% sc=zeros(8, 1);
% 
% 
% for k = 2:8
% 
% dim1=k;
% 
% % fobj = @(x)fitness(x,X,indices_area);
% fobj = @(x)fitness2(x,X);
% 
% 
% [Best_score,Best_pos,WOA_cg_curve]=WOA(SearchAgents_no,Max_iteration,ub,lb,dim1,dim2,fobj);
% 
% distances = dip_distance(X, Best_pos);
% [~, labels] = min(distances, [], 2);
% cluster = labels(final_class); 
% weights=indices_area;
% % sc(k)=silhouetteCoefficient(X, labels,weights);
% sc(k)=silhouetteCoefficient(X, labels);
% 
% 
% % 在初始化时或k>=3时更新最优结果
% if k == 2 || (k >= 3 && sc(k) > max_sc)
% % if k >= 2
%     final_Best_score = Best_score;
%     final_Best_pos = Best_pos;
%     final_WOA_cg_curve = WOA_cg_curve;
%     final_num_k = k;
%     final_cluster = cluster;
%     final_labels=labels;
%     max_sc = sc(k);  % 更新最大轮廓系数
%     final_indices_normals=X;
% end
% 
% end
% 
% 
% 
% 
% sc=zeros(8, 1);
% 
% 
% for k = 2:8
% 
% dim1=k;
% 
% fobj = @(x)fitness(x,X,indices_area);
% %fobj = @(x)fitness(x,X);
% 
% 
% [Best_score,Best_pos,WOA_cg_curve]=WOA(SearchAgents_no,Max_iteration,ub,lb,dim1,dim2,fobj);
% 
% distances = dip_distance(X, Best_pos);
% [~, labels] = min(distances, [], 2);
% cluster = labels(final_class); 
% weights=indices_area;
% % sc(k)=silhouetteCoefficient(X, labels,weights);
% sc(k)=silhouetteCoefficient(X, labels);
% 
% 
% % 在初始化时或k>=3时更新最优结果
% if k == 2 || (k >= 3 && sc(k) > max_sc)
% % if k >= 2
%     final_Best_score = Best_score;
%     final_Best_pos = Best_pos;
%     final_WOA_cg_curve2 = WOA_cg_curve;
%     final_num_k = k;
%     final_cluster = cluster;
%     final_labels=labels;
%     max_sc = sc(k);  % 更新最大轮廓系数
%     final_indices_normals=X;
% end
% 
% end


% final_class=final_class+1;
% 
% 
% X=indices_normals;
%  %搜索代理鲸鱼的数量
% 
% % Function_name='F24'; % 测试函数名称（从F1到F23可选）
% 
% 
% 
% % % 加载所选基准函数的详细信息
% % [lb,ub,dim,fobj]=Get_Functions_details(Function_name);
% ub=[1,1,0];
% lb=[-1,-1,-1];
% dim2=3;
% 
% % 初始化存储轮廓系数的数组
% sc = zeros(8, 1);
% % 用于存储两种WOA曲线结果的变量
% final_WOA_cg_curve1 = [];
% final_WOA_cg_curve2 = [];
% 
% % 循环计算k=2到8的情况
% for k = 2:8
%     dim1 = k;  % 维度设置
% 
%     % 第一部分：使用fitness2函数
%     fobj = @(x)fitness2(x, X);
%     [Best_score, Best_pos, WOA_cg_curve] = WOA(SearchAgents_no, Max_iteration, ub, lb, dim1, dim2, fobj);
% 
%     % 计算距离和聚类标签
%     distances = dip_distance(X, Best_pos);
%     [~, labels] = min(distances, [], 2);
%     cluster = labels(final_class); 
% 
%     % 计算轮廓系数
%     sc(k) = silhouetteCoefficient(X, labels);
% 
%     % 更新最优结果（第一种情况）
%     if k == 2 || (k >= 3 && sc(k) > max_sc)
%         final_Best_score1 = Best_score;
%         final_Best_pos1 = Best_pos;
%         final_WOA_cg_curve1 = WOA_cg_curve;
%         final_num_k1 = k;
%         final_cluster1 = cluster;
%         final_labels1 = labels;
%         max_sc1 = sc(k);  % 更新最大轮廓系数
%         final_indices_normals1 = X;
%     end
% 
%     % 第二部分：使用带indices_area参数的fitness函数
%     fobj = @(x)fitness(x, X, indices_area);
%     [Best_score, Best_pos, WOA_cg_curve] = WOA(SearchAgents_no, Max_iteration, ub, lb, dim1, dim2, fobj);
% 
%     % 计算距离和聚类标签（复用变量名，减少内存占用）
%     distances = dip_distance(X, Best_pos);
%     [~, labels] = min(distances, [], 2);
%     cluster = labels(final_class); 
% 
%     % 计算轮廓系数
%     sc(k) = silhouetteCoefficient(X, labels);  % 若需要可单独存储为sc2(k)
% 
%     % 更新最优结果（第二种情况）
%     if k == 2 || (k >= 3 && sc(k) > max_sc2)
%         final_Best_score2 = Best_score;
%         final_Best_pos2 = Best_pos;
%         final_WOA_cg_curve2 = WOA_cg_curve;
%         final_num_k2 = k;
%         final_cluster2 = cluster;
%         final_labels2 = labels;
%         max_sc2 = sc(k);  % 更新最大轮廓系数
%         final_indices_normals2 = X;
%     end
% end
% 
% strArray = string({"MWOA";"AR-MWOA"});
% all_final_WOA_cg_curve= [final_WOA_cg_curve; final_WOA_cg_curve2]; 
% plot_convergence_curve(all_final_WOA_cg_curve, strArray,1000,SearchAgents_no);
% % 








% X = indices_normals;  % 确保X已定义
% % 算法参数（根据您的实际参数调整）
% SearchAgents_no = 200;  % 鲸鱼数量
% Max_iteration = 100;    % 迭代次数
% ub = [1, 1, 0];
% lb = [-1, -1, -1];
% dim2 = 3;
% n_runs = 20;            % 重复实验次数
% 
% % 初始化存储20次实验的收敛曲线（每行一次实验，每列一次迭代）
% cg_curve1_all = zeros(n_runs, Max_iteration);
% cg_curve2_all = zeros(n_runs, Max_iteration);
% 
% % 重复20次实验
% for run = 1:n_runs
%     fprintf('正在进行第%d次实验...\n', run);
% 
%     % 每次实验重新初始化变量（与原始代码结构一致）
%     sc = zeros(8, 1);
%     max_sc1 = -Inf;  % 初始化第一种情况的最大轮廓系数
%     max_sc2 = -Inf;  % 初始化第二种情况的最大轮廓系数
%     final_WOA_cg_curve1 = [];
%     final_WOA_cg_curve2 = [];
% 
%     % 循环计算k=2到8的情况（保留原始逻辑）
%     for k = 2:8
%         dim1 = k;  % 维度设置
% 
%         % 第一部分：使用fitness2函数
%         fobj = @(x)fitness2(x, X);
%         [Best_score, Best_pos, WOA_cg_curve] = WOA(SearchAgents_no, Max_iteration, ub, lb, dim1, dim2, fobj);
% 
%         distances = dip_distance(X, Best_pos);
%         [~, labels] = min(distances, [], 2);
%         cluster = labels(final_class);  % 确保final_class已定义
%         sc(k) = silhouetteCoefficient(X, labels);
% 
%         % 更新最优结果（第一种情况）
%         if k == 2 || sc(k) > max_sc1  % 简化条件，与原始逻辑一致
%             final_Best_score1 = Best_score;
%             final_Best_pos1 = Best_pos;
%             final_WOA_cg_curve1 = WOA_cg_curve;  % 保存当前k下的最优曲线
%             final_num_k1 = k;
%             final_cluster1 = cluster;
%             final_labels1 = labels;
%             max_sc1 = sc(k);
%             final_indices_normals1 = X;
%         end
% 
%         % 第二部分：使用带indices_area参数的fitness函数
%         fobj = @(x)fitness(x, X, indices_area);  % 确保indices_area已定义
%         [Best_score, Best_pos, WOA_cg_curve] = WOA(SearchAgents_no, Max_iteration, ub, lb, dim1, dim2, fobj);
% 
%         distances = dip_distance(X, Best_pos);
%         [~, labels] = min(distances, [], 2);
%         cluster = labels(final_class);
%         sc(k) = silhouetteCoefficient(X, labels);
% 
%         % 更新最优结果（第二种情况）
%         if k == 2 || sc(k) > max_sc2  % 简化条件，与原始逻辑一致
%             final_Best_score2 = Best_score;
%             final_Best_pos2 = Best_pos;
%             final_WOA_cg_curve2 = WOA_cg_curve;  % 保存当前k下的最优曲线
%             final_num_k2 = k;
%             final_cluster2 = cluster;
%             final_labels2 = labels;
%             max_sc2 = sc(k);
%             final_indices_normals2 = X;
%         end
%     end
% 
%     % 将当前实验的最优收敛曲线存入数组（转为行向量）
%     cg_curve1_all(run, :) = final_WOA_cg_curve1';
%     cg_curve2_all(run, :) = final_WOA_cg_curve2';
% end
% 
% % 计算20次实验的平均收敛曲线（行向量）
% avg_cg_curve1 = mean(cg_curve1_all, 1);  % 按列求平均（每次迭代的平均值）
% avg_cg_curve2 = mean(cg_curve2_all, 1);
% 
% % 绘制平均收敛曲线
% strArray = string({"MWOA"; "AR-MWOA"});
% all_avg_cg_curve = [avg_cg_curve1; avg_cg_curve2];  % 每行一条曲线
% plot_convergence_curve(all_avg_cg_curve, strArray, 2600,SearchAgents_no );
% 
% 
% 
% 
% plot_convergence_curve(final_WOA_cg_curve2,"收敛曲线", "收敛曲线");
% % distances = dip_distance(X, Best_pos);
% % 
% % [~, labels] = min(distances, [], 2);
% % cluster = labels(final_class); 
% plotPoleFigure(indices_normals,final_labels, final_Best_pos);
% visualizeClusters(vertices, faces,final_index, final_cluster);
% visualizeClusters2(vertices, faces,final_index);
% 
% plotPoleRose(indices_normals);
% 
% plotpoleNDGER(indices_normals);
% 
% %plotall(result);
% 
% 
% 
% toc



final_class=final_class+1;

X = indices_normals;  % 确保X已定义
% 算法参数（根据您的实际参数调整）
SearchAgents_no = 300;  % 鲸鱼数量
Max_iteration = 500;    % 迭代次数
ub = [1, 1, 0];
lb = [-1, -1, -1];
dim2 = 3;


for k = 2:8

dim1=k;

fobj = @(x)fitness(x,X,indices_area);
%fobj = @(x)fitness(x,X);


[Best_score,Best_pos,WOA_cg_curve]=WOA(SearchAgents_no,Max_iteration,ub,lb,dim1,dim2,fobj);

distances = dip_distance(X, Best_pos);
[~, labels] = min(distances, [], 2);
cluster = labels(final_class); 
weights=indices_area;
% sc(k)=silhouetteCoefficient(X, labels,weights);
sc(k)=silhouetteCoefficient(X, labels);


% 在初始化时或k>=3时更新最优结果
if k == 2 || (k >= 3 && sc(k) > max_sc)
% if k >= 2
    final_Best_score = Best_score;
    final_Best_pos = Best_pos;
    final_WOA_cg_curve = WOA_cg_curve;
    final_num_k = k;
    final_cluster = cluster;
    final_labels=labels;
    max_sc = sc(k);  % 更新最大轮廓系数
    indices_normals=X;
end

end









% distances = dip_distance(X, Best_pos);
% 
% [~, labels] = min(distances, [], 2);
% cluster = labels(final_class); 
plotPoleFigure(indices_normals,final_labels, final_Best_pos);
visualizeClusters(vertices, faces,final_index, final_cluster);
visualizeClusters2(vertices, faces,final_index);

plotPoleRose(indices_normals);

plotpoleNDGER(indices_normals);

%plotall(result);



toc