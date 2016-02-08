
%clear all;
clc;

%start timer
start_time = clock;

%load data path and set variables
data_path = '/media/saverio/DATA/';
collect = false;
download = false;
detect = true;
detect_old = false;
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
        list_ok_lbl = setdiff(classes.name, ok_labels', 'stable');
        list_ok_id = setdiff(classes.description, ok_identities, 'stable');
    else
        list_ok_lbl = classes.name;
        list_ok_id = classes.description;
    end
    
    for i = 1:4%size(list_ok_lbl, 2)
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
        list_done_lbl = setdiff(classes.name, done_labels', 'stable');
        list_done_id = setdiff(classes.description, done_identities, 'stable');
    else
        list_done_lbl = classes.name;
        list_done_id = classes.description;
    end
    
    for i = 1:4%size(list_done_lbl, 2)
        identity = list_done_id{i, 1};
        label = list_done_lbl{1, i};
    
        download_cmd = ['python downloader.py ', '"', identity, '" ', '"', label, '" ', '"', data_path, '" '];
        system(download_cmd);
    end
end

if detect == true
   imgcrop_folder = [data_path, 'imgcrop/'];
   if ~exist(imgcrop_folder, 'dir')
       mkdir(imgcrop_folder);
   end
   
   for idx = 1:1%size(classes.description)
       identity = classes.description{idx, 1};
       label = classes.name{1, idx};
      
       identitycrop_folder = [imgcrop_folder,  label, '_', identity, '/'];
       if ~exist(identitycrop_folder, 'dir')
           mkdir(identitycrop_folder);
       end
       
       search_engine = {'aol', 'bing', 'yahoo'};
       for se = 1:1%size(search_engine, 2)
           enginecrop_folder = [identitycrop_folder, search_engine{1, se}, '/'];
           if ~exist(enginecrop_folder, 'dir')
               mkdir(enginecrop_folder);
           end
           fprintf('Detect and crop identity: %s - %s..', identity, search_engine{1, se});
           cmd = ['./face_detector ', strrep(enginecrop_folder, 'imgcrop', 'img'), '*'];
           
           [status, cmdout] = system(cmd);
           fprintf('\n - Elapsed time: %.2f s\n', etime(clock, start_time));
           imgout = strsplit(cmdout, ';');
           
           for i = 1:size(imgout, 2)             
                output = strsplit(imgout{1, i}, ',');
                for j = 1:size(output, 2)-1
                    box = strsplit(output{1, j}, '+');
                    det = zeros(4, 1);
                    for h = 1:size(det, 1)
                       det(h, 1) = str2num(box{1, h+1}); 
                    end
                    %crop and save
                    warning off MATLAB:colon:nonIntegerIndex;
                    im = imread(strrep(strtrim(box{1,1}), ' ', ''));
                    %for bigger crop
                    %diff = [-det(1)/2, -det(2)/2, det(3)/2, det(4)/2];
                    diff = [0,0,0,0];
                    crop = lib.face_proc.faceCrop.crop(im, det+diff');
                    impath = strrep(box{1,1}, 'img', 'imgcrop');
                    impath = strrep(impath, '.jpg', '');
                    imwrite(crop, strtrim([impath, '-', num2str(j), '.jpg']));
                end
                     
           end
       end     
   end    
end


fprintf('\n - Elapsed time: %.2f s\n', etime(clock, start_time));
