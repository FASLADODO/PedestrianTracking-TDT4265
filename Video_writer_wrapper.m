classdef Video_writer_wrapper < handle

    properties (Access = private)
        output_video;
        is_dummy_writer;
    end
    
    properties (Access = public)
        
    end
    
    methods
        
        %% Constructor
        
        function obj = Video_writer_wrapper(filename, is_dummy_writer, frame_rate)
            
            obj.is_dummy_writer = is_dummy_writer;
            
            if (~obj.is_dummy_writer)
                
                obj.output_video = VideoWriter(filename);
                obj.output_video.FrameRate = frame_rate;
                
                open(obj.output_video);
            else
                obj.output_video = [];
            end
        end
        
        %% Misc
        
        function write_frame(obj)
            
            if (~obj.is_dummy_writer)
                
                current_frame = getframe();
                
                writeVideo(obj.output_video, current_frame.cdata);
            end
        end
        
        function close(obj)
            
            if (~obj.is_dummy_writer)
                close(obj.output_video);
            end
        end
    end 
end

