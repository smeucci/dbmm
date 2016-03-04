
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Classification with a linear SVM using fc layer of pre-trained cnn as image descriptor %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%load training model
load([data_path, 'data/model.mat']);

fprintf('########## CLASSIFICATION ##########\n\n');

for i = 1:1%size(dataset, 1)
     
    index = 1;
    identity = dataset(i,:);
    identity_path = [data_path, 'img/', identity{2}, '_', identity{1}, '/'];
    fprintf('Images classification of identity %s - %s\n', identity{2}, identity{1});
    
    %connect to database
    conn = database('dataset', 'root', 'pwd', 'Vendor', 'MySQL', 'Server', 'localhost');
    
    data_test = [];
    tot = 0;
    max_size = 10;%size(identity{3}, 2);
    
    reverseStr = '';
    
    for j = 1:max_size
        
        % take the image and crop it using the face detection coordinates.
        im_data = identity{3}(j);
        %im_data.image = strtrim(strrep(im_data.image, 'Premature end of JPEG file', ''));
        expr = '(aol|bing|yahoo).*$';
        tmp = regexp(im_data.image, expr, 'match');
        im_data.image = strtrim(tmp{1});
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
        feature = squeeze(res(feat_layer).x)';
        
        % predict the class of the image using a pre-computed svm model.
        [output, predicted_label] = evalc('lib.libsvm.svmpredict(i, double(feature), model)');
        
        % save result as struct.
        data_test(index).image = im_data.image;
        data_test(index).identity = im_data.label;
        data_test(index).box = [num2str(im_data.box.left), ',', num2str(im_data.box.top), ',', ...
                                num2str(im_data.box.right), ',', num2str(im_data.box.bottom)];
                            
        %check if prediction matches expected label
        if i == predicted_label
            data_test(index).predicted = 1;
            tot = tot + 1;
        else
            data_test(index).predicted = 0;
        end
        
        index = index + 1;
                     
        %print progress
        msg = sprintf('#Progress identity %s - %s: %d', identity{2}, identity{1}, ceil(100*(j/max_size)));
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));

    end
    fprintf('\n');
    
    %save results to db
    data_to_insert = struct2cell(data_test);
    fprintf('Saving identity %s - %s\n', identity{2}, identity{1});
    %datainsert(conn, 'images', {'image', 'identity', 'box', 'predicted'}, squeeze(data_to_insert)');
    %update(conn, 'identities', {'num_images'}, tot, ['where label = "', identity{2}, '"']);
    
    fprintf(' - Identity: %s - %s, Elapsed time: %.2f s\n\n', identity{1}, identity{2}, etime(clock, start_time));
    
end

fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));
