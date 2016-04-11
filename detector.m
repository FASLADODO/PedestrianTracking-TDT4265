function [label, score] = detector(classifier, image)

    HOG_features = extractHOGFeatures(image);
    [label, score] = predict(classifier, HOG_features);
end

