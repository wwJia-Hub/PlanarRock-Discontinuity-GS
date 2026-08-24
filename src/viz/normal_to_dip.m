function [dip_dirs, dip_angles] = normal_to_dip(normals)
    % 向量化批量转换n×3单位法向量矩阵为倾向和倾角（高效版）
    % 输入：
    %   normals - n×3矩阵，每行是一个单位法向量
    % 输出：
    %   dip_dirs - n×1向量，倾向（°）
    %   dip_angles - n×1向量，倾角（°）
    
    % 提取法向量分量（确保单位向量，做容错处理）
    normals = normals ./ sqrt(sum(normals.^2, 2));  % 每行归一化
    nx = normals(:, 1);
    ny = normals(:, 2);
    nz = normals(:, 3);
    
    % 批量计算倾角（0°~90°）
    dip_angles = 90 - acos(abs(nz)) * (180/pi);
    
    % 批量计算倾向（0°~360°）
    % 1. 计算法向量水平投影的方位角
    theta = atan2(nx, ny) * (180/pi);  % 弧度转度
    theta = mod(theta, 360);  % 归一化到0°~360°
    
    % 2. 倾向 = 法向量水平方位角 + 90°（垂直关系）
    dip_dirs = theta + 90;
    dip_dirs = mod(dip_dirs, 360);  % 确保在0°~360°
    
    % 3. 修正方向（当法向量z分量为负时）
    neg_z_idx = nz < 0;  % z分量为负的索引
    dip_dirs(neg_z_idx) = mod(dip_dirs(neg_z_idx) + 180, 360);
    
    % 特殊情况：水平构造（水平投影为0，倾向设为0）
    zero_horiz_idx = (nx == 0) & (ny == 0);
    dip_dirs(zero_horiz_idx) = 0;
end
    