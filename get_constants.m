function c = get_constants()

    c = struct();
    
    % --------------------------------------
    
    c.TRACKING_SEQUENCE = 'seq_hotel';
    c.TRACKING_SEQUENCE = 'seq_eth';

    c.TRACKING_START = 30;
    c.TRACKING_DURATION = 3;
    
    % -----------------------------------------------------------
    
    c.DISPLAY_DIFFERENCE_IMAGE          = true;
    c.DISPLAY_MARKERS                   = true;
    c.DISPLAY_PEDESTRIAN_RECTANGLES     = true;
    
    % -----------------------------------------------------------

    c.DIFFERENCE_IMAGE_THRESHOLD        = 0.1;
    c.COMPONENT_AREA_THRESHOLD          = 10;
    
    % -----------------------------------------------------------

    c.INITIALIZATION                    = 'initialization';
    c.ACTIVE                            = 'active';
    
    c.PEDESTRIAN_WIDTH                  = 20;
    c.PEDESTRIAN_HEIGHT                 = 40;
    c.MEASUREMENT_HISTORY_SIZE          = 5;
    c.EXIT_INITIALIZATION_THRESHOLD     = 3;
    
    c.PEDESTRIAN_INTIALIZATION_COLOR    = 'c';
    c.PEDESTRIAN_ACTIVE_COLOR           = 'b';
end

