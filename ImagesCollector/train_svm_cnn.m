function train_svm_cnn(DATA_PATH, start_idx, end_idx, start_time, config)
% TRAIN_SVM_CNN extracts the fc layer of a pre-trained cnn, to be used as
% descriptors in training

    %warning off MATLAB:dispatcher:nameConflict;
    %warning off MATLAB:colon:nonIntegerIndex;
    warning off;
    
    addpath(genpath(config.MATCONVNET_PATH));
    vl_setupnn;

    %load dataset 
    if ~exist('dataset','var')
        fprintf('Loading dataset\n');
        load([DATA_PATH, 'data/dataset.mat']);
        fprintf('Dataset loaded in %.2f s\n\n', etime(clock, start_time));
    else
        fprintf('Dataset already loaded\n\n');
    end

    FEAT_LAYER = str2double(config.FEAT_LAYER);
    NUM_OF_IMAGES_PER_CLASS_TRAIN = str2double(config.NUM_OF_IMAGES_PER_CLASS_TRAIN);

    %load pre trained net
    if ~exist('net','var')
        fprintf('Loading ConvNet\n\n');
        net = load([DATA_PATH, 'data/vgg-face.mat']);
    else
        fprintf('ConvNet already loaded\n\n');
    end

    %load data_train
    if ~exist([DATA_PATH, 'data/data_train.mat'],'file')
            data_train = [];
            index = 1;
    else
        fprintf('Loading Data Train\n\n');
        load([DATA_PATH, 'data/data_train.mat']);
        index = size(data_train, 2) + 1;
    end
    
    %connect to database
    conn = database(config.DATABASE_DATASET, config.DB_USER, config.DB_PWD, 'Vendor', 'MySQL', 'Server', config.DB_LOCATION);

    fprintf('########## TRAINING ##########\n\n');

    for i = start_idx:end_idx

        identity = dataset(i,:);
        identity_path = [DATA_PATH, 'img/', identity{2}, '_', identity{1}, '/'];
        fprintf('Training: identity %s - %s\n', identity{2}, identity{1});

        %insert identity into db
        try
            fastinsert(conn, 'identities', {'label', 'name'}, {identity{2}, identity{1}}); 
        catch
            fprintf('Identity %s - %s already in database\n', identity{2}, identity{1});
        end

        %extract fc layer for each image
        %reverseStr = '';
        
        for j = 1:NUM_OF_IMAGES_PER_CLASS_TRAIN
            im_data = identity{3}(j);
            im_path = [identity_path, im_data.image];
            im = imread(im_path);
            det = [im_data.box.left, im_data.box.top, im_data.box.right, im_data.box.bottom]';    
            crop = lib.face_proc.faceCrop.crop(im, det);

            im_ = single(crop);
            im_ = imresize(im_, net.normalization.imageSize(1:2)) ;
            im_ = bsxfun(@minus,im_,net.normalization.averageImage) ;
            res = vl_simplenn(net, im_);
            feature = squeeze(res(FEAT_LAYER).x);

            %saving result as struct
            data_train(index).desc = feature';
            data_train(index).class = i;
            index = index + 1;

            %print progress
            %msg = sprintf('#Progress identity %s - %s: %d', identity{2}, identity{1}, ceil(100*(j/max_size)));
            %fprintf([reverseStr, msg]);
            %reverseStr = repmat(sprintf('\b'), 1, length(msg));

        end
        fprintf('\n');

        save([DATA_PATH, 'data/data_train.mat'], 'data_train');
        fprintf(' - Identity: %s - %s: Elapsed time: %.2f s\n\n', identity{1}, identity{2}, etime(clock, start_time));

    end

end