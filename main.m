
clc;
%clear all;

warning off;

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

pedestrian_detector = PedestrianDetector();
pedestrian_tracker = PedestrianTracker();

%------------------------------------------------

while (hasFrame(videoReader) && (videoReader.CurrentTime < c.TRACKING_START + c.TRACKING_DURATION))

    % Collect data
    
    current_frame = readFrame(videoReader);
    current_frame = rgb2gray(current_frame);
    
    current_frame = pedestrian_detector.adjust_contrast(current_frame);
   
    % Detect pedestrians
   
    position_measurements = pedestrian_detector.difference_image_detection(current_frame);
    position_measurements = pedestrian_detector.kNN_detection(current_frame);
    
    % Predict position and velocity of pedestrians
    
    pedestrian_tracker.kalman_prediction();
    
    % Register sensor readings
    
    pedestrian_tracker.inititalize_measurement_series();
    
    for m = 1:size(position_measurements, 2)
        pedestrian_tracker.distribute_position_measurement(position_measurements(:, m));
    end
    
    % Update pedestrian position and velocity based on sensor measurements
    
    pedestrian_tracker.kalman_update();
    
    % Update general tracking properties
    
    pedestrian_tracker.update_position_histories();
    pedestrian_tracker.update_state();
    pedestrian_tracker.remove_inactive_pedestrians();
    pedestrian_tracker.increment_time();
    
    % Display tracking results
    
    if (~ishandle(figureHandle))
        break;
    end
    
    if (c.DISPLAY_DIFFERENCE_IMAGE)
        imshow(differenceImage);
    else
        imshow(current_frame);
    end
    
    hold on;
    
    if (c.DISPLAY_MARKERS)
        for i = 1:size(position_measurements, 2)
            plot(position_measurements(1, i), position_measurements(2, i), 'rx');
        end
    end
    
    if (c.DISPLAY_PEDESTRIAN_RECTANGLES)
        pedestrian_tracker.plot_bounding_boxes();
        pedestrian_tracker.plot_position_histories();
    end
   
    hold off;
    pause(0.05);
end