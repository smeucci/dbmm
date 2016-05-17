function [results] = compute_statistics()

    clc;

    %load configuration file
    config = readconf('config/config.conf');

    %connect to database
    conn = database(config.DATABASE_DATASET, config.DB_USER, config.DB_PWD, 'Vendor', 'MySQL', 'Server', config.DB_LOCATION);

    %get identities
    query = 'SELECT label, name, num_images FROM identities WHERE remove is NULL';
    curs = exec(conn, query);
    curs = fetch(curs);
    identities = curs.Data;
    
    fprintf('Computing prediction statistics for %d identities of database "%s"\n', size(identities, 1), config.DATABASE_DATASET);
    
    results = [];
    for i = 1:size(identities, 1)
        
        label = identities{i, 1};
        
        query = ['SELECT * FROM images_crop WHERE identity = ' '''' label ''''];
        curs = exec(conn, query);
        curs = fetch(curs);
        images = curs.Data;
        
        predictions = images(:, 6);
        validations = images(:, 7);
        
        tot = size(validations, 1);
        tp = 0; fp = 0; tn = 0; fn = 0;
        for j = 1:tot
            
            prediction = predictions{j};
            validation = validations{j};
            
            if prediction == 1 && isnan(validation)
                tp = tp + 1;
            elseif prediction == 1 && validation == 1                
                tp = tp + 1;                
            elseif prediction == 1 && validation == 0                
                fp = fp + 1;                
            elseif prediction == 0 && isnan(validation)                
                tn = tn + 1;                
            elseif prediction == 0 && validation == 1                
                fn = fn + 1;                
            elseif prediction == 0 && validation == 0               
                tn = tn + 1;            
            end
            
        end
        
        result.label = label;
        result.name = identities{i, 2};
        result.tpr = tp / tot;
        result.fpr = fp / tot;
        result.tnr = tn / tot;
        result.fnr = fn / tot;
        result.tp = tp;
        result.fp = fp;
        result.tn = tn;
        result.fn = fn;
        result.groundtruth = tp + fn;
        
        results = [results; result];
        
    end
    
    tpr = 0; fpr = 0; tnr = 0; fnr = 0; tot_images_prediction = 0; tot_images_validation = 0;
    for i = 1:size(results, 1)
        
        tpr = tpr + results(i).tpr;
        fpr = fpr + results(i).fpr;
        tnr = tnr + results(i).tnr;
        fnr = fnr + results(i).fnr;
        tot_images_prediction = tot_images_prediction + results(i).tp;
        tot_images_validation = tot_images_validation + results(i).groundtruth;
        
    end
    
    tpr = tpr / size(identities, 1);
    fpr = fpr / size(identities, 1);
    tnr = tnr / size(identities, 1);
    fnr = fnr / size(identities, 1);
    tot_images_prediction = tot_images_prediction / size(identities, 1);
    tot_images_validation = tot_images_validation / size(identities, 1);
    
    fprintf('\n- True positive rate: %.2f\n', tpr);
    fprintf('- False positive rate: %.2f\n', fpr);
    fprintf('- True negative rate: %.2f\n', tnr);
    fprintf('- False negative rate: %.2f\n', fnr);
    
    fprintf('\n- Correctly predicted: %.2f\n', tpr + tnr);
    fprintf('- Not correctly predicted: %.2f\n', fpr + fnr);
    
    fprintf('\n- Average number of images per identity after PREDICTION: %d\n', round(tot_images_prediction));
    fprintf('- Average number of images per identity after VALIDATION: %d\n', round(tot_images_validation));

end