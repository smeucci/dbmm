
clear all;
clc;

%load paths and set variables
base_path = '/media/saverio/DATA/';
detect = false;
search = true;
num_of_imgs = 10;

%load list of identities
load([base_path, 'data/', 'identities.mat']);

%load face detector 
face_model_path = [base_path, 'data/face_model.mat'];
faceDet = lib.face_detector.dpmCascadeDetector(face_model_path);

dataset = cell(size(classes.description, 1), 1);

start_time = clock;

gcp();
parfor i = 1:4%size(classes.description, 1)
    
    query = classes.description{i, 1};
    name = classes.name{1, i};
    
    %if true, get images for the identity
    if search == true
        cmd = ['python imcollector.py ', '"', query, '" ', '"', name, '" ', '"', ...
                        [base_path, 'img/'], '" ', '"', num2str(num_of_imgs), '"'];
        system(cmd);
    end
    
    %load the info about image paths and labels from txt file
    im_path = [base_path, 'img/', name, '_', query, '/', name, '_paths.txt'];
    if exist(im_path, 'file')
        [imgs, labels, rank] = textread(im_path, '%s %s %s', 'delimiter', '-');
        tmp = cat(2, imgs, labels, rank);
        dataset{i, 1} = tmp;
    end
    
    %detect face
    if detect == true
        face_detector(dataset{i, 1}, faceDet, base_path);
    end
    
end

delete(gcp)

fprintf('\n - Elapsed time: %.2f s\n', etime(clock, start_time));
