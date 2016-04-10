classdef Pedestrian < handle
   
    properties (Access = private)
        
        position;
        position_history;
        velocity;
        covariance;
        
        state;                  % c.INITIALIZATION | c.ACTIVE
        
        measurement_series;     % Keep c.MEASUREMENT_HISTORY_SIZE measurements
                                % Each entry constists of timestep and
                                % and array of position measurements
                                % belonging to this pedestrian
    end
    
    methods
        
        %% Constructor
        
        function obj = Pedestrian(position_measurement, timestep)
            
            obj.position            = position_measurement;
            obj.position_history    = [];
            obj.velocity            = [0; 0];            
            obj.covariance          = diag([1 1 5 5]);       % Unsure about speed of target, hence greate variance
            
            obj.measurement_series  = {};
            
            obj.measurement_series{1}           = struct();
            obj.measurement_series{1}.timestep  = timestep;
            obj.measurement_series{1}.positions = position_measurement;
        end
        
        %% Measurement handling
        
        % Create an empty measurement series for a new timestep
        
        function initialize_measurement_series(obj, timestep)
            
            global c;
            
            if (length(obj.measurement_series) >= c.MEASUREMENT_HISTORY_SIZE)
                obj.measurement_series{1} = [];
            end
            
            index = length(obj.measurement_series) + 1;
            
            obj.measurement_series{index} = struct();
            obj.measurement_series{index}.timestep = timestep;
            obj.measurement_series{index}.positions = [];
        end
        
        % Adds a new position measurement to the current time series
        % I.e. the entry which is in the last entry
        
        function add_position_measurement(obj, position_measurement)
            
            index = length(obj.measurement_series);
            n = size(obj.measurement_series{index}.positions, 2);
            
            obj.measurement_series{index}.positions(:, n + 1) = position_measurement;
        end
        
        % Retrieve the position measurement from the last timestep which
        % is closest to the current position in the distance sense, 
        % i.e. nearest neighbour search
        
        function latest_nn_position_measurement = get_latest_nn_position_measurement(obj)            % Nearest neighbour measurement search
            
            % Get last entry in the measurement series and check how many
            % measurements that were made
            
            index = length(obj.measurement_series);
            n = size(obj.measurement_series{index}.positions, 2);
            
            if (n == 0)
                latest_nn_position_measurement = [];
            else
                latest_nn_position_measurement = obj.measurement_series{index}.positions(:, 1);
                
                % Loop through and check if any of the other measurement are
                % closer in the sense of euclidean 2 norm
                
                for i = 2:n
                   
                    position_measurement = obj.measurement_series{index}.positions(:, 2);
                    
                    if (norm(latest_nn_position_measurement - obj.position) > norm(position_measurement - obj.position))
                        latest_nn_position_measurement = position_measurement;
                    end
                end
            end
        end
        
        %% Plots
        
        function pos = get_position(obj)
            pos = obj.position;
        end
        
        function plot_bounding_box(obj)
            
            global c;
            
            configuration = [obj.position(1) - (c.PEDESTRIAN_WIDTH / 2), obj.position(2) - (c.PEDESTRIAN_HEIGHT / 2), c.PEDESTRIAN_WIDTH, c.PEDESTRIAN_HEIGHT];
            rectangle('Position', configuration, 'EdgeColor', 'b');
        end
        
        function plot_position_history(obj)
            
            plot(obj.position_history(1, :), obj.position_history(2, :), 'b');
        end
        
        %% Kalman filtering
        
        function kalman_prediction(obj, pedestrian_motion_model)
            
            F = pedestrian_motion_model.F;
            Q = pedestrian_motion_model.Q;
            
            x = [obj.position; obj.velocity];
            P = obj.covariance;
            
            x = F * x;
            P = F * P * F';
            
            obj.position = x(1:2);
            obj.velocity = x(3:4);
            obj.covariance = P;
        end
        
        function kalman_update(obj, pedestrian_motion_model)
            
            latest_measurement = obj.get_latest_nn_position_measurement();
            
            % If no measurement arrived settle with prediction
            
            if (~isempty(latest_measurement))
            
                H = pedestrian_motion_model.H;
                R = pedestrian_motion_model.R;

                x = [obj.position; obj.velocity];
                P = obj.covariance;
                z = latest_measurement;

                y = (z - H * x);
                S = H * P * H' + R;
                K = P * H' * inv(S);
                I = eye(length(x));

                x = x + K * y;
                P = (I - K * H) * P;

                obj.position = x(1:2);
                obj.velocity = x(3:4);
                obj.covariance = P;
            end
            
            obj.position_history(:, size(obj.position_history, 2) + 1 ) = obj.position;
        end
    end
    
end