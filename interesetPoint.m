close all, clear all, clc;

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
end
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
                                    'VISUALIZATION'            ,'on');       ... visualization on or off (default : 'off')


% Output:
disp('Results:');
%a) integer positions of window centers
disp('Positions of window centers (actually were integers in the internally scaled image):');
for i=1:length(win)
fprintf('%5.1f   %5.1f\n',win(i).r,win(i).c);
end

%% Reducing the number of interest points
winMatrix = [];
winMatrix(1,:) = [win.r];
winMatrix(2,:) = [win.c];
winMatrix = winMatrix';
dummy = winMatrix;
for i=1:size(dummy,1)
if (i==size(dummy,1))
break
else
extra = [];
extra(1,:) = dummy(i+1:size(dummy,1),1) - dummy(i,1);
extra(2,:) = dummy(i+1:size(dummy,1),2) - dummy(i,2);
extra = extra';
redCond = (abs(extra(:,1))<8) & (abs(extra(:,2))<8);
dummy(redCond,:) = [];
end
end
win = dummy;
%% STEP 2:

% Take image patches around the interest points and store them in a
% cell array
% Calculate the number of interest points that have been detected
interestPoints = size(win,1);
% Decide the size of patches
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

%figure,imshow(mat2gray(patches{k}));
% without reducing the number of interest points we get 3000 patches for each image 
