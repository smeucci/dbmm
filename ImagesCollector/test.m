warning off MATLAB:dispatcher:nameConflict;

addpath(genpath('/home/saverio/Ingegneria/Visual And Multimedia Recognition/Elaborato/dbmm/ImagesCollector/vlfeat/'));

data_path = '/media/saverio/DATA/';
load([data_path, 'data/dataset.mat']);

numClusters = 64;

for i = 1:1%size(dataset, 1)
    
    fprintf('Extracting sift..%s - %s\n', dataset{i,1}, dataset{i,2});
    identity_path = [data_path, 'img/', dataset{i, 2}, '_', dataset{i, 1}, '/'];
    dataLearn = [];
    for j = 1:size(dataset{i, 3}, 2)
        fprintf('%d / %d\n', j, size(dataset{i,3}, 2));
        im_data = dataset{1,3}(j);
        im_path = [identity_path, strtrim(im_data.image)];
        im = imread(im_path);
        det = [im_data.box.left, im_data.box.top, im_data.box.right, im_data.box.bottom]';
        w = det(3) - det(1);
        h = det(4) - det(2);
        w_scale = w/2;
        h_scale = h/2;
        diff = [-w_scale, -h_scale, w_scale, h_scale]';        
        crop = lib.face_proc.faceCrop.crop(im, det+diff);
        im_crop = single(rgb2gray(crop));
        [f,d] = vl_sift(im_crop);
        dataset{i,3}(j).descriptor = single(d);
        dataLearn = cat(2, dataLearn, single(d));
        
    end
    fprintf('Generating codebook..\n');
    vl_setup;
    centers = vl_kmeans(dataLearn, numClusters);
    clear dataLearn;
    kdtree = vl_kdtreebuild(centers) ;
    fprintf('Encoding %s - %s..\n', dataset{i,1}, dataset{i,2});
    dataEncoded = [];
    for j = 1:size(dataset{i, 3}, 2)
        fprintf('%d / %d\n', j, size(dataset{i,3}, 2));
        dataToBeEncoded = dataset{i,3}(j).descriptor;
        nn = vl_kdtreequery(kdtree, centers, dataToBeEncoded) ;
        
        numDataToBeEncoded = size(dataToBeEncoded, 2);
        assignments = single(zeros(numClusters,numDataToBeEncoded));
        assignments(sub2ind(size(assignments), nn, 1:length(nn))) = 1;
        enc = vl_vlad(dataToBeEncoded,centers,assignments);
        dataEncoded = cat(2, dataEncoded, enc);
        dataset{i,3}(j).descriptor = enc;
    end
    
    centers = vl_kmeans(dataEncoded, 50);
    dmat = eucliddist(dataEncoded', centers');
    
end






