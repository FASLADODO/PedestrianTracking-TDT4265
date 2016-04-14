classdef Video_writer_wrapper < handle

    properties (Access = private)
        output_video;
    end
    
    properties (Access = public)
        
    end
    
    methods
        
        %% Constructor
        
        function obj = Video_writer_wrapper(frame_rate)
            
            global c;
            
            filename = fullfile(c.TRACKING_RESULT_OUTPUT_FILE);
            
            if (c.STORE_TRACKING_RESULT)
                
                obj.output_video = VideoWriter(filename);
                obj.output_video.FrameRate = frame_rate / 4;
                
                open(obj.output_video);
            else
                obj.output_video = [];
            end
        end
        
        %% Misc
        
        function write_frame(obj)
            
            frame = getframe();
            
            writeVideo(obj.output_video, frame);
        end
        
        function close(obj)
            close(obj.output_video)
        end
        
    end 
end

