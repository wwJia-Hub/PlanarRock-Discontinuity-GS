function neighborFaces = findVertexSharingFaces(faces, targetFaceIdx)
%FINDVERTEXSHARINGFACES 查找与目标三角面共享任意顶点的所有面（向量化）
%
%   neighborFaces = findVertexSharingFaces(faces, targetFaceIdx)
%
% 输入：
%   faces         - Mx3 三角面索引矩阵
%   targetFaceIdx - 目标面索引（标量）
% 输出：
%   neighborFaces - 与目标面共享至少一个顶点的面索引（列向量，不含目标面自身）

    targetVertices = faces(targetFaceIdx, :);
    v1 = targetVertices(1);
    v2 = targetVertices(2);
    v3 = targetVertices(3);

    hasV1 = any(faces == v1, 2);
    hasV2 = any(faces == v2, 2);
    hasV3 = any(faces == v3, 2);

    isNeighborCandidate = hasV1 | hasV2 | hasV3;
    isNeighborCandidate(targetFaceIdx) = false;   % 排除自身

    neighborFaces = find(isNeighborCandidate);
end
