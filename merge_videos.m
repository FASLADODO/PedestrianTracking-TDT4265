global c; c = get_constants();

video_reader_1 = Video_reader_wrapper();
video_reader_2 = Video_reader_wrapper();

figure();

while (video_reader_1.should_proceed() && video_reader_2.should_proceed())
    
    current_frame_1 = video_reader_1.read_gray_frame();
    current_frame_2 = video_reader_2.read_gray_frame();
  
    both_frames = [current_frame_1 current_frame_2];
    imshow(both_frames);
    
    pause();
    
end