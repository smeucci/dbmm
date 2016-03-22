
%clear;
clc;

%start timer
start_time = clock;

%% Load data path and set variables
data_path = '/media/saverio/DATA/TEST/';

do_collect = false;
do_download = false;
do_detect = false;
do_remove = false;
do_train = false;
do_test = false;
do_crop = false;

num_to_collect = 0;

% Indexes for cycling
start_idx = 0;
end_idx = 0;


%% Load list of identities
load([data_path, 'data/', 'identities.mat']);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Collect images for list of identities %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_collect == true
    
    collect(classes, start_idx, end_idx, num_to_collect);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Download images for list of identities %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_download == true
    
    download(classes, start_idx, end_idx, data_path);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Detect and crop the images donwloaded for each identity %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_detect == true
   
   detect(classes, data_path, start_idx, end_idx, start_time);
   
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Remove duplicate images for every identity %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_remove == true
    
    remove_duplicate(data_path, start_idx, end_idx, start_time);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Traning of a linear SVM using fc layer of pre-trained cnn as image descriptor %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_train == true
    
   train_svm_cnn(data_path, start_idx, end_idx, start_time);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Classification with a linear SVM using fc layer of pre-trained cnn as image descriptor %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_test == true
    
   test_svm_cnn(data_path, start_idx, end_idx, start_time);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cropping images for the visual validation  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_crop == true
    
   crop(data_path, start_time);
    
end


fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));

%exit;
