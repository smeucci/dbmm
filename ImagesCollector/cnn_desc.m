
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extraction of fc layer of pre-trained cnn %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;

start_time = clock;

% Load data path and set variables

warning off MATLAB:dispatcher:nameConflict;
warning off MATLAB:colon:nonIntegerIndex;

data_path = '/media/saverio/DATA/';
addpath(genpath('/home/saverio/Ingegneria/Visual And Multimedia Recognition/Elaborato/vlfeat/'));
addpath(genpath('/home/saverio/Ingegneria/Visual And Multimedia Recognition/Elaborato/matconvnet/'));
vl_setupnn;

load([data_path, 'data/dataset.mat']);
net_path = [data_path, 'data/vgg-face.mat'];

feat_layer = 36;

% Load pre trained net
if ~exist('net','var')
    fprintf('Loading ConvNet\n');
    net = load(net_path);
    load([data_path, 'data/dataset_lab_CNN_correct.mat']);
else
    fprintf('ConvNet already loaded\n');
end

for i = 1:1%size(dataset, 1)
    
    identity = dataset(i,:);
    identity_path = [data_path, 'img/', identity{2}, '_', identity{1}, '/'];
    
    %extract fc layer for each image
    tot = 0;
    for j = 1:size(identity{3}, 2)
        im_data = identity{3}(j);
        im_data.image = strtrim(strrep(im_data.image, 'Premature end of JPEG file', ''));
        identity{3}(j).image = im_data.image;
        im_path = [identity_path, im_data.image];
        im = imread(im_path);
        det = [im_data.box.left, im_data.box.top, im_data.box.right, im_data.box.bottom]';    
        crop = lib.face_proc.faceCrop.crop(im, det);
        
        im_ = single(crop);
        im_ = imresize(im_, net.normalization.imageSize(1:2)) ;
        im_ = bsxfun(@minus,im_,net.normalization.averageImage) ;
        res = vl_simplenn(net, im_);
        feature = squeeze(res(feat_layer).x);
        [score, idx] = max(res(38).x);
        fprintf('Img %d: %s - predicted class: %s - score: %f\n', j, im_path, net.classes.description{idx}, score);
        if strcmp(identity{1}, net.classes.description{idx})
            tot = tot + 1;
        end
        
    end
 
    fprintf(' - Identity: %s - %s - TOT: %d, Elapsed time: %.2f s\n', identity{1}, identity{2}, tot, etime(clock, start_time));
    
end

fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));
