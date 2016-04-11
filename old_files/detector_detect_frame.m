
warning off;

%% Setup

VIDEO_FILE_NAME  = ['ewap_dataset/' c.TRACKING_SEQUENCE '/' c.TRACKING_SEQUENCE '.avi'];
videoReader = VideoReader(VIDEO_FILE_NAME);
videoReader.CurrentTime = 150;
I = readFrame(videoReader);
I = rgb2gray(I);

classifier_kNN = load('classifier_kNN.mat');
classifier_kNN = classifier_kNN.classifier_kNN;

classifier_SVM = load('classifier_SVM.mat');
classifier_SVM = classifier_SVM.classifier_SVM;

[image_height, image_width] = size(I);

TRAINING_IMAGE_WIDTH    = 40;
TRAINING_IMAGE_HEIGHT   = 40;

BLOCK_STEP_SIZE = 5;

i = 1;

% while (true)
%    
%     imshow(I);
%     [x,y] = ginput(1);
% 
%     r_x         = x - (TRAINING_IMAGE_WIDTH  / 2);
%     r_y         = y - (TRAINING_IMAGE_HEIGHT / 2);
%     r_width     = TRAINING_IMAGE_WIDTH;
%     r_height    = TRAINING_IMAGE_HEIGHT;
% 
%     % Extract training image
%     
%     training_image = imcrop(I, [r_x, r_y, r_width, r_height]);
%     imshow(training_image)
%     [label, score] = detector(classifier_kNN, training_image);
%     label
%     score
%     pause;
%     
% end

%% Sliding windows detection using classifier

detection_points = zeros(image_height, image_width);

tic
for i = 1:BLOCK_STEP_SIZE:(image_width - TRAINING_IMAGE_WIDTH - BLOCK_STEP_SIZE)
    for j = 1:BLOCK_STEP_SIZE:(image_height - TRAINING_IMAGE_HEIGHT - BLOCK_STEP_SIZE)
        
        block = I(j:(j + TRAINING_IMAGE_HEIGHT), i:(i + TRAINING_IMAGE_WIDTH));
        [label, score] = detector(classifier_kNN, block); 
        
        if (label == 1 && score(2) >= 1)
            detection_points(j, i) = 1;
        end
    end
end
toc

%% Convert to position measurements adjusted for rectangle detection window

position_measurements   = zeros(2, sum(sum(detection_points)));
position_measurements_i = 1;

for i = 1:size(detection_points, 2)
    for j = 1:size(detection_points, 1)
        
        if (detection_points(j, i) == 1)

            position_measurements(:, position_measurements_i) = [(i + (TRAINING_IMAGE_WIDTH / 2)); (j + (TRAINING_IMAGE_HEIGHT / 2))];
            position_measurements_i = position_measurements_i + 1;
        end
    end
end

%% Display results

imshow(I);

hold on;

for i = 1:size(position_measurements, 2)
    plot(position_measurements(1, i), position_measurements(2, i), 'rx');
end



