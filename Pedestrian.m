classdef Pedestrian < handle
   
    properties (Access = private)
        
        position;
        position_history;
        velocity;
        covariance;
        
        state;          % INITIALIZATION | ACTIVE
        
        measurements;   % Keep HISTORY_SIZE measurements
    end
    
    methods
        
        % Constructor
        
        function obj = Pedestrian(measurement)
            
            obj.position = measurement.position;
            obj.position_history = [];
            obj.velocity = [0; 0];            
            obj.covariance = diag([1 1 5 5]);       % Unsure about speed of target
            
            obj.measurements = {};
            obj.measurements{1} = measurement;
        end
        
        % Measurement handling
        
        function add_measurement(obj, measurement)
            obj.measurements{length(obj.measurements) + 1} = measurement;
        end
        
        function latest_measurement = get_latest_measurement(obj)
            latest_measurement = obj.measurements{length(obj.measurements)};
        end
        
        function measurements = get_measurements(obj)
            measurements = obj.measurements;
        end
        
        % Plots
        
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
        
        % Kalman filtering
        
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
            
            latest_measurement = obj.get_latest_measurement();
            
            H = pedestrian_motion_model.H;
            R = pedestrian_motion_model.R;
            
            x = [obj.position; obj.velocity];
            P = obj.covariance;
            z = latest_measurement.position;
            
            y = (z - H * x);
            S = H * P * H' + R;
            K = P * H' * inv(S);
            I = eye(length(x));
            
            x = x + K * y;
            P = (I - K * H) * P;
            
            obj.position = x(1:2);
            obj.velocity = x(3:4);
            obj.covariance = P;
            
            obj.position_history(:, size(obj.position_history, 2) + 1 ) = obj.position;
        end
    end
    
end