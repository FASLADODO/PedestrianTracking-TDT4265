
global c; c = get_constants();

%% Setup

video_reader_1 = Video_reader_wrapper(c.MERGE_VIDEO_FILENAME_INPUT_1);
video_reader_2 = Video_reader_wrapper(c.MERGE_VIDEO_FILENAME_INPUT_2);

video_writer = Video_writer_wrapper(c.MERGE_VIDEO_FILENAME_OUTPUT, false, video_reader_1.get_frame_rate());

figure();

%% Read in frames, merge and then write to video

while (video_reader_1.should_proceed() && video_reader_2.should_proceed())
    
    current_frame_1 = video_reader_1.read_frame();
    current_frame_2 = video_reader_2.read_frame();
  
    merged_frames = [current_frame_1 current_frame_2];
    imshow(merged_frames);
    
    video_writer.write_frame();
end

video_writer.close();