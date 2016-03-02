
clear;
clc;

%start timer
start_time = clock;

%% Load data path and set variables
%base_path = cd;
data_path = '/media/saverio/DATA/';
collect = false;
download = false;
detect = false;
remove = true;
num_to_collect = 10;
% Indexes for detection
start_idx = 1;
end_idx = 4;

%% Load list of identities
load([data_path, 'data/', 'identities.mat']);
identities_txt = [data_path, 'data/identities.txt'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Collect images for list of identities %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        %pause(10);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Download images for list of identities %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        %pause(5);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Detect and crop the images donwloaded for each identity %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if detect == true
   
   if ~exist([data_path, 'data/dataset.mat'], 'file')
       dataset = cat(2, classes.description, classes.name');
   else
       fprintf('Loading dataset..\n');
       load([data_path, 'data/dataset.mat']);
   end
   
   %start parallel pool
   gcp();
   
   fprintf('## Detecting faces from identities %d to %d. ##\n', start_idx, end_idx);
   parfor idx = start_idx:end_idx%size(dataset, 1)
       
       identity = classes.description{idx, 1};
       label = classes.name{1, idx};
       
       dets = [];
       index = 1;
       
       identity_path = [data_path, 'img/',  label, '_', identity, '/'];
              
       cmd = ['./face_detector ', identity_path, '*/*.jpg'];
       [status, cmdout] = system(cmd);
       
       fprintf('- %s - %s - Elapsed time: %.2f s\n', identity, label, etime(clock, start_time));
       output = strsplit(cmdout, ';');
       
       for i = 1:size(output, 2)-1
           
           if size(output{1,i}, 2) > 1
               
               try          
                   box = strsplit(output{1, i}, '+');
                   dets(index).image = strtrim(strrep(strrep(box{1,1}, identity_path, ''), 'Premature end of JPEG file', ''));
                   dets(index).identity = identity;
                   dets(index).label = label;
                   
                   coords = struct();
                   coords.left = str2double(box{1,2});
                   coords.top = str2double(box{1,3});
                   coords.right = str2double(box{1,4});
                   coords.bottom = str2double(box{1,5});

                   dets(index).box = coords;

                   index = index + 1;

               catch
                   %do nothing
               end
                           
           end
                     
       end
       
       dataset{idx, 3} = dets;
       
   end
   
   save([data_path, 'data/datasetAB.mat'], 'dataset');
   %delete parallel pool
   delete(gcp);
   
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Remove duplicate images for every identity %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if remove == true
    
    addpath(genpath('/home/saverio/Ingegneria/Visual And Multimedia Recognition/Elaborato/vlfeat/'));

    load([data_path, 'data/dataset.mat']);
    dataset_unique = dataset;
    numClusters = 64;
    
    %start parallel pool
    gcp();
    
    fprintf('## Removing duplicate images from identities %d to %d. ##\n', start_idx, end_idx);
    parfor i = start_idx:end_idx%size(dataset, 1)
        
        warning off MATLAB:dispatcher:nameConflict;
        
        identity = dataset(i,:);
        
        fprintf('Extracting sift %s - %s..\n', identity{1}, identity{2});
        identity_path = [data_path, 'img/', identity{2}, '_', identity{1}, '/'];
        for j = 1:size(identity{3}, 2)
            %fprintf('%d / %d\n', j, size(identity{3}, 2));
            im_data = identity{3}(j);
            im_data.image = strtrim(strrep(im_data.image, 'Premature end of JPEG file', ''));
            identity{3}(j).image = im_data.image;
            im_path = [identity_path, im_data.image];
            im = imread(im_path);
            det = [im_data.box.left, im_data.box.top, im_data.box.right, im_data.box.bottom]';
            w = det(3) - det(1);
            h = det(4) - det(2);
            diff = [-w/2, -h/2, w/2, h/2]';        
            crop = lib.face_proc.faceCrop.crop(im, det+diff);
            if size(size(crop), 2) == 3
                im_crop = single(rgb2gray(crop));
            else
                im_crop = single(crop);
            end
            [f,d] = vl_sift(im_crop);
            identity{3}(j).descriptor = single(d);

        end
        fprintf('Generating codebook..%s- %s\n', identity{1}, identity{2});
        vl_setup;
        dataLearn = cat(2, identity{3}.descriptor);
        centers = vl_kmeans(dataLearn, numClusters);
        kdtree = vl_kdtreebuild(centers) ;
        
        fprintf('Encoding %s - %s..\n', identity{1}, identity{2});
        for j = 1:size(identity{3}, 2)
            %fprintf('%d / %d\n', j, size(identity{3}, 2));
            dataToBeEncoded = identity{3}(j).descriptor;
            nn = vl_kdtreequery(kdtree, centers, dataToBeEncoded) ;

            numDataToBeEncoded = size(dataToBeEncoded, 2);
            assignments = single(zeros(numClusters,numDataToBeEncoded));
            assignments(sub2ind(size(assignments), nn, 1:length(nn))) = 1;
            enc = vl_vlad(dataToBeEncoded,centers,assignments);
            identity{3}(j).descriptor = enc;
        end

        fprintf('Clustering images %s - %s..\n', identity{1}, identity{2});
        dataEncoded = cat(2, identity{3}.descriptor);
        centers = vl_kmeans(dataEncoded, size(identity{3}, 2));
        dmat = eucliddist(dataEncoded', centers');

        for h = 1:size(dmat, 2)
            [val, idx] = min(dmat(:,h));
            identity{3}(idx).unique = 1;
        end

        fprintf('Removing duplicate images %s - %s..\n', identity{1}, identity{2});
        data_unique = struct('image', NaN, 'identity', NaN, 'label', NaN, 'box', NaN);
        index = 1;
        for j = 1:size(identity{3}, 2)
            im_data = identity{3}(j);
            if im_data.unique == 1
                data_unique(index) = rmfield(im_data, {'descriptor', 'unique'});
                index = index + 1;
            end
        end

        dataset_unique{i,3} = data_unique;

        fprintf(' - Identity: %s - %s - Elapsed time: %.2f s\n', identity{1}, identity{2}, etime(clock, start_time));

    end
    
    dataset = dataset_unique;
    
    save([data_path, 'data/dataset.mat'], 'dataset');
    
    %delete parallel pool
    delete(gcp);
    
end

fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));

%exit;
