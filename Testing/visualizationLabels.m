% Visualization of labels
load labelPredict.mat
load win.mat
testImage = imread('image_5.jpg');
totalPoints = length(labelPredict);
imshow(testImage)
hold on;
for index = 1:totalPoints
    xDim = floor(win(index,2)); % Column
    yDim = floor(win(index,1)); % Row
    if (labelPredict(index,1) == -1)
        plot(xDim,yDim,'ro');
        hold on;
    else
        plot(xDim,yDim,'g*');
        hold on;
    end
end
