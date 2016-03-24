
%clear;
clc;

%start timer
start_time = clock;

%% Load config file
config = readconf('config/config.conf');

START_IDX = str2double(config.START_IDX);
END_IDX = str2double(config.END_IDX);


%% Load list of identities
if strcmp(config.USE_MATFILE, 'true')
    load([config.DATA_PATH, 'data/', 'identities.mat']);
else
    %do something
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Collect images for list of identities %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(config.DO_COLLECT, 'true')
    
    collect(classes, START_IDX, END_IDX);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Download images for list of identities %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(config.DO_DOWNLOAD, 'true')
    
    download(classes, START_IDX, END_IDX);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Detect and crop the images donwloaded for each identity %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(config.DO_DETECT, 'true')
   
   detect(classes, config.DATA_PATH, START_IDX, END_IDX, start_time);
   
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Remove duplicate images for every identity %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(config.DO_REMOVE, 'true')
    
    remove_duplicate(config.DATA_PATH, START_IDX, END_IDX, start_time);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Traning of a linear SVM using fc layer of pre-trained cnn as image descriptor %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(config.DO_TRAIN, 'true')
    
   train_svm_cnn(config.DATA_PATH, START_IDX, END_IDX, start_time, config);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Classification with a linear SVM using fc layer of pre-trained cnn as image descriptor %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(config.DO_TEST, 'true')
    
   test_svm_cnn(config.DATA_PATH, START_IDX, END_IDX, start_time, config);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cropping images for the visual validation  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(config.DO_CROP, 'true')
    
   crop(config.DATA_PATH, start_time, config);
    
end


fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));

%exit;
