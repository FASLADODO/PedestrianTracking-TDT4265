classdef Pedestrian_detector < handle
 
    properties (Access = private)
        
       previous_frame;
       current_frame;
       
       has_previous_frame;
    end
    
    methods
        
        %% Constructor
        
        function obj = Pedestrian_detector()
            
            obj.previous_frame = [];
            obj.current_frame = [];
            
            obj.has_previous_frame = false;
        end
        
        %% Misc
        
        function [label, score] = HOG_predictor(obj, classifier, image)
            
            HOG_features = extractHOGFeatures(image);
            [label, score] = predict(classifier, HOG_features);
        end
        
        %% Pre processing
        
        function current_frame = pre_processing(obj, current_frame)
            
            H = fspecial('gaussian', 20);
            
            current_frame = histeq(current_frame);
            current_frame = imfilter(current_frame, H, 'replicate');
        end
        
        %% Classifier training example generation
        
        function classifier_training_example_generation(obj)
            
            global c;
            
            % Setup
            
            video_reader = Video_reader_wrapper(c.TRACKING_VIDEO_FILENAME);
            
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
                
                video_reader.set_current_time(timestep);

                frame = video_reader.read_gray_frame();
                
                % Use same pre processing as when doing tracking
                    
                frame = obj.pre_processing(frame);

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

                imwrite(training_image, fullfile(c.TRAINING_IMAGE_FOLDER, [num2str(c.TRAINING_CATEGORY) '_' num2str(base_example_number + i) '.png']));
            end
        end

        %% Training example folder feature matrix X and label vector Y

        function [X, Y, number_of_training_images] = get_training_folder_features_and_labels(obj)

            global c;

            % Setup training matrices

            directory = dir(c.TRAINING_IMAGE_FOLDER);
            number_of_training_images = length(directory(not([directory.isdir])));

            if (number_of_training_images <= 0)
                
                X = [];
                Y = [];

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
                    
                    filename = fullfile(c.TRAINING_IMAGE_FOLDER, [num2str(training_category) '_' num2str(category_image_i) '.png']);

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
        end
        
        %% Classifier training
        
        function classifier_training(obj)
            
            global c;
            
            % Gather training data

            [X, Y, number_of_training_images] = obj.get_training_folder_features_and_labels();

            if (number_of_training_images <= 0)
                disp('No training data was found.');
                return;
            end

            % Train classifiers and store them

            kNN_classifier = fitcknn(X, Y, 'NumNeighbors', c.NEAREST_NEIGHBOUR_K);
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
        
        % Detection
        
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
        
        % Offset matrix generation
        
        function [offsets, n_offsets] = get_cross_offsets(obj)
                
            global c;
            
            s = c.CLASSIFIER_FILTER_OFFSET_STEP;
            
            offsets = [ 0   -s    -s    s     s;
                        0   -s    s     -s    s];
                    
            n_offsets = size(offsets, 2);
        end
        
        function [offsets, n_offsets] = get_square_offsets(obj)
            
            global c;
            
            s = c.CLASSIFIER_FILTER_OFFSET_STEP;
            
            [offsets_x, offsets_y] = meshgrid(-s:s:s, -s:s:s);
            offsets = [offsets_x(:)'; offsets_y(:)'];
            
            n_offsets = size(offsets, 2);
        end
        
        % Filtering
            
        function [position_measurements, position_measurement_labels] = filter_measurements_with_kNN(obj, current_frame, position_measurements)
            
            global c;
            
            % Option of not using filter
            
            if (c.DISABLE_CLASSIFIER_FILTER)
                position_measurement_labels = c.MEASUREMENT_LABEL_UNKNOWN * ones(size(position_measurements, 2), 1);
                return;
            end
            
            % Use pretrained kNN classifier
            
            kNN_classifier = obj.load_kNN_classifier();
            
            % Assume unknown measurement
    
            position_measurement_labels = c.MEASUREMENT_LABEL_UNKNOWN * ones(size(position_measurements, 2), 1);

            [offsets, n_offsets] = obj.get_cross_offsets();
                    
            % Crop out image around each measurement and check against kNN
            % classifier
            
            for i = 1:size(position_measurements, 2)

                x = position_measurements(1, i);
                y = position_measurements(2, i);

                r_x         = x - (c.TRAINING_IMAGE_WIDTH  / 2);
                r_y         = y - (c.TRAINING_IMAGE_HEIGHT / 2);
                r_width     = c.TRAINING_IMAGE_WIDTH - 1;
                r_height    = c.TRAINING_IMAGE_HEIGHT - 1;

                % Scan around measurement to find best match for pedestrian
                
                pedestrian_scores = nan(n_offsets, 1);
                
                for j = 1:n_offsets
                    
                    % Extract shifted image
                    
                    offset = offsets(:, j);
                    
                    block = imcrop(current_frame, [r_x + offset(1), r_y + offset(2), r_width, r_height]);

                    % If image is not big enough, i.e. on the edge or something
                    % just do not care
                    
                    [block_height, block_width] = size(block);

                    if (block_height ~= c.TRAINING_IMAGE_HEIGHT || block_width ~= c.TRAINING_IMAGE_HEIGHT)
                        continue;
                    end

                    % Determine if this looks more like a pedestrian than
                    % previously best

                    [label, score] = obj.HOG_predictor(kNN_classifier, block);
                    pedestrian_scores(j) = score(2);
                end

                % No valid scores were found
                
                if (isnan(pedestrian_scores))
                    continue;
                end
                
                % Evaluate type of measurement
                
                max_pedestrian_score = max(pedestrian_scores);
                
                if (max_pedestrian_score >= c.PEDESTRIAN_FILTER_THRESHOLD)
                    
                    % Create new measurement for all of the detections that
                    % were max. I.e. if one single measurement were from
                    % two one might expect it to detect someone clearly on
                    % either side.
                    
                    offset_indices = find(pedestrian_scores == max_pedestrian_score);
                    
                    % Modify original measurement
                    
                    position_measurement_labels(i) = c.MEASUREMENT_LABEL_PEDESTRIAN;
                    position_measurements(:, i) = position_measurements(:, i) + offsets(:, offset_indices(1));
                    
                    % Add the newly created ones if there were any
                    
                    for z = 2:length(offset_indices)
                        
                        index = length(position_measurement_labels) + 1;
                        
                        position_measurement_labels(index) = c.MEASUREMENT_LABEL_PEDESTRIAN;
                        position_measurements(:, index) = position_measurements(:, i) + offsets(:, offset_indices(z));
                    end
                    
                elseif (max_pedestrian_score >= 0)
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
                difference_image = zeros(size(obj.current_frame));
                
                return;
            end
            
            % Compute difference image
            
            difference_image = imabsdiff(obj.current_frame, obj.previous_frame);
        
            structuring_element = strel('disk', c.DIFFERENCE_IMAGE_DISK_RADIUS);

            difference_image = im2bw(difference_image, c.DIFFERENCE_IMAGE_THRESHOLD);
            difference_image = imclose(difference_image, structuring_element);
            
            % Get measurements from connected components
            
            proposed_position_measurement = regionprops(difference_image);
            position_measurements = [];

            for i = 1:length(proposed_position_measurement)

                if (proposed_position_measurement(i).Area > c.DIFFERENCE_IMAGE_AREA_THRESHOLD)
                    position_measurements(1:2, size(position_measurements, 2) + 1) = proposed_position_measurement(i).Centroid;
                end
            end
        end
    end
end

