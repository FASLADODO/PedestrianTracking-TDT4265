
clc;
warning off;

global c; c = get_constants();

%% Setup

video_reader = Video_reader_wrapper(c.TRACKING_VIDEO_FILENAME);
video_reader.set_current_time(c.TRACKING_START);

video_writer = Video_writer_wrapper(c.TRACKING_RESULT_VIDEO_FILENAME, ~c.STORE_TRACKING_RESULT, video_reader.get_frame_rate() / c.RESULTS_FRAME_RATE_REDUCTION);

pedestrian_detector = Pedestrian_detector();
pedestrian_tracker = Pedestrian_tracker();

%% Tracking loop

while (video_reader.should_proceed_with_tracking())

    % Collect data
    
    current_frame = video_reader.read_gray_frame();
    current_frame = pedestrian_detector.pre_processing(current_frame);
   
    % Detect pedestrians
   
    [position_measurements, difference_image]               = pedestrian_detector.difference_image_detection(current_frame);
    [position_measurements, position_measurement_labels]    = pedestrian_detector.filter_measurements_with_kNN(current_frame, position_measurements);
    
    % Predict position and velocity of pedestrians
    
    pedestrian_tracker.kalman_prediction();
    
    % Register sensor readings with tracker
    
    pedestrian_tracker.inititalize_measurement_series();
    
    valid_position_measurements         = position_measurements(:, position_measurement_labels ~= c.MEASUREMENT_LABEL_CLUTTER);
    valid_position_measurement_labels   = position_measurement_labels(position_measurement_labels ~= c.MEASUREMENT_LABEL_CLUTTER);
    
    for m = 1:size(valid_position_measurements, 2)
        
        position_measurement        = valid_position_measurements(:, m);
        position_measurement_label  = valid_position_measurement_labels(m);
        
        pedestrian_tracker.distribute_position_measurement(position_measurement, position_measurement_label);
    end
    
    % Update pedestrian position and velocity based on sensor measurements
    
    pedestrian_tracker.kalman_update();
    
    % Update general tracking properties
    
    pedestrian_tracker.update_position_histories();
    pedestrian_tracker.update_state();
    pedestrian_tracker.remove_inactive_pedestrians();
    pedestrian_tracker.increment_time();
    
    % Display tracking results
    
    has_closed_figure = pedestrian_tracker.plot(video_reader.get_current_time(), current_frame, difference_image, position_measurements, position_measurement_labels);
    
    if (has_closed_figure)
        break;
    end
    
    % Save output video
    
    video_writer.write_frame();
    
    pause(0.05);
end

video_writer.close();
