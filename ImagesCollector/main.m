
clear all;
clc;

%start timer
start_time = clock;

%load data path and set variables
data_path = '/media/saverio/DATA/';
collect = false;
download = true;
detect = false;
num_to_collect = 10;

%load list of identities
load([data_path, 'data/', 'identities.mat']);
identities_txt = [data_path, 'data/identities.txt'];
%collect images for list of identities
if collect == true
    %get list of identities with status = OK
    status = 'OK';
    ok_identities_cmd =  ['python get_identities.py ', '"', status, '" ', '"', data_path, '" '];
    system(ok_identities_cmd);
    
    %build list to collect
    if exist(identities_txt, 'file')
        [ids, lbls] = textread(identities_txt, '%s %s', 'delimiter', '+');
        ok_labels = cat(2, lbls);
        ok_identities = cat(2, ids);
        list_ok_lbl = setdiff(classes.name, ok_labels');
        list_ok_id = setdiff(classes.description, ok_identities);
    else
        list_ok_lbl = classes.name;
        list_ok_id = classes.description;
    end
    
    
    for i = 1:2%size(list_ok_lbl, 2)
        identity = list_ok_id{i, 1};
        label = list_ok_lbl{1, i};
        
        collect_cmd = ['python collector.py ', '"', identity, '" ', '"', label, '" ', '"', num2str(num_to_collect), '"'];
        system(collect_cmd);
    
    end
end

%download images for list of identities
if download == true
    %get list of identities with status = DONE
    status = 'DONE';
    done_identities_cmd =  ['python get_identities.py ', '"', status, '" ', '"', data_path, '" '];
    system(done_identities_cmd);
    
    %build list to download
    if exist(identities_txt, 'file')
        [ids, lbls] = textread(identities_txt, '%s %s', 'delimiter', '+');
        done_labels = cat(2, lbls);
        done_identities = cat(2, ids);
        list_done_lbl = setdiff(classes.name, done_labels');
        list_done_id = setdiff(classes.description, done_identities);
    else
        list_done_lbl = classes.name;
        list_done_id = classes.description;
    end
    
    for i = 1:2%size(list_done_lbl, 2)
        identity = list_done_id{i, 1};
        label = list_done_lbl{1, i};
    
        download_cmd = ['python downloader.py ', '"', identity, '" ', '"', label, '" ', '"', data_path, '" '];
        system(download_cmd);
    end
end

%detect faces and crop images
if detect == true
    %load the face model and inizialize the face detector
    face_model_path = [data_path, 'data/face_model.mat'];
    faceDet = lib.face_detector.dpmCascadeDetector(face_model_path);

    dataset = cell(size(classes.description, 1), 1);
    
    %start the parallel pool
    gcp();
    parfor i = 1:4%size(classes.name, 2)
        identity = classes.description{i, 1};
        label = classes.name{1, i};
        file_path = [data_path, 'img/', label, '_', identity, '/', label, '_paths.txt'];
        if exist(file_path, 'file')
            [images, labels, names, engines, ranks] = textread(file_path, '%s %s %s %s %s', 'delimiter', '+');
            tmp = cat(2, images, labels, names, engines, ranks);
            dataset{i, 1} = tmp;
        end
        
        face_detector(dataset{i, 1}, faceDet, data_path)
        
    end
    %shutdown parallel pool
    delete(gcp)
    
end

fprintf('\n - Elapsed time: %.2f s\n', etime(clock, start_time));
