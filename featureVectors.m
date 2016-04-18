clear all;
close all;
clc;
load train_pos_clusters.mat;
load train_neg_clusters.mat;
load patchMatrix.mat;
load patchMatrixNeg.mat;
totalPositivePatches = size(patchMatrix,1);
totalNegativePatches = size(patchMatrixNeg,1);
lengthNegCluster = length(train_neg_clusters);
lengthPosCluster = length(train_pos_clusters);
totalClusters = lengthNegCluster + lengthPosCluster;
% for negCluster = 1:length(train_neg_clusters)
%     train_neg_clusters{1,negCluster} = train_neg_clusters{1,negCluster} + lengthPosCluster;
% end
positiveFeatureVectors = zeros(totalPositivePatches, totalClusters);
negativeFeatureVectors = zeros(totalNegativePatches, totalClusters);
% Piece of code to assign binary features depending on the cluster number
for index = 1:lengthPosCluster
    % For positive patches
    contents = train_pos_clusters{1,index};
    for numberOfElement = 1:length(contents)
        positiveFeatureVectors(contents(numberOfElement),index) = 1;
    end
end
trainingData = [positiveFeatureVectors; negativeFeatureVectors];

for index = 1:lengthNegCluster
    % For negative patches
    contents = train_neg_clusters{1,index};
    for numberOfElement = 1:length(contents)
        trainingData((contents(numberOfElement))+totalPositivePatches,index+lengthPosCluster) = 1;
    end
end

% Concatente the positive and negative feature vectors and give labels
trainingData(1:totalPositivePatches,totalClusters+1) = 1;
trainingData(totalPositivePatches+1:end,totalClusters+1) = -1;
