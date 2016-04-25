% K Means thresholding 
i = imread('imageHM_1.jpg');
v = i(:);
v = single(v);
c = kmeans(v,2);
c1 = v(c==1);
c2 = v(c==2);
if (mean(c1) < mean(c2))
    mean1 = mean(c1)/255;
    mean2 = mean(c2)/255;
else
    mean1 = mean(c2)/255;
    mean2 = mean(c1)/255;
end 
I = imfill(i);
bw = im2bw(I, (0.85 * mean2 + 0.9 * mean1));
%bw = im2bw(I, (0.72));
se = strel('square',3);
open = imopen(bw,se);
imshowpair(bw, open,'montage')

% Eliminating the false positives
trueLabel = Label;
for i = 1:length(copyWin)
    x = floor(copyWin(i,1));
    y = floor(copyWin(i,2));
    if (Label(i) == 1 & open(x,y) == 0)
        trueLabel(i) = -1;
    end
end

% Plot the labels
diff = 5;
figure;
    imshow(image);
    hold on;
    for i = 1:length(Label)
        y = copyWin(i,1);
        x = copyWin(i,2);
        if (trueLabel(i) == -1)
            plot(x,y,'gd');
            hold on;
        else
            plot(x,y,'b*');
            hold on;
            blah1 = [y-diff y-diff y+diff y+diff];
            blah2 = [x-diff x+diff x+diff x-diff];
            patch(blah1,blah2,'red');
            hold on;
        end
    end
    
   
% Plot the rectangles around the interest points
for i = 1:length(copyWin)
    x = floor(copyWin(i,1));
    y = floor(copyWin(i,2));
    diff = 5;
    blah1 = [x-diff x-diff x+diff x+diff];
    blah2 = [y-diff y+diff y+diff y-diff];
    patch(blah1,blah2,'red')
