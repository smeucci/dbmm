
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Traning of a linear SVM using fc layer of pre-trained cnn as image descriptor %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;

start_time = clock;

% Load data path and set variables

%warning off MATLAB:dispatcher:nameConflict;
%warning off MATLAB:colon:nonIntegerIndex;
warning off;

data_path = '/media/saverio/DATA/';
addpath(genpath('/home/saverio/Ingegneria/Visual And Multimedia Recognition/Elaborato/vlfeat/'));
addpath(genpath('/home/saverio/Ingegneria/Visual And Multimedia Recognition/Elaborato/matconvnet/'));
vl_setupnn;

%load dataset 
if ~exist('dataset','var')
    fprintf('Loading dataset\n\n');
    load([data_path, 'data/dataset.mat']);
else
    fprintf('Dataset already loaded\n\n');
end

feat_layer = 36;

%load pre trained net
if ~exist('net','var')
    fprintf('Loading ConvNet\n\n');
    net = load([data_path, 'data/vgg-face.mat']);
else
    fprintf('ConvNet already loaded\n\n');
end

%load data_train
if ~exist([data_path, 'data/data_train.mat'],'file')
        data_train = [];
        index = 1;
else
    fprintf('Loading Data Train\n\n');
    load([data_path, 'data/data_train.mat']);
    index = size(data_train, 2) + 1;
end

fprintf('########## TRAINING ##########\n\n');

for i = 1:4%size(dataset, 1)
    
    identity = dataset(i,:);
    identity_path = [data_path, 'img/', identity{2}, '_', identity{1}, '/'];
    fprintf('Training: identity %s - %s\n', identity{2}, identity{1});
    
    %connect to database
    conn = database('dataset', 'root', 'pwd', 'Vendor', 'MySQL', 'Server', 'localhost');
    
    %insert identity into db
    try
        fastinsert(conn, 'identities', {'label', 'name'}, {identity{2}, identity{1}}); 
    catch
        fprintf('Identity %s - %s already in database\n', identity{2}, identity{1});
    end
    
    %extract fc layer for each image
    reverseStr = '';
    max_size = 10;
    for j = 1:max_size
        im_data = identity{3}(j);
        im_path = [identity_path, im_data.image];
        im = imread(im_path);
        det = [im_data.box.left, im_data.box.top, im_data.box.right, im_data.box.bottom]';    
        crop = lib.face_proc.faceCrop.crop(im, det);
        
        im_ = single(crop);
        im_ = imresize(im_, net.normalization.imageSize(1:2)) ;
        im_ = bsxfun(@minus,im_,net.normalization.averageImage) ;
        res = vl_simplenn(net, im_);
        feature = squeeze(res(feat_layer).x);
        
        %saving result as struct
        data_train(index).desc = feature';
        data_train(index).class = i;
        index = index + 1;
        
        %print progress
        msg = sprintf('#Progress identity %s - %s: %d', identity{2}, identity{1}, ceil(100*(j/max_size)));
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
        
    end
    fprintf('\n');
 
    save([data_path, 'data/data_train.mat'], 'data_train');
    fprintf(' - Identity: %s - %s: Elapsed time: %.2f s\n\n', identity{1}, identity{2}, etime(clock, start_time));
    
end

desc_train = double(cat(1, data_train.desc));
labels_train = cat(1, data_train.class);

fprintf('Computing model..\n');
model = lib.libsvm.svmtrain(labels_train, desc_train, '-t 0 -c 1');

save([data_path, 'data/model.mat'], 'model');

fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));

%exit;
