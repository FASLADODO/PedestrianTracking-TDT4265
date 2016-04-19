
global c; c = get_constants();

%% Needs to have tsne installed

if (exist('tsne') == 0)
    disp('Please install tsne before running this script.');
    return;
end

%% Build feature representation of each directory

pedestrian_detector = Pedestrian_detector();

[X, Y, number_of_training_images] = pedestrian_detector.get_training_folder_features_and_labels();

%% Map the feature vectors onto 2 dimensions and plot

mapped_X = tsne(X);

gscatter(mapped_X(:, 1), mapped_X(:, 2), Y, 'br', 'xo');

legend('Clutter', 'Pedestrians');
title(['Tracking sequence: ' c.TRACKING_SEQUENCE], 'Interpreter', 'none');
