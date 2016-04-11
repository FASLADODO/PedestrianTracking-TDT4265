
clc;
%clear all;

global c; c = get_constants();

%% Setup

TRAINING_CATEGORY       = 0;
TRAINING_IMAGE_WIDTH    = 40;
TRAINING_IMAGE_HEIGHT   = 40;
TRAINING_IMAGE_FOLDER   = 'training_examples/';

training_timesteps      = [140:160];

VIDEO_FILE_NAME  = ['ewap_dataset/' c.TRACKING_SEQUENCE '/' c.TRACKING_SEQUENCE '.avi'];
videoReader = VideoReader(VIDEO_FILE_NAME);

%% Find out how many previously added images there are and begin to count from there

base_example_number = 0;
directory = dir(TRAINING_IMAGE_FOLDER);

for i = 1:length(directory)
    
    filename = directory(i).name;
    
    if (strcmp(filename(1), num2str(TRAINING_CATEGORY)))
       
        example_number = filename(3:(end - 4));
        example_number = str2num(example_number);
        
        if (example_number > base_example_number)
            base_example_number = example_number;
        end
    end
end

%% Gather data

for i = 1:length(training_timesteps)
    
    timestep = training_timesteps(i);
    
    videoReader.CurrentTime = timestep;
    
    frame = readFrame(videoReader);
    frame = rgb2gray(frame);

    % Let user pick a point on the image
    
    imshow(frame);
    
    while (true)
        
        [x,y] = ginput(1);

        r_x         = x - (TRAINING_IMAGE_WIDTH  / 2);
        r_y         = y - (TRAINING_IMAGE_HEIGHT / 2);
        r_width     = TRAINING_IMAGE_WIDTH - 1;
        r_height    = TRAINING_IMAGE_HEIGHT - 1;

        % Extract training image

        training_image = imcrop(frame, [r_x, r_y, r_width, r_height]);

        % Ensure that all training images are of correct size
        % This is needed because all HOG feature vector must be of same
        % size
        
        [training_image_height, training_image_width] = size(training_image);
        
        if (training_image_height == TRAINING_IMAGE_HEIGHT && training_image_width == TRAINING_IMAGE_WIDTH)
            break;
        end
    end
    
    % Write training image, file name
    % [(TRAINING_CATEGORY)_(EXAMPLE_NUMBER)].png
    
    imwrite(training_image, [TRAINING_IMAGE_FOLDER num2str(TRAINING_CATEGORY) '_' num2str(base_example_number + i) '.png']);
end
