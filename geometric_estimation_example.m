original  = imread('drone_photo.jpg');
original = rgb2gray(original);
imshow(original);

title('Base image');

distorted = imresize(original,0.7);
distorted = imrotate(distorted,31);
figure; imshow(distorted);

title('Transformed image');

ptsOriginal  = detectSURFFeatures(original);
ptsDistorted = detectSURFFeatures(distorted);

[featuresOriginal,validPtsOriginal] = extractFeatures(original, ptsOriginal);
[featuresDistorted,validPtsDistorted] = extractFeatures(distorted,ptsDistorted);

% Point matching
index_pairs = matchFeatures(featuresOriginal,featuresDistorted);
matchedPtsOriginal  = validPtsOriginal(index_pairs(:,1));
matchedPtsDistorted = validPtsDistorted(index_pairs(:,2));
figure;
showMatchedFeatures(original,distorted,matchedPtsOriginal,matchedPtsDistorted);
title('Matched SURF points,including outliers');
