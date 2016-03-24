function collect(classes, start_idx, end_idx)
% COLLECT collects image urls from selected search engines for each
% identity passed

    for i = start_idx:end_idx
        identity = classes.description{i, 1};
        label = classes.name{1, i};
        
        collect_cmd = ['python +python/collector.py ', '"', identity, '" ', '"', label, '"'];
        system(collect_cmd);
        fprintf('\n');
        pause(10);
    end

end