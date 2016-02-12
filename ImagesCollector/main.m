
clear;
clc;

%start timer
start_time = clock;

%% Load data path and set variables
%base_path = cd;
data_path = '/media/saverio/DATA/';
collect = false;
download = false;
detect = true;
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
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Detect and crop the images donwloaded for each identity %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if detect == true
   
   dataset = cat(2, classes.description, classes.name');
   
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
                   dets(index).image = strrep(box{1,1}, identity_path, '');
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
   
   save([data_path, 'data/dataset.mat'], ['dataset', num2str(start_idx), '-', num2str(end_idx)]);
   %delete parallel pool
   delete(gcp);
end


fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));
