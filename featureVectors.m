clear all;
close all;
clc;
load train_pos_clusters.mat;
load train_neg_clusters.mat;
load patchMatrix.mat;
load patchMatrixNeg.mat;
totalPositivePatches = size(patchMatrix,1);
totalNegativePatches = size(patchMatrixNeg,1);
totalClusters = size(train_pos_clusters,2);
positiveFeatureVectors = zeros(totalPositivePatches, totalClusters);
negativeFeatureVectors = zeros(totalNegativePatches, totalClusters);
% Piece of code to assign binary features depending on the cluster number
for index = 1:totalClusters
    % For positive patches
    contents = train_pos_clusters{1,index};
    for numberOfElement = 1:length(contents)
        positiveFeatureVectors(contents(numberOfElement),index) = 1;
    end
    % For negative patches
    contents = train_neg_clusters{1,index};
    if ~isempty(contents)
        for numberOfElement = 1:length(contents)
            negativeFeatureVectors(contents{numberOfElement},index) = 1;
        end
    end
end
% Concatente the positive and negative feature vectors and give labels
trainingData = [positiveFeatureVectors; negativeFeatureVectors];
trainingData(1:totalPositivePatches,totalClusters+1) = 1;
trainingData(totalPositivePatches+1:end,totalClusters+1) = -1;
