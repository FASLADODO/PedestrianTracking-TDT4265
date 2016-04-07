classdef Pedestrian < handle
    properties
        position;
        measurements;
        velocity;
        state;
    end
    
    methods
        
        % Constructor
        
        function obj = Pedestrian(measurement)
            obj.measurements = {};
            obj.position = measurement.position;
            obj.velocity = [0; 0];
            obj.measurements{1} = measurement;
        end
        
        % Methods
        
        function add_measurement(obj, measurement)
            obj.measurements{length(obj.measurements) + 1} = measurement;
        end
        
        function latest_measurement = get_latest_measurement(obj)
            latest_measurement = obj.measurements{length(obj.measurements)};
        end
        
        function measurements = get_measurements(obj)
            measurements = obj.measurements;
        end
        
        function pos = get_position(obj)
            pos = obj.position;
        end
        
        function display(obj, width, height)
            configuration = [obj.position(1) - width/2, obj.position(2) - height/2, width, height];
            rectangle('Position', configuration, 'EdgeColor', 'b');
        end
        
    end
    
end