close all, clear all, clc;
patchMatrix = [];
boundaryArr = [];
%% STEP 1:

allImages = dir('*.png');  % the folder in which ur images exists
% Decaler a cell array to store the patches
n = 3000;
for i = 1 : length(allImages)
filename = strcat('images/',allImages(i).name);
% read the current image
image = imread(filename);
dimensions = size(image);
if (dimensions(3) == 3)
image = rgb2gray(image);
end
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%:

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
patches = {};
windowSize = 37;
halfLength = (windowSize-1)/2;
window = zeros(windowSize, windowSize);

% Extend the image
extendedImage = padarray(image,[halfLength,halfLength],'both');

% For each location of the interest point, take the window centered at it
for numberOfPoints = 1:interestPoints
x = floor(win(numberOfPoints,1));
y = floor(win(numberOfPoints,2));
for i = 1:windowSize
for j = 1:windowSize
window(i,j) = extendedImage(x+i-1, y+j-1);
end
end
patches{k} = window;
k = k + 1;
end

%     for k = 1:1:10
%         figure,imshow(mat2gray(patches{k}))
%     end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%:

% Converting all patches into vectors and storing them all in a matrix
for i=1:length(win)
c = (size(patchMatrix,1));
patchMatrix(c+1,:) = reshape(patches{1,i}, 1, windowSize*windowSize); %Patch made column wise
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Perform Clustering on the patches collected so far
train_pos_clusters = agglomerativeCluster( patchMatrix, 15 );
show_clusters( train_pos_clusters, patchMatrix )