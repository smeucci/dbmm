function download(classes, start_idx, end_idx, data_path)

    for i = start_idx:end_idx
        identity = classes.description{i, 1};
        label = classes.name{1, i};
    
        download_cmd = ['python +python/downloader.py ', '"', identity, '" ', '"', label, '" ', '"', data_path, '" '];
        system(download_cmd);
        fprintf('\n');
        pause(5);
    end

end