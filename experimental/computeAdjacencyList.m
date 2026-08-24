function adjacencyList = computeAdjacencyList(faces)
    % 初始化哈希表（边 -> 面列表）
    edgeToFaces = containers.Map('KeyType', 'uint64', 'ValueType', 'any');
    
    % 遍历所有面，构建边到面的映射
    nFaces = size(faces, 1);
    for i = 1:nFaces
        face = faces(i, :);
        
        % 处理三条边
        for j = 1:3
            v1 = min(face(j), face(mod(j, 3) + 1));  % 确保边的顶点按顺序排列
            v2 = max(face(j), face(mod(j, 3) + 1));
            
            % 创建边的唯一键（使用位运算避免哈希冲突）
            edgeKey = uint64(v1) + (uint64(v2) << 32);
            
            % 更新边到面的映射
            if isKey(edgeToFaces, edgeKey)
                edgeToFaces(edgeKey) = [edgeToFaces(edgeKey), i];
            else
                edgeToFaces(edgeKey) = i;
            end
        end
    end
    
    % 构建邻接表
    adjacencyList = cell(nFaces, 1);
    for i = 1:nFaces
        face = faces(i, :);
        neighbors = [];
        
        % 处理三条边
        for j = 1:3
            v1 = min(face(j), face(mod(j, 3) + 1));
            v2 = max(face(j), face(mod(j, 3) + 1));
            edgeKey = uint64(v1) + (uint64(v2) << 32);
            
            % 获取共享此边的所有面
            if isKey(edgeToFaces, edgeKey)
                facesSharingEdge = edgeToFaces(edgeKey);
                neighbors = [neighbors, facesSharingEdge(facesSharingEdge ~= i)];
            end
        end
        
        % 去重并存储结果
        adjacencyList{i} = unique(neighbors);
    end
end