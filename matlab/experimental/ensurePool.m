function ensurePool(desiredN)
    if nargin==0 || isempty(desiredN)
        desiredN = min(parcluster('local').NumWorkers, feature('numcores'));
    end
    p = gcp('nocreate');
    if isempty(p)
        parpool('local', desiredN, 'IdleTimeout', 240);
    elseif p.NumWorkers ~= desiredN
        delete(p);
        parpool('local', desiredN, 'IdleTimeout', 240);
    end
end

