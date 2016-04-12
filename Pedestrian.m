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
            
            global c;
            
            obj.position            = position_measurement;
            obj.position_history    = [];
            obj.velocity            = [0; 0];            
            obj.covariance          = diag([1 1 5 5]);       % Unsure about speed of target, hence greate variance
            
            obj.state               = c.INITIALIZATION;
            
            obj.measurement_series  = {};
            
            obj.measurement_series{1}           = struct();
            obj.measurement_series{1}.timestep  = timestep;
            obj.measurement_series{1}.positions = position_measurement;
        end
        
        %% Misc
        
        function state = get_state(obj)
            state = obj.state;
        end
        
        function pos = get_position(obj)
            pos = obj.position;
        end
        
        function age = get_age(obj)
            age = size(obj.position_history, 2);
        end
        
        function update_state(obj)
           
            global c;
            
            if (strcmp(obj.state, c.INITIALIZATION))
            
                if (obj.get_non_empty_measurement_series() > c.EXIT_INITIALIZATION_THRESHOLD)
                    obj.state = c.ACTIVE;
                end
            end
        end
        
        function inactive = is_inactive(obj)
            
            if (obj.get_non_empty_measurement_series() <= 0)
                inactive = true;
            else
                inactive = false;
            end
        end
        
        function update_position_history(obj)
            obj.position_history(:, size(obj.position_history, 2) + 1 ) = obj.position;
        end
        
        %% Measurement handling
        
        % Create an empty measurement series for a new timestep
        
        function initialize_measurement_series(obj, timestep)
            
            global c;
            
            if (length(obj.measurement_series) >= c.MEASUREMENT_HISTORY_SIZE)
                obj.measurement_series = {obj.measurement_series{2:end}};
            end
            
            index = length(obj.measurement_series) + 1;
            
            obj.measurement_series{index} = struct();
            obj.measurement_series{index}.timestep = timestep;
            obj.measurement_series{index}.positions = [];
        end
        
        % Check how many of the measurements series are nonempty
        
        function non_empty_measurement_series = get_non_empty_measurement_series(obj)
            
            non_empty_measurement_series = 0;
                
            for i = 1:length(obj.measurement_series)

                if (~isempty(obj.measurement_series{i}.positions))
                    non_empty_measurement_series = non_empty_measurement_series + 1;
                end
            end
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
        
        function color = get_state_based_plot_color(obj)

            global c;
            
            if (strcmp(obj.state, c.INITIALIZATION))
                color = 'c';
            else
                color = 'b';
            end
        end
        
        function plot_bounding_box(obj)
            
            global c;
            
            configuration = [obj.position(1) - (c.PEDESTRIAN_WIDTH / 2), obj.position(2) - (c.PEDESTRIAN_HEIGHT / 2), c.PEDESTRIAN_WIDTH, c.PEDESTRIAN_HEIGHT];
            color = obj.get_state_based_plot_color();

            rectangle('Position', configuration, 'EdgeColor', color);
        end
        
        function plot_position_history(obj)

            color = obj.get_state_based_plot_color();
            
            plot(obj.position_history(1, :), obj.position_history(2, :), color);
        end
        
        %% Kalman filtering
        
        function kalman_prediction(obj, pedestrian_motion_model)
            
            F = pedestrian_motion_model.F;
            Q = pedestrian_motion_model.Q;
            
            x = [obj.position; obj.velocity];
            P = obj.covariance;
            
            x = F * x;
            P = F * P * F' + Q;
            
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
        end
    end
    
end