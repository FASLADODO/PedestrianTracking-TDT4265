classdef PedestrianTracker < handle
 
    properties (Access = private)
        
        timestep;
        
        pedestrians;
        pedestrian_motion_model;
    end
    
    methods
        
        %% Constructor
        
        function obj = PedestrianTracker()
            
            obj.timestep = 1;
            
            obj.pedestrians = {};
            obj.pedestrian_motion_model = PedestrianMotionModel();
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
        
        function distribute_position_measurement(obj, position_measurement)
            
            global c;
            
            % Search for connection between pedestrian and measurement
            
            for i = 1:length(obj.pedestrians)
               
                pedestrian_position = obj.pedestrians{i}.get_position();
                position_offset = position_measurement - pedestrian_position;
                
                if (abs(position_offset(1)) <= (c.PEDESTRIAN_WIDTH / 2)) && (abs(position_offset(2)) <= (c.PEDESTRIAN_HEIGHT / 2))
                    
                    obj.pedestrians{i}.add_position_measurement(position_measurement);
                    
                    return;
                end
            end
            
            % If no connection was found initialize a new pedestrian
            
            index = length(obj.pedestrians) + 1;

            obj.pedestrians{index} = Pedestrian(position_measurement, obj.timestep);
        end
        
        %% Plots
        
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

