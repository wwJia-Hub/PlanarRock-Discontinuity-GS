function make_example(outfile)
%MAKE_EXAMPLE 生成合成示例 PLY 网格（3 组结构面，每组 4 个分离平面小块）
%
%   make_example()
%   make_example(outfile)
%
% 该示例用于演示与自测：3 组不同产状（水平、倾向 +x 倾 30°、倾向 +y 倾 45°）的
% 平面结构面，每组由 4 个空间上分离的小块构成，共 12 个候选区域。
% 每个小块为 8x8 网格三角面（98 面），整体 768 顶点 / 1176 面。
%
% 生成位置：默认为本文件同目录下的 example_rock_slope.ply。

    if nargin < 1 || isempty(outfile)
        outfile = fullfile(fileparts(mfilename('fullpath')), 'example_rock_slope.ply');
    end

    % 3 组结构面：法向量 + 两个互相正交且垂直于法向的切向
    orient = struct();
    orient(1).n = [0.0 0.0 1.0];  orient(1).u = [1 0 0]; orient(1).v = [0 1 0];          % 水平
    orient(2).n = [0.8660254 0.0 0.5]; orient(2).u = [0 1 0]; orient(2).v = [-0.5 0 0.8660254]; % 倾 30°
    orient(3).n = [0.0 0.7071068 0.7071068]; orient(3).u = [1 0 0]; orient(3).v = [0 0.7071068 -0.7071068]; % 倾 45°

    grid = 8;        % 每块 8x8 顶点
    half = 1.0;      % 小块半宽
    step = 2 * half / (grid - 1);

    vertices = zeros(0, 3);
    faces = zeros(0, 3);

    for oi = 1:3
        n = orient(oi).n; u = orient(oi).u; v = orient(oi).v;
        row_y = (oi - 1) * 3.0;
        for pi = 0:3
            cx = pi * 3.0;
            base = size(vertices, 1);
            for i = 1:grid
                for j = 1:grid
                    s = -half + (i - 1) * step;
                    t = -half + (j - 1) * step;
                    p = [cx, row_y, 0] + s * u + t * v;
                    vertices(end + 1, :) = p; %#ok<AGROW>
                end
            end
            for i = 1:grid - 1
                for j = 1:grid - 1
                    a = base + (i - 1) * grid + j;
                    b = base + (i - 1) * grid + (j + 1);
                    c = base + i * grid + j;
                    d = base + i * grid + (j + 1);
                    faces(end + 1, :) = [a, b, d]; %#ok<AGROW>
                    faces(end + 1, :) = [a, d, c]; %#ok<AGROW>
                end
            end
        end
    end

    writeMeshPly(outfile, vertices, faces);
    fprintf('已生成示例网格：%s（%d 顶点，%d 面）\n', outfile, ...
        size(vertices, 1), size(faces, 1));
end

function writeMeshPly(filename, V, F)
% 写 ASCII PLY（三角面）
    fid = fopen(filename, 'w');
    assert(fid > 0, '无法写入 %s', filename);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'ply\n');
    fprintf(fid, 'format ascii 1.0\n');
    fprintf(fid, 'comment Planar Rock Discontinuity synthetic example\n');
    fprintf(fid, 'element vertex %d\n', size(V, 1));
    fprintf(fid, 'property float x\nproperty float y\nproperty float z\n');
    fprintf(fid, 'element face %d\n', size(F, 1));
    fprintf(fid, 'property list uchar int vertex_indices\n');
    fprintf(fid, 'end_header\n');
    fprintf(fid, '%.6f %.6f %.6f\n', V');
    fprintf(fid, '3 %d %d %d\n', (F - 1)');   % 转回 0-based
end
