
clc;
clear all;

%------------------------------------------------
% Video and display setup

TRACKING_SEQUENCE = 'seq_hotel';
TRACKING_SEQUENCE = 'seq_eth';

TRACKING_START = 30;
TRACKING_DURATION = 3;

VIDEO_FILE                  = ['ewap_dataset/' TRACKING_SEQUENCE '/' TRACKING_SEQUENCE '.avi'];

videoReader = VideoReader(VIDEO_FILE);
videoReader.CurrentTime = TRACKING_START;

hasReadFirstFrame = false;
previousFrameGray = [];

figureHandle = figure(1);

DISPLAY_DIFFERENCE_IMAGE      = true;
DISPLAY_MARKERS               = true;
DISPLAY_PEDESTRIAN_RECTANGLES = true;

%------------------------------------------------
% Detection setup

DIFFERENCE_IMAGE_THRESHOLD  = 0.1;
COMPONENT_AREA_THRESHOLD    = 10;
CLOSE_DISC_RADIUS           = 3;

PEDESTRIAN_WIDTH  = 20;
PEDESTRIAN_HEIGHT = 40;

%------------------------------------------------
% ROI setup

REGION_WIDTH  = 30;
REGION_HEIGHT = 30;

pedestrians = {};

%------------------------------------------------

time = 0;

while (hasFrame(videoReader) && (videoReader.CurrentTime < TRACKING_START + TRACKING_DURATION))

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
    
    differenceImage = im2bw(differenceImage, DIFFERENCE_IMAGE_THRESHOLD);
    differenceImage = imclose(differenceImage, structuringElement);
    
    % Extract connected components
    
    proposed_position_measurement = regionprops(differenceImage);
    position_measurements = [];
    
    for i = 1:length(proposed_position_measurement)
       
        if (proposed_position_measurement(i).Area > COMPONENT_AREA_THRESHOLD)
            position_measurements(1:2, size(position_measurements, 2) + 1) = proposed_position_measurement(i).Centroid;
        end
    end
    
    % Region of interest calculations
    
    for m = 1:size(position_measurements, 2)
        
        [pedestrian, belongs_to] = contains(position_measurements(:, m), pedestrians, PEDESTRIAN_WIDTH, PEDESTRIAN_HEIGHT);
        
        if (belongs_to)
            measurement.position = position_measurements(:, m);
            measurement.time = time + 1;
            
            pedestrian.add_measurement(measurement);
        else
            measurement.position = position_measurements(:, m);
            measurement.time = time + 1;
            
            new_pedestrian = Pedestrian(measurement);
            pedestrians{length(pedestrians) + 1} = new_pedestrian;
        end
        
    end
    
    
    
    % Display tracking results
    
    if (~ishandle(figureHandle))
        break;
    end
    
    if (DISPLAY_DIFFERENCE_IMAGE)
        imshow(differenceImage);
    else
        imshow(currentFrame);
    end
    
    hold on;
    
    if (DISPLAY_MARKERS)
        for i = 1:size(position_measurements, 2)
            plot(position_measurements(1, i), position_measurements(2, i), 'rx');
        end
    end
    
    if (DISPLAY_PEDESTRIAN_RECTANGLES)
        for i = 1:size(pedestrians, 2)
            pedestrians{i}.display(PEDESTRIAN_WIDTH, PEDESTRIAN_HEIGHT);
        end
    end
   
    time = time + 1;
    hold off;
    pause(0.05);
end