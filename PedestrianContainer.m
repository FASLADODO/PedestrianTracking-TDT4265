classdef PedestrianContainer < handle
 
    properties (Access = private)
        pedestrians;
        pedestrian_motion_model;
    end
    
    methods
        
        %% Constructor
        
        function obj = PedestrianContainer()
            obj.pedestrians = {};
            obj.pedestrian_motion_model = PedestrianMotionModel();
        end
        
        %% Misc
        
        function update_position_histories(obj)
            
            for i = 1:length(obj.pedestrians)
               obj.pedestrians{i}.update_position_history();
            end
        end
        
        %% Measurement handling
        
        function inititalize_measurement_series(obj, timestep)
            
            for i = 1:length(obj.pedestrians)
               obj.pedestrians{i}.initialize_measurement_series(timestep);
            end
        end
        
        function distribute_position_measurement(obj, position_measurement, timestep)
            
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
            
            obj.pedestrians{length(obj.pedestrians) + 1} = Pedestrian(position_measurement, timestep);
        end
        
        %% Plots
        
        function plot_bounding_boxes(obj)
            
            for i = 1:length(obj.pedestrians)
               obj.pedestrians{i}.plot_bounding_box();
            end
        end
        
        function plot_position_histories(obj)
            
            for i = 1:length(obj.pedestrians)
               obj.pedestrians{i}.plot_position_history();
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

