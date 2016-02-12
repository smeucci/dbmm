
start_time = clock;
identity_path = '/media/saverio/DATA/img/n00000001_A.J._Buckley/';
identity = 'A.J._Buckley';
label = 'n00000001';
search_engine = {'aol', 'bing', 'yahoo'};
flag = false;
if flag == true
    for se = 1:size(search_engine, 2)
       engine_path = [identity_path, search_engine{1, se}, '/'];

       fprintf('Detect and crop identity: %s - %s - %s..', identity, label, search_engine{1, se});
       cmd = ['./face_detector ', engine_path, '*.jpg'];

       [status, cmdout] = system(cmd);
       fprintf('\n - %s - %s - %s - Elapsed time: %.2f s\n', identity, label, search_engine{1, se}, etime(clock, start_time));
    end
else
    fprintf('Detect and crop identity: %s - %s..', identity, label);
    cmd = ['./face_detector ', identity_path, '*/*.jpg'];

    [status, cmdout] = system(cmd);
    fprintf('\n - %s - %s - Elapsed time: %.2f s\n', identity, label, etime(clock, start_time));
    
end