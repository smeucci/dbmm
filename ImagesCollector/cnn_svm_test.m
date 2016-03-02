
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Testing of a linear SVM using fc layer of pre-trained cnn as image descriptor %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

load([data_path, 'data/model.mat']);

index = 1;
for i = 1:1%size(dataset, 1)
    
    identity = dataset(i,:);
    identity_path = [data_path, 'img/', identity{2}, '_', identity{1}, '/'];
    
    data_test = [];
    for j = 50:100%size(identity{3}, 2)
        % take the image and crop it using the face detection coordinates.
        disp(j);
        im_data = identity{3}(j);
        im_data.image = strtrim(strrep(im_data.image, 'Premature end of JPEG file', ''));
        identity{3}(j).image = im_data.image;
        im_path = [identity_path, im_data.image];
        im = imread(im_path);
        det = [im_data.box.left, im_data.box.top, im_data.box.right, im_data.box.bottom]';    
        crop = lib.face_proc.faceCrop.crop(im, det);
        
        % extract the fc layer of the pre-trained cnn as descriptor.
        im_ = single(crop);
        im_ = imresize(im_, net.normalization.imageSize(1:2)) ;
        im_ = bsxfun(@minus,im_,net.normalization.averageImage) ;
        res = vl_simplenn(net, im_);
        feature = squeeze(res(feat_layer).x);
        
        % predict the class of the image using a pre-computed svm model.
        predicted_label = lib.libsvm.svmpredict(i, feature', model);
        
        % save result as field struct.
        
        data_test(index).image = im_data.image;
        data_test(index).identity = im_data.label;
        data_test(index).box = [num2str(im_data.box.left), ',', num2str(im_data.box.top), ',', ...
                                num2str(im_data.box.right), ',', num2str(im_data.box.bottom)];
        if i == predicted_label
            data_test(index).predicted = 1;
        else
            data_test(index).predicted = 0;
        end
      
        index = index + 1;
    end
    
    %save results to db, 
    data_to_insert = struct2table(data_test);
    %connect to db
    
    fprintf(' - Identity: %s - %s, Elapsed time: %.2f s\n', identity{1}, identity{2}, etime(clock, start_time));
    
end


fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));
