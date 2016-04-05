clear all; clc;
%------------------------------------------------

VIDEO_FILE                  = 'drone.mp4';

COMPONENT_AREA_THRESHOLD    = 50;
CLOSE_DISC_RADIUS           = 3;

DISPLAY_FLOW                = true;
DISPLAY_MAGNITUDE           = false;
DISPLAY_MARKERS             = true;

USE_GEOMETRIC_TRANSFORM     = false;

%------------------------------------------------

vidReader = VideoReader(VIDEO_FILE);
opticFlow = opticalFlowLK('NoiseThreshold', 0.009);

previous_frame = [];
first = true;

while hasFrame(vidReader)
    
    % Correct geometric transform of camera
    
    frameRGB = readFrame(vidReader);
    frameGray = rgb2gray(frameRGB);
    
    if (first)
        
        previous_frame = frameGray;
        first = false;
        
        continue;
    end
    
    if (USE_GEOMETRIC_TRANSFORM)
        
        ptsOriginal = detectSURFFeatures(frameGray);
        ptsPrevious = detectSURFFeatures(previous_frame);

        [featuresOriginal,validPtsOriginal] = extractFeatures(frameGray, ptsOriginal);
        [featuresPrevious,validPtsPrevious] = extractFeatures(previous_frame, ptsPrevious);

        index_pairs = matchFeatures(featuresOriginal,featuresPrevious);
        matchedPtsOriginal  = validPtsOriginal(index_pairs(:,1));
        matchedPtsPrevious = validPtsPrevious(index_pairs(:,2));
        
        [tform, inlierPtsPrevious, inlierPtsOriginal] = estimateGeometricTransform(matchedPtsPrevious, matchedPtsOriginal,'similarity');
        
        frame_distorted = imwarp(frameGray, tform);
        
        imshowpair(frame_distorted, previous_frame, 'montage');
        pause();
    end
       
    % Estimate flow
    
    reset(opticFlow);
    flow = estimateFlow(opticFlow, previous_frame);
    flow = estimateFlow(opticFlow, frameGray);
    
    previous_frame = frame_distorted;
    
    % Get pixels which move faster than a desired threshold
    
    magnitude = im2bw(flow.Magnitude, graythresh(flow.Magnitude));
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
