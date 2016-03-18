function collect(classes, start_idx, end_idx, num_to_collect)

    for i = start_idx:end_idx
        identity = classes.description{i, 1};
        label = classes.name{1, i};
        
        collect_cmd = ['python +python/collector.py ', '"', identity, '" ', '"', label, '" ', '"', num2str(num_to_collect), '"'];
        system(collect_cmd);
        pause(10);
    end

end