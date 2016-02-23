
%FEATURES EXTRACTION

%clear;
clc;

%start timer
start_time = clock;

%% Load data path and set variables
data_path = '/media/saverio/DATA/';
addpath(genpath('/home/saverio/Ingegneria/Visual And Multimedia Recognition/Elaborato/vlfeat/'));
addpath(genpath('/home/saverio/Ingegneria/Visual And Multimedia Recognition/Elaborato/matconvnet/'));
load([data_path, 'data/', 'identities.mat']);
net_path = [data_path, 'data/vgg-face.mat'];

%% Load pre trained net
if ~exist('net','var')
    net = load(net_path);
    load([data_path, 'data/dataset_lab_CNN_correct.mat']);
else
    disp('ConvNet already loaded')
end

search_engine = {'aol', 'bing', 'yahoo'};

for i = 2:2%size(classes.description, 1)
    identity = classes.description{i, 1};
    label = classes.name{1, i};
    
    identity_path = [data_path, 'imgcrop/', label, '_', identity, '/'];
    
    for se = 1:1%size(search_engine, 2)

        se_path = [identity_path, search_engine{1,se}, '/'];
        list_of_imgs = dir([se_path, '*.jpg']);

        for j = 1:10%size(list_of_imgs, 1)

            im_name = list_of_imgs(j).name;
            im_path = [se_path, im_name];
            fprintf(' - Features extraction: %s\n', im_path);
            im_ = imread(im_path);
            im_ = imresize(im_, [224 224]);
            im_ = single(im_);
            im_ = imresize(im_, net.normalization.imageSize(1:2)) ;
            im_ = bsxfun(@minus,im_,net.normalization.averageImage) ;
            res = vl_simplenn(net, im_);
            feature = squeeze(res(feat_layer+2).x);
            features = features ./ norm(features, 2);
            data.image = im_name;
            data.identity = identity;
            data.label = label;
            data.search_engine = search_engine{1, se};
            data.features = features;
            
            dataset(end+1) = data;
            
        end

    end
end