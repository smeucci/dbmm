
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
if ~exist('net','var')
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
if ~exist('data_train','var')
    fprintf('Loading training data\n\n');
    load([data_path, 'data/data_train.mat']);
else
    fprintf('Training data already loaded\n\n');
end

size_of_data_train = size(data_train, 2);
num_of_desc_per_identity = 50;
num_of_versus_identity = 10;

%connect to database
conn = database('dataset', 'root', 'pwd', 'Vendor', 'MySQL', 'Server', 'localhost');

st = 1;
en = 2;%size(dataset, 1);

fprintf('########## CLASSIFICATION from %d to %d ##########\n\n', st, en);

for i = st:en
    
    index = 1;
    identity = dataset(i,:);
    identity_path = [data_path, 'img/', identity{2}, '_', identity{1}, '/'];
    fprintf('Images classification of identity %s - %s\n', identity{2}, identity{1});
    
    %create tmp data_train related to the identity
    end_idx = i*num_of_desc_per_identity;
    start_idx = end_idx - num_of_desc_per_identity + 1;
    
    %select a random integer to determine a set of identities to be train
    %against the current identity i
    if end_idx < size_of_data_train/2
        r = randi([end_idx+1, size_of_data_train-(num_of_versus_identity*num_of_desc_per_identity)], 1, 1);
    else
        r = randi([1, (size_of_data_train/2)-(num_of_versus_identity*num_of_desc_per_identity)], 1, 1);
    end
    
    %create descriptors 
    data_train_identity = data_train(start_idx:end_idx);
    data_train_versus = data_train(r:r+(num_of_versus_identity*num_of_desc_per_identity)-1);
    
    %create labels
    label_identity = ones(num_of_desc_per_identity,1);
    label_versus = zeros(num_of_versus_identity*num_of_desc_per_identity,1);
    
    %create svm model
    desc_train = double(cat(1, data_train_identity.desc, data_train_versus.desc));
    labels_train = cat(1, label_identity, label_versus);
    
    fprintf('Creating svm model\n');
    model = lib.libsvm.svmtrain(labels_train, desc_train, '-t 0 -c 1');
    
    data_test = [];
    tot = 0;
    max_size = size(identity{3}, 2);
    
    reverseStr = '';
    
    for j = 1:max_size
        
        % take the image and crop it using the face detection coordinates.
        im_data = identity{3}(j);
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
        if predicted_label == 1
            data_test(index).predicted = 1;
            tot = tot + 1;
        elseif predicted_label == 0
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
    fprintf('Saving identity %s - %sElapsed time: %.2f s\n', identity{2}, identity{1}, etime(clock, start_time));
    datainsert(conn, 'images', {'image', 'identity', 'box', 'predicted'}, squeeze(data_to_insert)');
    update(conn, 'identities', {'num_images'}, tot, ['where label = "', identity{2}, '"']);
    
    fprintf(' - Identity: %s - %s, Elapsed time: %.2f s\n\n', identity{1}, identity{2}, etime(clock, start_time));
    
end

fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));

%exit;
