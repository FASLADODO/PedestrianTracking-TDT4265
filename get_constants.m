function c = get_constants()

    c = struct();
    
    %% General input and output settings
    
    % Tracking source and results
    
    c.TRACKING_SEQUENCE                 = 'seq_hotel';
    c.TRACKING_SEQUENCE                 = 'seq_eth';

    c.TRACKING_START                    = 30;
    c.TRACKING_DURATION                 = 5;
    
    c.TRACKING_VIDEO_FILENAME           = fullfile('ewap_dataset', c.TRACKING_SEQUENCE, [c.TRACKING_SEQUENCE '.avi']);
    c.TRACKING_RESULT_VIDEO_FILENAME    = 'results/tracking_result_asd.avi';

    c.STORE_TRACKING_RESULT             = false;
    c.RESULTS_FRAME_RATE_REDUCTION      = 4;
    c.INFORMATION_TEXT                  = {'Pedestrian', 'tracker'};
    c.INFROMATION_TEXT_POSITION         = 'southwest';
    
    % Plots
    
    c.DISPLAY_DIFFERENCE_IMAGE          = false;
    c.DISPLAY_MEASUREMENTS              = true;
    c.DISPLAY_PEDESTRIAN_RECTANGLES     = true;
    c.DISPLAY_ONLY_ACTIVE_PEDESTRIANS   = true;
    c.DISPLAY_TRACK_CONFIDENCE          = true;
    c.DISPLAY_INFORMATION_TEXT          = true;

    % Merging

    c.MERGE_VIDEO_FILENAME_INPUT_1      = 'results/tracking_result_test.avi';
    c.MERGE_VIDEO_FILENAME_INPUT_2      = 'results/tracking_result_test.avi';
    c.MERGE_VIDEO_FILENAME_OUTPUT       = 'results/merge_test.avi';
    
    %% Detection
    
    % Training
    
    c.TRAINING_IMAGE_FOLDER             = ['training_examples_' c.TRACKING_SEQUENCE];
    c.TRAINING_IMAGE_WIDTH              = 40;
    c.TRAINING_IMAGE_HEIGHT             = 40;
    
    c.TRAINING_CATEGORY                 = 0;
    c.TRAINING_TIMESTEPS                = linspace(35, 36, 20);
    
    c.NEAREST_NEIGHBOUR_K               = 5;
    
    % Difference image
    
    c.DIFFERENCE_IMAGE_THRESHOLD        = 0.1;
    c.DIFFERENCE_IMAGE_AREA_THRESHOLD   = 10;
    c.DIFFERENCE_IMAGE_DISK_RADIUS      = 3;
    
    % Classifiers
    
    c.BLOCK_STEP_SIZE                   = 5;
    
    c.MEASUREMENT_LABEL_UNKNOWN         = 10;
    c.MEASUREMENT_LABEL_PEDESTRIAN      = 11;
    c.MEASUREMENT_LABEL_CLUTTER         = 12;
    
    c.DISABLE_CLASSIFIER_FILTER         = false;
    
    if (strcmp(c.TRACKING_SEQUENCE, 'seq_eth'))
        c.CLASSIFIER_FILTER_OFFSET_STEP = 3;
    else
        c.CLASSIFIER_FILTER_OFFSET_STEP = 5;
    end
    
    %% Tracking

    % Core
    
    c.INITIALIZATION                    = 'initialization';
    c.ACTIVE                            = 'active';
    
    c.PEDESTRIAN_INTIALIZATION_COLOR    = 'c';
    c.PEDESTRIAN_ACTIVE_COLOR           = 'b';
    
    if (strcmp(c.TRACKING_SEQUENCE, 'seq_eth'))
        c.PEDESTRIAN_WIDTH              = 20;
        c.PEDESTRIAN_HEIGHT             = 20;
    else
        c.PEDESTRIAN_WIDTH              = 60;
        c.PEDESTRIAN_HEIGHT             = 60;
    end
    
    c.MEASUREMENT_HISTORY_SIZE          = 10;
    c.EXIT_INITIALIZATION_THRESHOLD     = 6;
    c.INACTIVE_THRESHOLD                = 0;
    c.PEDESTRIAN_FILTER_THRESHOLD       = 0.2;
    
    c.MEAN                              = 1;
    c.CLOSEST_TO_PREDICTION             = 2;
    c.KALMAN_UPDATE_MEASUREMENT         = c.MEAN;
    
    c.COST_AGE_WEIGHT                   = 0.5;
    c.COST_AGE_SATURATION               = 20;
end

