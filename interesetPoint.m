close all, clear all, clc;
patchMatrix = [];
boundaryArr = [];
%% STEP 1:

allImages = dir('*.png');  % the folder in which ur images exists
% Decaler a cell array to store the patches
n = 3000;
patches = cell(n, 1);
k = 1;
for i = 1 : length(allImages)
filename = strcat('images/',allImages(i).name);
% read the current image
image = imread(filename);
dimensions = size(image);
if (dimensions(3) == 3)
image = rgb2gray(image);
end
%figure, imshow(image);

% Call with default parameters
% [win, corner, circ, noclass] = ip_fop(g);

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
%     for i=1:length(win)
%         fprintf('%5.1f   %5.1f\n',win(i).r,win(i).c);
%     end
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
%     [Y,I]=sort(dummy(:,1));
%     dummy = dummy(I,:); %use the column indices from sort() to sort all columns of A.
for i=1:length(dummy)
if (i==length(dummy))
break
else
boundaryArr(1,:) = [dummy(i,1)-10 dummy(i,2)-10];
boundaryArr(2,:) = [dummy(i,1)-10 dummy(i,2)+10];
boundaryArr(3,:) = [dummy(i,1)+10 dummy(i,2)+10];
boundaryArr(4,:) = [dummy(i,1)+10 dummy(i,2)-10];
[in,on] = inpolygon(dummy(i+1:length(dummy),1),dummy(i+1:length(dummy),2),boundaryArr(:,1)',boundaryArr(:,2)');
plot(boundaryArr(:,2)',boundaryArr(:,1)','r');
hold on;
xq = dummy(i+1:length(dummy),1);
yq = dummy(i+1:length(dummy),2);
xq;
yq(in);
% Removal of interest points with values within +3 and -3 of
% current interest point
%     extra = [];
%     extra(:,1) = abs(dummy(i+1:length(dummy),1) - dummy(i,1)); % r of win
%     extra(:,2) = abs(dummy(i+1:length(dummy),1) - dummy(i,2)); % c of win
%     redCond = (extra(:,1)<=4) & (extra(:,2)<=8);
%     dummy(redCond,:) = [];
end
%     end
%     win = dummy;
%     % Display the selected interest points on the image
%     figure, imshow(image);
%     title('Reduced interest points');
%     hold on
%     for i = 1:length(win)
%         plot(win(i,2),win(i,1),'r+');
%
%end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%:

% Take image patches around the interest points and store them in a
% cell array
% Calculate the number of interest points that have been detected
interestPoints = size(win,2);
% Decide the size of patches
windowSize = 37;
halfLength = (windowSize-1)/2;
window = zeros(windowSize, windowSize);
% Extend the image
extendedImage = padarray(image,[halfLength,halfLength],'both');
% For each location of the interest point, take the window centered at it
for numberOfPoints = 1:interestPoints
x = floor(win(numberOfPoints).r);
y = floor(win(numberOfPoints).c);
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
for i=1:650
patchMatrix(length(patchMatrix)+1,:) = reshape(patches{i,1}, 1, windowSize*windowSize); %Patch made column wise
end
end