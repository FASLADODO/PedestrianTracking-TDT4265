classdef Pedestrian_tracker < handle
 
    properties (Access = private)
        
        timestep;
        
        pedestrians;
        pedestrian_motion_model;
        
        figure_handle;
    end
    
    methods
        
        %% Constructor
        
        function obj = Pedestrian_tracker()
            
            obj.timestep = 1;
            
            obj.pedestrians = {};
            obj.pedestrian_motion_model = Pedestrian_motion_model();
            
            obj.figure_handle = figure();
        end
        
        %% Misc

        function increment_time(obj)
            obj.timestep = obj.timestep + 1;
        end
        
        function update_state(obj)
            
            for i = 1:length(obj.pedestrians)
               obj.pedestrians{i}.update_state();
            end
        end
        
        function remove_inactive_pedestrians(obj)
           
            active_indices = [];
            
            for i = 1:length(obj.pedestrians)
                if(~obj.pedestrians{i}.is_inactive())
                    active_indices(length(active_indices) + 1) = i;
                end
            end
            
            if (length(active_indices) < length(obj.pedestrians))
                obj.pedestrians = {obj.pedestrians{active_indices}};
            end
        end
        
        function update_position_histories(obj)
            
            for i = 1:length(obj.pedestrians)
               obj.pedestrians{i}.update_position_history();
            end
        end
        
        %% Measurement handling
        
        function inititalize_measurement_series(obj)
            
            for i = 1:length(obj.pedestrians)
               obj.pedestrians{i}.initialize_measurement_series(obj.timestep);
            end
        end
        
        % Cost of connection between measurement and track
        % Weighted measure between distance and the age of the track
        % Favors tracks which are consistent
        
        function cost = measurement_connection_cost(obj, position_offset, age)
            
            global c;
            
            cost = norm(position_offset) - c.COST_AGE_WEIGHT * max(c.COST_AGE_SATURATION, age);
        end
        
        function distribute_position_measurement(obj, position_measurement, position_measurement_label)
            
            global c;
            
            % Search for connection between pedestrian and measurement
            % I.e. if the measurement falls into the box that defines the
            % the pedestrian
            
            pedestrian_connected_to_measurement = -1;
            best_pedestrian_connection_cost = Inf;
            
            for i = 1:length(obj.pedestrians)
               
                pedestrian_position = obj.pedestrians{i}.get_position();
                position_offset = position_measurement - pedestrian_position;
                
                if (abs(position_offset(1)) <= (c.PEDESTRIAN_WIDTH / 2)) && (abs(position_offset(2)) <= (c.PEDESTRIAN_HEIGHT / 2))
                    
                    % Cost of connection
                    
                    pedestrian_connection_cost = obj.measurement_connection_cost(position_offset, obj.pedestrians{i}.get_age());
                    
                    if (pedestrian_connection_cost < best_pedestrian_connection_cost)
                        
                        pedestrian_connected_to_measurement = i;
                        best_pedestrian_connection_cost = pedestrian_connection_cost;
                    end
                end
            end
            
            % Assign the measurement to the pedestrian which is predicted
            % to be closest to the measurement
            
            if (pedestrian_connected_to_measurement > 0)
                
                obj.pedestrians{pedestrian_connected_to_measurement}.add_position_measurement(position_measurement, position_measurement_label);
            
            % If no connection was found initialize a new pedestrian
            
            else
                index = length(obj.pedestrians) + 1;

                obj.pedestrians{index} = Pedestrian(position_measurement, position_measurement_label, obj.pedestrian_motion_model, obj.timestep);
            end
        end
        
        %% Plots
        
        function has_closed_figure = plot(obj, current_time, current_frame, difference_image, position_measurements, position_measurement_labels)
       
            global c;
            
            % If the user has closed the figure window, exit
            
            if (~ishandle(obj.figure_handle))
                has_closed_figure = true;
                return;
            end
            
            has_closed_figure = false;
            
            % Else show desired plots set in the c file
            
            if (c.DISPLAY_DIFFERENCE_IMAGE)
                imshow(difference_image);
            else
                imshow(current_frame);
            end

            hold on;

            if (c.DISPLAY_INFORMATION_TEXT)
                obj.plot_information_text(current_frame, current_time);
            end

            if (c.DISPLAY_MEASUREMENTS)
                
                if (nargin >= 5)
                    obj.plot_position_measurements_with_labels(position_measurements, position_measurement_labels);
                else
                    obj.plot_position_measurements(position_measurements);
                end
            end

            if (c.DISPLAY_PEDESTRIAN_RECTANGLES)
                obj.plot_bounding_boxes();
                obj.plot_position_histories();
            end
            
            hold off;
        end

        % Information text

        function plot_information_text(obj, current_frame, current_time)

            global c;

            [frame_height, frame_width] = size(current_frame);

            if (strcmp(c.INFROMATION_TEXT_POSITION, 'southwest'))

                horizontal_alignment = 'left';
                horizontal_position  = 20;
                vertical_alignment   = 'bottom';
                vertical_position    = frame_height - 20;

            else % southeast

                horizontal_alignment = 'right';
                horizontal_position  = frame_width - 20;
                vertical_alignment   = 'bottom';
                vertical_position    = frame_height - 20;
            end

            time_handle = text(horizontal_position, vertical_position, num2str(current_time), 'Color', 'r', 'FontSize', 18);
            time_handle.HorizontalAlignment = horizontal_alignment;
            time_handle.VerticalAlignment   = vertical_alignment;

            text_handle = text(horizontal_position, vertical_position - 30, c.INFORMATION_TEXT, 'Color', 'r', 'FontSize', 18);
            text_handle.HorizontalAlignment = horizontal_alignment;
            text_handle.VerticalAlignment   = vertical_alignment;
        end
        
        % Position measurements
        
        function plot_position_measurements_with_labels(obj, position_measurements, position_measurement_labels)
        
            global c;
            
            for i = 1:size(position_measurements, 2)
                
                marker_style = 'ro';
                
                if (position_measurement_labels(i) == c.MEASUREMENT_LABEL_PEDESTRIAN)
                    marker_style = 'rd';
                elseif (position_measurement_labels(i) == c.MEASUREMENT_LABEL_CLUTTER)
                    marker_style = 'rs';
                end
                
                plot(position_measurements(1, i), position_measurements(2, i), marker_style);
            end
        end
        
        function plot_position_measurements(obj, position_measurements)
        
            for i = 1:size(position_measurements, 2)
                plot(position_measurements(1, i), position_measurements(2, i), 'rx');
            end
        end
        
        % Pedestrians
        
        function plot_bounding_boxes(obj)
            
            global c;
            
            for i = 1:length(obj.pedestrians)
                
                if (~(c.DISPLAY_ONLY_ACTIVE_PEDESTRIANS && strcmp(obj.pedestrians{i}.get_state(), c.INITIALIZATION)))
                    obj.pedestrians{i}.plot_bounding_box();
                end
            end
        end
        
        function plot_position_histories(obj)
            
            global c;
            
            for i = 1:length(obj.pedestrians)
                if (~(c.DISPLAY_ONLY_ACTIVE_PEDESTRIANS && strcmp(obj.pedestrians{i}.get_state(), c.INITIALIZATION)))
                    obj.pedestrians{i}.plot_position_history();
                end
            end
        end
        
        %% Kalman filter
        
        function kalman_prediction(obj)
            
            for i = 1:length(obj.pedestrians)
               obj.pedestrians{i}.kalman_prediction(obj.pedestrian_motion_model);
            end
        end
        
        function kalman_update(obj)
            
            for i = 1:length(obj.pedestrians)
               obj.pedestrians{i}.kalman_update(obj.pedestrian_motion_model);
            end
        end
    end
    
end

