
%clc;
%clear all;

%------------------------------------------------
% Video and display setup

global c; c = struct();

c.TRACKING_SEQUENCE = 'seq_hotel';
c.TRACKING_SEQUENCE = 'seq_eth';

c.TRACKING_START = 30;
c.TRACKING_DURATION = 3;

VIDEO_FILE                  = ['ewap_dataset/' c.TRACKING_SEQUENCE '/' c.TRACKING_SEQUENCE '.avi'];

videoReader = VideoReader(VIDEO_FILE);
videoReader.CurrentTime = c.TRACKING_START;

hasReadFirstFrame = false;
previousFrameGray = [];

figureHandle = figure(1);

c.DISPLAY_DIFFERENCE_IMAGE      = true;
c.DISPLAY_MARKERS               = true;
c.DISPLAY_PEDESTRIAN_RECTANGLES = true;

%------------------------------------------------
% Detection setup

c.DIFFERENCE_IMAGE_THRESHOLD  = 0.1;
c.COMPONENT_AREA_THRESHOLD    = 10;

c.PEDESTRIAN_WIDTH  = 20;
c.PEDESTRIAN_HEIGHT = 40;

c.MEASUREMENT_HISTORY_SIZE = 5;

pedestrians = PedestrianContainer();
pedestrian_motion_model = PedestrianMotionModel();

%------------------------------------------------

timestep = 0;

while (hasFrame(videoReader) && (videoReader.CurrentTime < c.TRACKING_START + c.TRACKING_DURATION))

    % Collect data
    
    currentFrame = readFrame(videoReader);
    currentFrame = rgb2gray(currentFrame);
    
    if (~hasReadFirstFrame)
        previousFrame = currentFrame;
        hasReadFirstFrame = true;
        
        continue;
    end
    
    % Compute difference image
    
    differenceImage = imabsdiff(currentFrame, previousFrame);
    previousFrame = currentFrame;
        
    structuringElement = [1 1 1 1 1 1 1 1 1]';
    structuringElement = repmat(structuringElement, 2, 2);
    
    differenceImage = im2bw(differenceImage, c.DIFFERENCE_IMAGE_THRESHOLD);
    differenceImage = imclose(differenceImage, structuringElement);
    
    % Extract connected components
    
    proposed_position_measurement = regionprops(differenceImage);
    position_measurements = [];
    
    for i = 1:length(proposed_position_measurement)
       
        if (proposed_position_measurement(i).Area > c.COMPONENT_AREA_THRESHOLD)
            position_measurements(1:2, size(position_measurements, 2) + 1) = proposed_position_measurement(i).Centroid;
        end
    end
    
    % Predict position and velocity of pedestrians
    
    pedestrians.kalman_prediction(pedestrian_motion_model);
    
    % Register sensor readings
    
    pedestrians.inititalize_measurement_series(timestep);
    
    for m = 1:size(position_measurements, 2)
        pedestrians.distribute_position_measurement(position_measurements(:, m), timestep);
    end
    
    % Update pedestrian position and velocity based on sensor measurements
    
    pedestrians.kalman_update(pedestrian_motion_model);
    
    timestep = timestep + 1;
    
    % Display tracking results
    
    if (~ishandle(figureHandle))
        break;
    end
    
    if (c.DISPLAY_DIFFERENCE_IMAGE)
        imshow(differenceImage);
    else
        imshow(currentFrame);
    end
    
    hold on;
    
    if (c.DISPLAY_MARKERS)
        for i = 1:size(position_measurements, 2)
            plot(position_measurements(1, i), position_measurements(2, i), 'rx');
        end
    end
    
    if (c.DISPLAY_PEDESTRIAN_RECTANGLES)
        pedestrians.plot_bounding_boxes();
        pedestrians.plot_position_histories();
    end
   
    hold off;
    pause(0.05);
end