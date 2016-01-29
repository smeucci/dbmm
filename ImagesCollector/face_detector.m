function face_detector(dataset, faceDet, data_path)
    
    %warning off;
    resize = 800; %resizing base on image height
    crop_dir = strrep([data_path, dataset{1, 1}], [dataset{1, 5}, '.jpg'], 'crop/');
    if ~exist(crop_dir, 'dir')
        
        for i = 1:size(dataset, 1)

            fprintf('Detect and crop: %s\n', dataset{i, 1});
            impath = [data_path, dataset{i, 1}];
            im = imread(impath);

            %resize the image if too big, for working locally
            im = imresize(im, [resize NaN]);

            %detect the faces within the image
            det = faceDet.detect(im);
            if size(det, 1) > 0

                for j = 1:size(det, 2)

                    %check if detection confidence is above a threshold
                    if det(6, j) >= 2     

                        %crop the image and save to disk
                        diff = [-100, -100, 100, 100]; %for bigger crop
                        crop = lib.face_proc.faceCrop.crop(im, det(1:4, j)+diff');

                        %create the folder where to put the cropped images, once
                        %per identity
                        crop_path = strrep(impath, [dataset{i, 5}, '.jpg'], 'crop/');
                        if ~exist(crop_path, 'dir')
                            mkdir(crop_path);
                        end

                        %save croped image to disk
                        imwrite(crop, [crop_path, dataset{i, 3}, '-', num2str(j) ,'.jpg']);    

                    end

                end 

            end
            
        end
            
        fprintf('Finish face detection: %s\n', dataset{i, 2});
        
    else
    
        fprintf('Face detection already done: %s\n', dataset{1, 2});
        
    end
    
end