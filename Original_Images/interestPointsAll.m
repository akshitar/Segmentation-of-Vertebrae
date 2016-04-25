close all, clear all, clc;
patchMatrix = [];
boundaryArr = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Take all the positive samples and detect interest points
allImages = dir('*.png');  % the folder in which ur images exists
% Declare a cell array to store the patches
n = 5000;
for imageNumber = 1:24
    filename = strcat('backgroundImages/',allImages(imageNumber).name);
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
%     hold on
%     for i = 1:length(win)
%         plot(win(i).c,win(i).r,'b+');
%         hold on
%     end

    % Display the selected interest points on the image
%     figure, imshow(image);
%     title('Reduced interest points');
%     hold on
%     for i = 1:length(win)
%         plot(win(i,2),win(i,1),'r+');hold on;
%         boundaryArr(1,:) = [win(i,1)-diff win(i,2)-diff];
%         boundaryArr(2,:) = [win(i,1)-diff win(i,2)+diff];
%         boundaryArr(3,:) = [win(i,1)+diff win(i,2)+diff];
%         boundaryArr(4,:) = [win(i,1)+diff win(i,2)-diff];
%         boundaryArr(5,:) = [win(i,1)-diff win(i,2)-diff];
%         plot(boundaryArr(:,2)',boundaryArr(:,1)','g');
%     end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%:

    % Take image patches around the interest points and store them in a
    % cell array
    % Calculate the number of interest points that have been detected
    interestPoints = size(win,2);

    % Decide the size of patches
    k = 1;
    patches = {};
    windowSize = 25;
    halfLength = (windowSize-1)/2;
    window = zeros(windowSize, windowSize);

    % % Extend the image
    % extendedImage = padarray(image,[halfLength,halfLength],'both');
    borderColumns = size(image,1)-halfLength;
    borderRows = size(image,2)-halfLength;

    for i = 1:length(win)
        copyWin(i,1) = win(i).r;
        copyWin(i,2) = win(i).c;
    end
   
    for numberOfPoints = 1:interestPoints
        x = floor(win(numberOfPoints).r);
        y = floor(win(numberOfPoints).c);
    %     disp(x);
    %     disp(y);
        if ( (x > halfLength) & (x < borderColumns) )
            if ( (y > halfLength) & (y < borderRows) )
                window = image(x-halfLength:x+halfLength, y-halfLength:y+halfLength); 
                patches{k} = window;
                k = k + 1;
            else 
                sprintf('Patch is out of bounds for %d , %d', x , y)
                copyWin(numberOfPoints,:) = 0;
                
            end
        else 
            sprintf('Patch is out of bounds for %d , %d', x , y)
            copyWin(numberOfPoints,:) = 0;
        end
    end
    % delete the zero rows
    copyWin(all(copyWin==0,2),:)=[];
    %     for k = 1:1:10
    %         figure,imshow(mat2gray(patches{k}))
    %     end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%:

    % Converting all patches into vectors and storing them all in a matrix
    for i=1:length(patches)
        c = (size(patchMatrix,1));
        patchMatrix(c+1,:) = reshape(patches{1,i}, 1, windowSize*windowSize); %Patch made column wise
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % Perform Clustering on the patches collected so far
% train_pos_clusters = agglomerativeCluster( patchMatrix, 50 );
% show_clusters( train_pos_clusters, patchMatrix )
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 6 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Store the cluster centroids in a matrix
% 
% clusterSize = length(train_pos_clusters);
% for clusterNumber = 1:clusterSize
%     centroids(clusterNumber,:) = mean(patchMatrix(train_pos_clusters{1,clusterNumber},:),1);
end
