function c = get_constants()

    c = struct();
    
    %% General settings
    
    c.TRACKING_SEQUENCE = 'seq_hotel';
    c.TRACKING_SEQUENCE = 'seq_eth';

    c.TRACKING_START = 30;
    c.TRACKING_DURATION = 5;
    
    % Plots
    
    c.DISPLAY_DIFFERENCE_IMAGE          = false;
    c.DISPLAY_MEASUREMENTS              = true;
    c.DISPLAY_PEDESTRIAN_RECTANGLES     = true;
    c.DISPLAY_ONLY_ACTIVE_PEDESTRIANS   = false;
    
    %% Detection
    
    % Training
    
    c.TRAINING_IMAGE_FOLDER             = ['training_examples_' c.TRACKING_SEQUENCE '/'];
    c.TRAINING_IMAGE_WIDTH              = 40;
    c.TRAINING_IMAGE_HEIGHT             = 40;
    
    c.TRAINING_CATEGORY                 = 0;
    c.TRAINING_TIMESTEPS                = 140:160;
    
    % Difference image
    
    c.DIFFERENCE_IMAGE_THRESHOLD        = 0.1;
    c.COMPONENT_AREA_THRESHOLD          = 10;
    
    % Classifiers
    
    c.BLOCK_STEP_SIZE                   = 5;
    
    c.MEASUREMENT_LABEL_UNKNOWN         = 10;
    c.MEASUREMENT_LABEL_PEDESTRIAN      = 11;
    c.MEASUREMENT_LABEL_CLUTTER         = 12;
    
    %% Tracking

    % Core
    
    c.INITIALIZATION                    = 'initialization';
    c.ACTIVE                            = 'active';
    
    c.PEDESTRIAN_INTIALIZATION_COLOR    = 'c';
    c.PEDESTRIAN_ACTIVE_COLOR           = 'b';
    
    c.PEDESTRIAN_WIDTH                  = 30;
    c.PEDESTRIAN_HEIGHT                 = 30;
    c.MEASUREMENT_HISTORY_SIZE          = 10;
    c.EXIT_INITIALIZATION_THRESHOLD     = 6;
    c.INACTIVE_THRESHOLD                = 0;
end

