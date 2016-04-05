
clc;
clear all;

%------------------------------------------------

VIDEO_FILE                  = 'drone_moving_camera.mp4';

COMPONENT_AREA_THRESHOLD    = 50;
CLOSE_DISC_RADIUS           = 3;

DISPLAY_FLOW                = true;
DISPLAY_MAGNITUDE           = false;
DISPLAY_MARKERS             = true;

%------------------------------------------------

vidReader = VideoReader(VIDEO_FILE);
opticFlow = opticalFlowLK('NoiseThreshold',0.009);

while hasFrame(vidReader)
    
    % Correct geometric transform of camera
    
    
    
    % Estimate flow
    
    frameRGB = readFrame(vidReader);
    frameGray = rgb2gray(frameRGB);
    
    flow = estimateFlow(opticFlow,frameGray);

    % Get pixels which move faster than a desired threshold
    
    magnitude =im2bw(flow.Magnitude, graythresh(flow.Magnitude));
    magnitude = imclose(magnitude, strel('disk', CLOSE_DISC_RADIUS));
    magnitude = imfill(magnitude, 'holes');
    
    % Filter out components which are big enough
    
    proposed_props = regionprops(magnitude);
    props = [];
    
    for i = 1:length(proposed_props)
       
        if (proposed_props(i).Area > COMPONENT_AREA_THRESHOLD)
            props(1:2, size(props, 2) + 1) = proposed_props(i).Centroid;
        end
    end
    
    % Display results
    
    imshow(frameRGB)
    
    hold on;
    
    if (DISPLAY_FLOW)
        plot(flow,'DecimationFactor',[5 5],'ScaleFactor',10);
    end
    
    if (DISPLAY_MAGNITUDE)
        imshow(magnitude);
    end
    
    if (DISPLAY_MARKERS)
        for i = 1:size(props, 2)
            plot(props(1, i), props(2, i), 'rx');
        end
    end
    
    hold off;
    pause(0.05);
end