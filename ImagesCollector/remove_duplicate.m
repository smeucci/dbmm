function remove_duplicate(DATA_PATH, start_idx, end_idx, start_time, config)
% REMOVE_DUPLICATE removes duplicated images from the dataset

    warning off MATLAB:dispatcher:nameConflict;
    
    addpath(genpath(config.VLFEAT_PATH));
    vl_setup;
    
    fprintf('Loading dataset..\n');
    d = load([DATA_PATH, 'data/dataset.mat']);
    fprintf('Dataset loaded in %.2f s\n', etime(clock, start_time));
    
    dataset = d.dataset;
    dataset_unique = dataset;
    numClusters = 64;
    
    %start parallel pool
    gcp();
    
    fprintf('## Removing duplicate images from identities %d to %d. ##\n', start_idx, end_idx);
    parfor i = start_idx:end_idx
        
        warning off MATLAB:dispatcher:nameConflict;
        
        identity = dataset(i,:);
        
        fprintf('Extracting sift %s - %s..\n', identity{1}, identity{2});
        identity_path = [DATA_PATH, 'img/', identity{2}, '_', identity{1}, '/'];
        
        for j = 1:size(identity{3}, 2)
            
            %read image data and crop it
            im_data = identity{3}(j);
            expr = '(aol|bing|yahoo).*$';
            tmp = regexp(im_data.image, expr, 'match');
            im_data.image = strtrim(tmp{1});
            identity{3}(j).image = im_data.image;
            im_path = [identity_path, im_data.image];
            im = imread(im_path);
            det = [im_data.box.left, im_data.box.top, im_data.box.right, im_data.box.bottom]';
            w = det(3) - det(1);
            h = det(4) - det(2);
            diff = [-w/2, -h/2, w/2, h/2]';        
            crop = lib.face_proc.faceCrop.crop(im, det+diff);
            
            if size(size(crop), 2) == 3
                im_crop = single(rgb2gray(crop));
            else
                im_crop = single(crop);
            end
            
            %extract local features using sift
            %[f,d] = lib.vlfeat.vl_sift(im_crop);
            [f,d] = vl_sift(im_crop);
            identity{3}(j).descriptor = single(d);

        end
        
        %generating codebook
        fprintf('Generating codebook..%s- %s\n', identity{1}, identity{2});
        %vl_setup;
        dataLearn = cat(2, identity{3}.descriptor);
        %centers = lib.vlfeat.vl_kmeans(dataLearn, numClusters);
        %kdtree = lib.vlfeat.vl_kdtreebuild(centers);
        centers = vl_kmeans(dataLearn, numClusters);
        kdtree = vl_kdtreebuild(centers);
        
        %create descriptor for each image using vlad encoding
        fprintf('Encoding %s - %s..\n', identity{1}, identity{2});
        for j = 1:size(identity{3}, 2)
            
            dataToBeEncoded = identity{3}(j).descriptor;
            %nn = lib.vlfeat.vl_kdtreequery(kdtree, centers, dataToBeEncoded);
            nn = vl_kdtreequery(kdtree, centers, dataToBeEncoded);

            numDataToBeEncoded = size(dataToBeEncoded, 2);
            assignments = single(zeros(numClusters,numDataToBeEncoded));
            assignments(sub2ind(size(assignments), nn, 1:length(nn))) = 1;
            %enc = lib.vlfeat.vl_vlad(dataToBeEncoded,centers,assignments);
            enc = vl_vlad(dataToBeEncoded,centers,assignments);
            identity{3}(j).descriptor = enc;
            
        end
    
        %clustering images descriptor to see which images are the same
        fprintf('Clustering images %s - %s..\n', identity{1}, identity{2});
        dataEncoded = cat(2, identity{3}.descriptor);
        %centers = lib.vlfeat.vl_kmeans(dataEncoded, size(identity{3}, 2));
        centers = vl_kmeans(dataEncoded, size(identity{3}, 2));
        dmat = eucliddist(dataEncoded', centers');

        for h = 1:size(dmat, 2)
            [val, idx] = min(dmat(:,h));
            identity{3}(idx).unique = 1;
        end
    
        %removing duplicate images from dataset
        fprintf('Removing duplicate images %s - %s..\n', identity{1}, identity{2});
        data_unique = struct('image', NaN, 'identity', NaN, 'label', NaN, 'box', NaN);
        index = 1;
        for j = 1:size(identity{3}, 2)
            im_data = identity{3}(j);
            if im_data.unique == 1
                data_unique(index) = rmfield(im_data, {'descriptor', 'unique'});
                index = index + 1;
            end
        end

        dataset_unique{i,3} = data_unique;

        fprintf(' - Identity: %s - %s - Elapsed time: %.2f s\n', identity{1}, identity{2}, etime(clock, start_time));

    end
    
    dataset = dataset_unique;
    
    save([DATA_PATH, 'data/dataset.mat'], 'dataset');
    %save_backup
    save([DATA_PATH, 'data/dataset-unique'], 'dataset');
    
    %delete parallel pool
    delete(gcp);

end