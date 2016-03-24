function crop(DATA_PATH, start_time, config)
% CROP crops the images of the dataset after the classification phase

    %create folder img_validation
    img_folder = [DATA_PATH, 'img_crop/'];
    if ~exist(img_folder, 'dir')
        mkdir(img_folder);
    end

    %connect to database
    conn = database(config.DATABASE_DATASET, config.DB_USER, config.DB_PWD, 'Vendor', 'MySQL', 'Server', config.DB_LOCATION);

    %query all the identities
    query = 'SELECT label, name FROM identities';
    curs = exec(conn, query);
    curs = fetch(curs);
    identities = curs.Data;

    %cycle through the identities
    for i = 1:size(identities, 1)

        label = identities{i, 1};
        name = identities{i, 2};

        fprintf('Identity: %s - %s\n', label, name);

        %create identity folder
        identity_folder = [img_folder, label, '_', name, '/'];
        if ~exist(identity_folder, 'dir')
            mkdir(identity_folder);
        end

        %select images of the identity
        query = ['SELECT * FROM images WHERE identity = ' '''' label '''']; 
        curs = exec(conn, query);
        curs = fetch(curs);
        images = curs.Data;

        %cycle through the images
        fprintf('Cropping images..\n');
        for j = 1:size(images, 1)

            image = images{j, 2};
            image_identity = images{j, 3};
            box = images{j, 4};
            predicted = images{j, 5};
            validation = images{j, 6};

            im_path = [DATA_PATH, 'img/', label, '_', name, '/', image];

            %crop the image
            split_box = strsplit(box, ',');
            left = str2double(split_box{1, 1});
            top = str2double(split_box{1, 2});
            right = str2double(split_box{1, 3});
            bottom = str2double(split_box{1, 4});

            im = imread(im_path);
            det = [left, top, right, bottom]';    
            w = det(3) - det(1);
            h = det(4) - det(2);
            diff = [-w/2, -h/2, w/2, h/2]';        
            im_crop = lib.face_proc.faceCrop.crop(im, det+diff);

            %save image and modify data of the image (name..)
            new_image = [num2str(j), '.jpg'];
            imwrite(im_crop, [identity_folder, new_image]);
            images{j, 1} = new_image;
            if isnan(validation)
               images{j, 6} = [];
            end

        end

        %insert all the identity images on db

        fprintf('Saving to db..\n');
        datainsert(conn, 'images_crop', {'image', 'old_image', 'identity', 'box', 'predicted', 'validation'}, images);

        fprintf('Done: %s - %s, Elapsed time: %.2f s\n\n', label, name, etime(clock, start_time)); 

    end

end