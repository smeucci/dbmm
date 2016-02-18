warning off MATLAB:dispatcher:nameConflict;

clear;
clc;

start_time = clock;
addpath(genpath('/home/saverio/Ingegneria/Visual And Multimedia Recognition/Elaborato/vlfeat/'));

data_path = '/media/saverio/DATA/';
load([data_path, 'data/dataset.mat']);

numClusters = 64;
for i = 1:4%size(dataset, 1)
    
    fprintf('Extracting sift %s - %s..\n', dataset{i,1}, dataset{i,2});
    identity_path = [data_path, 'img/', dataset{i, 2}, '_', dataset{i, 1}, '/'];
    for j = 1:size(dataset{i, 3}, 2)
        fprintf('%d / %d\n', j, size(dataset{i,3}, 2));
        im_data = dataset{i,3}(j);
        im_path = [identity_path, strtrim(strrep(im_data.image, 'Premature end of JPEG file', ''))];
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
        [f,d] = vl_sift(im_crop);
        dataset{i,3}(j).descriptor = single(d);
        
    end
    fprintf('Generating codebook..\n');
    vl_setup;
    dataLearn = cat(2, dataset{i,3}.descriptor);
    centers = vl_kmeans(dataLearn, numClusters);
    kdtree = vl_kdtreebuild(centers) ;
    fprintf('Encoding %s - %s..\n', dataset{i,1}, dataset{i,2});
    for j = 1:size(dataset{i, 3}, 2)
        fprintf('%d / %d\n', j, size(dataset{i,3}, 2));
        dataToBeEncoded = dataset{i,3}(j).descriptor;
        nn = vl_kdtreequery(kdtree, centers, dataToBeEncoded) ;
        
        numDataToBeEncoded = size(dataToBeEncoded, 2);
        assignments = single(zeros(numClusters,numDataToBeEncoded));
        assignments(sub2ind(size(assignments), nn, 1:length(nn))) = 1;
        enc = vl_vlad(dataToBeEncoded,centers,assignments);
        dataset{i,3}(j).descriptor = enc;
    end
    
    fprintf('Assignment %s - %s..\n', dataset{i,1}, dataset{i,2});
    dataEncoded = cat(2, dataset{i,3}.descriptor);
    centers = vl_kmeans(dataEncoded, size(dataset{i,3}, 2));
    dmat = eucliddist(dataEncoded', centers');
    
    for h = 1:size(dmat, 2)
        [val, idx] = min(dmat(:,h));
        dataset{i,3}(idx).unique = 1;
        
    end
    
    if ~exist([identity_path, 'unique/'], 'dir')
        mkdir([identity_path, 'unique/']);
    end
    
    fprintf('Removing duplicate images %s - %s..\n', dataset{i,1}, dataset{i,2});
    dataset_unique = struct('image', NaN, 'identity', NaN, 'label', NaN, 'box', NaN, 'descriptor', NaN, 'unique', NaN);
    index = 1;
    for j = 1:size(dataset{i,3}, 2)
        im_data = dataset{i,3}(j);
        if im_data.unique == 1
            dataset_unique(index) = im_data;
            index = index + 1;
        end
        
    end
    
    dataset{i,3} = dataset_unique;
    save([data_path, 'data/dataset_unique.mat'], 'dataset');
    
    fprintf(' - Identity: %s - %s - Elapsed time: %.2f s\n', dataset{i,1}, dataset{i,2}, etime(clock, start_time));
    
end

fprintf('\n - END- Elapsed time: %.2f s\n', etime(clock, start_time));
