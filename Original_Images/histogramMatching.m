% Filter to sharpen the training images
h = fspecial('unsharp');
allImages = dir('*.jpg');
%% Histogram matching
% Take a reference image and filter it
imageRef = imread('image_1.jpg');
imageRef = imfilter(imageRef,h);

histRef = imhist(imageRef); % Compute histogram
%figure; imhist(imageRef);
cdfRef = cumsum(histRef) / numel(imageRef);

% Declare a cell to hold all the matched images
matchedImages = {};

% Perform histogram matching w.r.t the reference image
for imageNumber = 1:4
    filename = strcat('Original_Images/',allImages(imageNumber).name);

    % read the current image
    imageCurrent = imread(filename);
    imageCurrent = imfilter(imageCurrent,h); % filter the current image
    M = zeros(256,1,'uint8'); % Store mapping - Cast to uint8 to respect data type
    histCurrent = imhist(imageCurrent);
    cdfCurrent = cumsum(histCurrent) / numel(imageCurrent);
    %figure; imhist(imageCurrent);
    
    % Compute the mapping
    for idx = 1 : 256
        [~,ind] = min(abs(cdfCurrent(idx) - cdfRef));
        M(idx) = ind-1;
    end

    % Now apply the mapping to get current image to make
    % the image look like the distribution of the reference image
    matchedImages{imageNumber} = M(double(imageCurrent)+1);
    imshow(matchedImages{imageNumber})
    imsave
    %figure; imshow(matchedImages{imageNumber});
end
