clear all;
close all;
clc;
% Calculation of the final cluster centroids
load train_neg_clusters;
load train_pos_clusters;
load patchMatrix;
load patchMatrixNeg;
%new_train_neg_clusters = {};
clusterSize = length(train_neg_clusters);
for clusterNumber = 1:clusterSize
    % Add the positive patches in every cluster and count the number 
    sumPositive = sum(patchMatrix(train_pos_clusters{1,clusterNumber},:),1);
    lengthPositive = length(train_pos_clusters{1,clusterNumber});
    % Add the negative patches in every cluster and count the number 
    sumNegative = sum(patchMatrixNeg(cell2mat(train_neg_clusters{1,clusterNumber}),:),1);
    lengthNegative = length(train_neg_clusters{1,clusterNumber});
    new_centroids(clusterNumber,:) = (sumPositive + sumNegative)/(lengthPositive + lengthNegative);
end

% Take all the positive samples and detect interest points
allImages = dir('*.jpg');  % the folder in which ur images exists
% Declare a cell array to store the patches
n = 3000;
imageNumber = 1;
filename = strcat('Testing/',allImages(imageNumber).name);
% read the current image
image = imread(filename);
dimensions = size(image);
% if (dimensions(3) == 3)
% image = rgb2gray(image);
% end
%figure, imshow(image);

% Call with other control parameters
disp('Calling ip_fop ...');
[win, corner, circ, noclass]=ip_fop( ...
                                    image,                                       ... intensity image (one channel, grey-level image)
                                    'DETECTION_METHOD',        'foerstner',  ... method for optimal search window: 'foerstner' (default) or 'koethe'
                                    'SIGMA_N'                  ,1.0,         ... standard deviation of (constant) image noise (default: 2.0)
                                    'DERIVATIVE_FILTER'        ,'gaussian2d',... filter for gradient: 'gaussian2d'(default) oder 'gaussian1d'
                                    'INTEGRATION_FILTER'       ,'gaussian',  ... integration kernel: 'box_filt' (default) oder 'gaussian'
                                    'SIGMA_DERIVATIVE_FILTER'  ,0.7,         ... size of derivative filter (sigma) (default: 1.0)
                                    'SIGMA_INTEGRATION_FILTER' ,2,           ... size of integration filter (default: 1.41 * SIGMA_DIFF)
                                    'PRECISION_THRESHOLD'      ,0.5,         ... threshold for precision of points (default: 0.5 Pixel)
                                    'ROUNDNESS_THRESHOLD'      ,0.3,         ... threshold for roundness (default: 0.3)
                                    'SIGNIFICANCE_LEVEL'       ,0.999,       ... significance level for point classification (default: 0.999)
                                    'VISUALIZATION'            ,'off');       ... visualization on or off (default : 'off')

% Output:
disp('Results:');
% a) integer positions of window centers
disp('Positions of window centers (actually were integers in the internally scaled image):');
figure, imshow(image);
title('All the interest points');
hold on
for i = 1:length(win)
plot(win(i).c,win(i).r,'b+');
hold on
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Reducing the number of interest points
winMatrix = [];
winMatrix(1,:) = [win.r];
winMatrix(2,:) = [win.c];
winMatrix = winMatrix';
dummy = winMatrix;
dummy(:,3) = zeros([length(winMatrix),1]);
diff = 15;
for i=1:length(dummy)
if (i==length(dummy))
break
elseif (dummy(i,3)~=1) % Avoiding points already marked as redundant
%     Removal of interest points with values within the neighbourhood of
%     the current interest points
extra = zeros([650,2]);
extra(i+1:length(dummy),1) = abs(dummy(i+1:length(dummy),1) - dummy(i,1)); % r of win
extra(i+1:length(dummy),2) = abs(dummy(i+1:length(dummy),2) - dummy(i,2)); % c of win
auxiliaryPoints = zeros(650,1);
auxiliaryPoints(i+1:length(dummy),1) = (extra(i+1:length(dummy),1) <= diff) & (extra(i+1:length(dummy),2) <= diff);
dummy(auxiliaryPoints == 1,3) = 1;
end
end

% Removing those points marked as redundant
dummy(dummy(:,3)==1,:) = [];
win = dummy(:,1:2);

% Display the selected interest points on the image
figure, imshow(image);
title('Reduced interest points');
hold on
for i = 1:length(win)
plot(win(i,2),win(i,1),'r+');hold on;
boundaryArr(1,:) = [win(i,1)-diff win(i,2)-diff];
boundaryArr(2,:) = [win(i,1)-diff win(i,2)+diff];
boundaryArr(3,:) = [win(i,1)+diff win(i,2)+diff];
boundaryArr(4,:) = [win(i,1)+diff win(i,2)-diff];
boundaryArr(5,:) = [win(i,1)-diff win(i,2)-diff];
plot(boundaryArr(:,2)',boundaryArr(:,1)','g');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%:

% Take image patches around the interest points and store them in a
% cell array
% Calculate the number of interest points that have been detected
interestPoints = size(win,1);

% Decide the size of patches
k = 1;
testPatches = {};
windowSize = 37;
halfLength = (windowSize-1)/2;
window = zeros(windowSize, windowSize);

% % Extend the image
% extendedImage = padarray(image,[halfLength,halfLength],'both');
borderColumns = size(image,1)-halfLength;
borderRows = size(image,2)-halfLength;

% For each location of the interest point, take the window centered at it
for numberOfPoints = 1:interestPoints
    x = floor(win(numberOfPoints,1));
    y = floor(win(numberOfPoints,2));
%     disp(x);
%     disp(y);
    if ( (x > halfLength) && (x < borderColumns) )
        if ( (y > halfLength) && (y < borderRows) )
            window = image(x-halfLength:x+halfLength, y-halfLength:y+halfLength); 
            testPatches{k} = window;
            k = k + 1;
        else 
            sprintf('Patch is out of bounds for %d , %d', x , y)
        end
    else 
        sprintf('Patch is out of bounds for %d , %d', x , y)
    end
end
%     for k = 1:1:10
%         figure,imshow(mat2gray(patches{k}))
%     end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%:

% Converting all patches into vectors and storing them all in a matrix
testPatchMatrix = [];
for i=1:length(testPatches)
c = (size(testPatchMatrix,1));
testPatchMatrix(c+1,:) = reshape(testPatches{1,i}, 1, windowSize*windowSize); %Patch made column wise
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%:

% Perform clustering on all the patches
numberOfPatches = size(testPatchMatrix,1);
numberOfCentroids = size(new_centroids,1);
% Declare a cell aray to hold similar patch's indices together
test_clusters = cell(1,numberOfCentroids);
for index = 1:numberOfCentroids
    test_clusters{1,index} = zeros(0,0);
end
% Calculate the euclidean distance between the patch from each of the
% centroids
currentMatrix = zeros(2,windowSize*windowSize);
distance = zeros(numberOfCentroids,1);
for currentPatch = 1:numberOfPatches
    for currentCentroid = 1:numberOfCentroids
    currentMatrix(1,:) = patchMatrixNeg(currentPatch,:);
    currentMatrix(2,:) = new_centroids(currentCentroid,:);
    distance(currentCentroid,1) = pdist(currentMatrix,'euclidean');
    end
    % Assign the patch to the cluster which is the nearest
    [minimumDistance, nearestCentroid] = min(distance);
    test_clusters{nearestCentroid} = [test_clusters{nearestCentroid} num2cell(currentPatch)];
end

% Display similar patches
show_neg_clusters( test_clusters, testPatchMatrix )
