function startup()
%STARTUP 将本工具箱所有子目录加入 MATLAB 搜索路径
%
%   在 MATLAB 中运行一次，或将其加入 startup.m，即可直接调用所有函数。
%   运行 GUI（DiscontinuityAnalyzer）或 main.m 时通常会自动调用，无需手动执行。

    root = fileparts(mfilename('fullpath'));
    addpath(genpath(root));
    fprintf('已添加路径：%s\n', root);
end
