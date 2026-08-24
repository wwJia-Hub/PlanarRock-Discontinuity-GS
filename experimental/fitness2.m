function fit= fitness2(x,data)
distances = dip_distance(data, x);
[min_values, ~] = min(distances, [], 2);
% 累加所有最小值
fit = 1000*sum(min_values);

if isnan(fit)
    fit=inf;
end
end