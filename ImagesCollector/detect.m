function detect(classes, DATA_PATH, start_idx, end_idx, start_time, config)
% DETECT detects faces in the dataset of images using dlib

    %create dataset variable or load it
   if ~exist([DATA_PATH, 'data/dataset.mat'], 'file')
       dataset = cat(2, classes.description, classes.name');
   else
       fprintf('Loading dataset..\n');
       load([DATA_PATH, 'data/dataset.mat']);
       fprintf('Dataset loaded in %.2f s\n', etime(clock, start_time));
   end
   
   identities = classes.description;
   labels = classes.name;
   
   %start parallel pool
   gcp();
   
   fprintf('## Detecting faces from identities %d to %d. ##\n', start_idx, end_idx);
   parfor idx = start_idx:end_idx
       
       identity = identities{idx, 1};
       label = labels{1, idx};
       
       dets = [];
       index = 1;
       
       identity_path = [DATA_PATH, 'img/',  label, '_', identity, '/'];
       
       %cmd = ['exec/./face_detector ', identity_path, '*/*.jpg'];
       cmd = [config.DLIB_PATH, '/examples/build/./face_detector ', identity_path, '*/*.jpg'];
       [status, cmdout] = system(cmd);
       
       output = strsplit(cmdout, ';');
       
       for i = 1:size(output, 2)-1
           
           if size(output{1,i}, 2) > 1
               
               try          
                   
                   box = strsplit(output{1, i}, '+');
                   expr = '(aol|bing|yahoo).*$';
                   tmp = regexp(box{1,1}, expr, 'match');
                   box{1,1} = strtrim(tmp{1});
                   %dets(index).image = strtrim(strrep(strrep(box{1,1}, identity_path, ''), 'Premature end of JPEG file', ''));
                   dets(index).image = box{1,1};
                   dets(index).identity = identity;
                   dets(index).label = label;
                   
                   coords = struct();
                   coords.left = str2double(box{1,2});
                   coords.top = str2double(box{1,3});
                   coords.right = str2double(box{1,4});
                   coords.bottom = str2double(box{1,5});

                   dets(index).box = coords;

                   index = index + 1;

               catch
                   %do nothing
               end
                           
           end
                     
       end
       
       dataset{idx, 3} = dets;
       
       fprintf('- %s - %s - Elapsed time: %.2f s\n', identity, label, etime(clock, start_time));
       
   end
   
   save([DATA_PATH, 'data/dataset.mat'], 'dataset');
   %save backup
   save([DATA_PATH, 'data/dataset-detection.mat'], 'dataset');
   %delete parallel pool
   delete(gcp);

end