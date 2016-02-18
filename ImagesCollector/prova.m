load('/media/saverio/DATA/data/dataset_unique.mat')
data_path = '/media/saverio/DATA/';

for i = 2:4
   dets = dataset{i,3};
   index = 1;
   for j = 1:size(dets, 2)
       im_data = dets(j);
       folder_path = [data_path, 'img/', im_data.label, '_', im_data.identity, '/unique/'];
       if ~exist(folder_path, 'dir')
            mkdir(folder_path); 
       end
       im_path = strrep(folder_path, 'unique/', strtrim(strrep(im_data.image, 'Premature end of JPEG file', '')));
       try
            im = imread(im_path);
            det = [im_data.box.left, im_data.box.top, im_data.box.right, im_data.box.bottom]';
            w = det(3) - det(1);
            h = det(4) - det(2);
            diff = [-w/2, -h/2, w/2, h/2]';        
            crop = lib.face_proc.faceCrop.crop(im, det+diff);
            imwrite(crop, [folder_path, num2str(index), '.jpg']);
            index = index + 1;
       catch
            fprintf('Error: %s\n', im_path);
       end
           
   end
         
end