classdef Video_reader_wrapper < handle

    properties (Access = private)
        video_reader;
    end
    
    properties (Access = public)
        
    end
    
    methods
        
        %% Constructor
        
        function obj = Video_reader_wrapper(filename)
            obj.video_reader = VideoReader(filename);
        end
        
        %% Misc
        
        % Proceed
        
        function proceed = should_proceed_with_tracking(obj)
            
            global c;
            
            proceed = hasFrame(obj.video_reader) && (obj.video_reader.CurrentTime < c.TRACKING_START + c.TRACKING_DURATION);
        end
        
        function proceed = should_proceed(obj)
                    
            proceed = hasFrame(obj.video_reader);
        end
        
        % Frames
        
        function frame_rate = get_frame_rate(obj)
            frame_rate = obj.video_reader.FrameRate;
        end
        
        function gray_frame = read_gray_frame(obj)
            
            gray_frame = readFrame(obj.video_reader);
            gray_frame = rgb2gray(gray_frame);
        end
        
        function frame = read_frame(obj)
            frame = readFrame(obj.video_reader);
        end
        
        % Set time
        
        function current_time = get_current_time(obj)
            current_time = obj.video_reader.CurrentTime; 
        end
        
        function set_current_time(obj, current_time)
            obj.video_reader.CurrentTime = current_time;
        end
    end 
end

