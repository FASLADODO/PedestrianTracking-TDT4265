
clc;
%clear all;

global c; c = get_constants();

%------------------------------------------------
% Video and display setup

VIDEO_FILE                  = ['ewap_dataset/' c.TRACKING_SEQUENCE '/' c.TRACKING_SEQUENCE '.avi'];

videoReader = VideoReader(VIDEO_FILE);
videoReader.CurrentTime = c.TRACKING_START;

hasReadFirstFrame = false;
previousFrameGray = [];

figureHandle = figure(1);

%------------------------------------------------
% Tracker setup

pedestrians = PedestrianContainer();

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
    
    pedestrians.kalman_prediction();
    
    % Register sensor readings
    
    pedestrians.inititalize_measurement_series(timestep);
    
    for m = 1:size(position_measurements, 2)
        pedestrians.distribute_position_measurement(position_measurements(:, m), timestep);
    end
    
    % Update pedestrian position and velocity based on sensor measurements
    
    pedestrians.kalman_update();
    pedestrians.update_position_histories();
    
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