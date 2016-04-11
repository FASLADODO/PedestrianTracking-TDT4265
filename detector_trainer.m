
clc;

TRAINING_IMAGE_FOLDER = 'training_examples/';

%% Setup SVM training matrices

directory = dir(TRAINING_IMAGE_FOLDER);
number_of_training_images = length(directory(not([directory.isdir])));

X = nan(number_of_training_images, 576);
Y = nan(number_of_training_images, 1);

%% Gather training data

disp('Gathering data...');

training_image_i = 1;

for training_category = 0:1
    
    category_image_i = 1;
    
    while (true)
        
        filename = [TRAINING_IMAGE_FOLDER num2str(training_category) '_' num2str(category_image_i) '.png'];
        
        if (exist(filename, 'file'))
        
            training_image = imread(filename);
            HOG_features = extractHOGFeatures(training_image);
            
            X(training_image_i, :) = HOG_features;
            Y(training_image_i, :) = training_category;
        else
            break;
        end
        
        category_image_i = category_image_i + 1;
        training_image_i = training_image_i + 1;
    end
end

%% Train classifiers

disp('Training classifier...');

classifier_kNN = fitcknn(X, Y, 'NumNeighbors', 5);
classifier_SVM = fitcsvm(X, Y, 'KernelFunction', 'rbf', 'Standardize', true, 'ClassNames', {'0','1'});

save('classifier_kNN.mat', 'classifier_kNN');
save('classifier_SVM.mat', 'classifier_SVM');

disp('Finished');
