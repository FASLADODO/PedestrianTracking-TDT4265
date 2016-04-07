
clc;
clear all;

%------------------------------------------------

VIDEO_FILE                  = 'ewap_dataset/seq_eth/seq_eth.avi';

MAGNITUDE_THRESHOLD         = 0.1;
COMPONENT_AREA_THRESHOLD    = 50;
CLOSE_DISC_RADIUS           = 3;

DISPLAY_FLOW                = true;
DISPLAY_MAGNITUDE           = false;
DISPLAY_MARKERS             = true;

%------------------------------------------------

vidReader = VideoReader(VIDEO_FILE);
vidReader.CurrentTime = 30;

opticFlow = opticalFlowLK('NoiseThreshold',0.009);

while hasFrame(vidReader) && (vidReader.CurrentTime < 32)

    % Estimate flow
    
    frameRGB = readFrame(vidReader);
    frameGray = rgb2gray(frameRGB);
    
    flow = estimateFlow(opticFlow,frameGray);

    % Get pixels which move faster than a desired threshold
    
    if (MAGNITUDE_THRESHOLD == -1)
        magnitude_threshold = graythresh(flow.Magnitude);
    else
        magnitude_threshold = MAGNITUDE_THRESHOLD;
    end
    
    magnitude =im2bw(flow.Magnitude, magnitude_threshold);
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