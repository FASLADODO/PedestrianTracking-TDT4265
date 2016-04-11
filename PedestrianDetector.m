classdef PedestrianDetector < handle
 
    properties (Access = private)
        
       previous_frame;
       current_frame;
       
       has_previous_frame;
    end
    
    methods
        
        %% Constructor
        
        function obj = PedestrianDetector()
            
            obj.previous_frame = [];
            obj.current_frame = [];
            
            obj.has_previous_frame = false;
        end
        
        %% Contrast enhancement
        
        
        
        %% Difference image detection
        
        function [position_measurements] = difference_image_detection(obj, current_frame)
           
            global c;
            
            obj.previous_frame = obj.current_frame;
            obj.current_frame = current_frame;
            
            % Make sure something is buffered when doing difference image
            
            if (~obj.has_previous_frame)
                
                obj.has_previous_frame = true;
                position_measurements = [];
                
                return;
            end
            
            % Compute difference image
            
            difference_image = imabsdiff(obj.current_frame, obj.previous_frame);

            structuring_element = [1 1 1 1 1 1 1 1 1]';
            structuring_element = repmat(structuring_element, 2, 2);

            difference_image = im2bw(difference_image, c.DIFFERENCE_IMAGE_THRESHOLD);
            difference_image = imclose(difference_image, structuring_element);
            
            % Get measurements from connected components
            
            proposed_position_measurement = regionprops(difference_image);
            position_measurements = [];

            for i = 1:length(proposed_position_measurement)

                if (proposed_position_measurement(i).Area > c.COMPONENT_AREA_THRESHOLD)
                    position_measurements(1:2, size(position_measurements, 2) + 1) = proposed_position_measurement(i).Centroid;
                end
            end
        end
    end
    
end

