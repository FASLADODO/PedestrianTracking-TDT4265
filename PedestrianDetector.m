classdef PedestrianDetector < handle
 
    properties (Access = private)
        
       previous_frame;
       current_frame;
       
       has_previous_frame;
    end
    
    methods
        
        %% Constructor
        
        function obj = PedestrianDetector()
            
            obj.previous_frame = [];
            obj.current_frame = [];
            
            obj.has_previous_frame = false;
        end
        
        %% Misc
        
        function [label, score] = HOG_predictor(obj, classifier, image)
            
            HOG_features = extractHOGFeatures(image);
            [label, score] = predict(classifier, HOG_features);
        end
        
        %% Contrast enhancement
        
        function current_frame = pre_processing(obj, current_frame)
            
            H = fspecial('gaussian', 20);
            
            current_frame = histeq(current_frame);
            current_frame = imfilter(current_frame, H, 'replicate');
        end
        
        %% Classifier training example generation
        
        function classifier_training_example_generation(obj)
            
            c = get_constants();
            
            % Setup
            
            VIDEO_FILE_NAME  = ['ewap_dataset/' c.TRACKING_SEQUENCE '/' c.TRACKING_SEQUENCE '.avi'];
            videoReader = VideoReader(VIDEO_FILE_NAME);
            
            % Find out how many previously added images there are and begin to count from there

            base_example_number = 0;
            directory = dir(c.TRAINING_IMAGE_FOLDER);

            for i = 1:length(directory)

                filename = directory(i).name;

                if (strcmp(filename(1), num2str(c.TRAINING_CATEGORY)))

                    example_number = filename(3:(end - 4));
                    example_number = str2num(example_number);

                    if (example_number > base_example_number)
                        base_example_number = example_number;
                    end
                end
            end

            % Gather data

            for i = 1:length(c.TRAINING_TIMESTEPS)
    
                timestep = c.TRAINING_TIMESTEPS(i);

                videoReader.CurrentTime = timestep;

                frame = readFrame(videoReader);
                frame = rgb2gray(frame);

                % Let user pick a point on the image

                imshow(frame);

                while (true)

                    [x,y] = ginput(1);

                    r_x         = x - (c.TRAINING_IMAGE_WIDTH  / 2);
                    r_y         = y - (c.TRAINING_IMAGE_HEIGHT / 2);
                    r_width     = c.TRAINING_IMAGE_WIDTH - 1;
                    r_height    = c.TRAINING_IMAGE_HEIGHT - 1;

                    % Extract training image

                    training_image = imcrop(frame, [r_x, r_y, r_width, r_height]);

                    % Ensure that all training images are of correct size
                    % This is needed because all HOG feature vector must be of same
                    % size

                    [training_image_height, training_image_width] = size(training_image);

                    if (training_image_height == c.TRAINING_IMAGE_HEIGHT && training_image_width == c.TRAINING_IMAGE_WIDTH)
                        break;
                    end
                end

                % Write training image, file name
                % [(TRAINING_CATEGORY)_(EXAMPLE_NUMBER)].png

                imwrite(training_image, [c.TRAINING_IMAGE_FOLDER num2str(c.TRAINING_CATEGORY) '_' num2str(base_example_number + i) '.png']);
            end
        end
        
        %% Classifier training
        
        function classifier_training(obj)
            
            c = get_constants();
            
            % Setup training matrices

            directory = dir(c.TRAINING_IMAGE_FOLDER);
            number_of_training_images = length(directory(not([directory.isdir])));
            
            if (number_of_training_images <= 0)
                disp('No training data was found.');
                return;
            end

            X = nan(number_of_training_images, 576);
            Y = nan(number_of_training_images, 1);
            
            % Gather training data

            training_image_i = 1;

            for training_category = 0:1

                category_image_i = 1;

                while (true)

                    % If the current exists extract HOG feature descriptor
                    % and add to training matrix
                    
                    filename = [c.TRAINING_IMAGE_FOLDER num2str(training_category) '_' num2str(category_image_i) '.png'];

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

            % Train classifiers and store them

            kNN_classifier = fitcknn(X, Y, 'NumNeighbors', 5);
            SVM_classifier = fitcsvm(X, Y, 'KernelFunction', 'rbf', 'Standardize', true, 'ClassNames', {'0','1'});

            save(['kNN_classifier_' c.TRACKING_SEQUENCE '.mat'], 'kNN_classifier');
            save(['SVM_classifier_' c.TRACKING_SEQUENCE '.mat'], 'SVM_classifier');
        end
        
        %% kNN classifier detection
        
        function kNN_classifier = load_kNN_classifier(obj)
            
            global c;
            
            kNN_classifier = load(['kNN_classifier_' c.TRACKING_SEQUENCE '.mat']);
            kNN_classifier = kNN_classifier.kNN_classifier;
        end
        
        function position_measurements = kNN_detection(obj, current_frame)
        
            global c;
            
            kNN_classifier = obj.load_kNN_classifier();

            [image_height, image_width] = size(current_frame);
            
            % Sliding windows detection using classifier

            detection_points = zeros(image_height, image_width);

            for i = 1:c.BLOCK_STEP_SIZE:(image_width - c.TRAINING_IMAGE_WIDTH - c.BLOCK_STEP_SIZE)
                for j = 1:c.BLOCK_STEP_SIZE:(image_height - c.TRAINING_IMAGE_HEIGHT - c.BLOCK_STEP_SIZE)

                    block = current_frame(j:(j + c.TRAINING_IMAGE_HEIGHT), i:(i + c.TRAINING_IMAGE_WIDTH));
                    [label, score] = obj.HOG_predictor(kNN_classifier, block);

                    if (label == 1 && score(2) >= 1)
                        detection_points(j, i) = 1;
                    end
                end
            end

            % Convert to position measurements adjusted for rectangle detection window

            position_measurements   = zeros(2, sum(sum(detection_points)));
            position_measurements_i = 1;

            for i = 1:size(detection_points, 2)
                for j = 1:size(detection_points, 1)

                    if (detection_points(j, i) == 1)

                        position_measurements(:, position_measurements_i) = [(i + (c.TRAINING_IMAGE_WIDTH / 2)); (j + (c.TRAINING_IMAGE_HEIGHT / 2))];
                        position_measurements_i = position_measurements_i + 1;
                    end
                end
            end
        end
        
        function position_measurement_labels = label_position_measurements_with_kNN(obj, current_frame, position_measurements)
            
            global c;
            
            % Use pretrained kNN classifier
            
            kNN_classifier = obj.load_kNN_classifier();
            
            % Assume unknown measurement
    
            position_measurement_labels = c.MEASUREMENT_LABEL_UNKNOWN * ones(size(position_measurements, 2), 1);

            % Crop out image around each measurement and check against kNN
            % classifier
            
            for i = 1:size(position_measurements, 2)

                x = position_measurements(1, i);
                y = position_measurements(2, i);

                r_x         = x - (c.TRAINING_IMAGE_WIDTH  / 2);
                r_y         = y - (c.TRAINING_IMAGE_HEIGHT / 2);
                r_width     = c.TRAINING_IMAGE_WIDTH - 1;
                r_height    = c.TRAINING_IMAGE_HEIGHT - 1;

                % Extract training image

                block = imcrop(current_frame, [r_x, r_y, r_width, r_height]);

                [block_height, block_width] = size(block);

                % If image is not big enough, i.e. on the edge or something
                % just do not care
                
                if (block_height ~= c.TRAINING_IMAGE_HEIGHT || block_width ~= c.TRAINING_IMAGE_HEIGHT)
                    continue;
                end

                % Determine type of image

                [label, score] = obj.HOG_predictor(kNN_classifier, block);

                pedestrian_score = score(2);
                clutter_score    = score(1);
                
                if (pedestrian_score >= 0.2)
                    position_measurement_labels(i) = c.MEASUREMENT_LABEL_PEDESTRIAN;
                elseif (clutter_score >= 0.2)
                    position_measurement_labels(i) = c.MEASUREMENT_LABEL_CLUTTER;
                end
            end
        end
        
        %% Difference image detection
        
        function [position_measurements, difference_image] = difference_image_detection(obj, current_frame)
           
            global c;
            
            obj.previous_frame = obj.current_frame;
            obj.current_frame = current_frame;
            
            % Make sure something is buffered when doing difference image
            
            if (~obj.has_previous_frame)
                
                obj.has_previous_frame = true;
                position_measurements = [];
                difference_image = [];
                
                return;
            end
            
            % Compute difference image
            
            difference_image = imabsdiff(obj.current_frame, obj.previous_frame);
        
            structuring_element = strel('disk', 4);

            difference_image = im2bw(difference_image, c.DIFFERENCE_IMAGE_THRESHOLD);
            difference_image = imclose(difference_image, structuring_element);
            
            % Get measurements from connected components
            
            proposed_position_measurement = regionprops(difference_image);
            position_measurements = [];

            for i = 1:length(proposed_position_measurement)

                if (proposed_position_measurement(i).Area > c.COMPONENT_AREA_THRESHOLD)
                    position_measurements(1:2, size(position_measurements, 2) + 1) = proposed_position_measurement(i).Centroid;
                end
            end
        end
    end
end

