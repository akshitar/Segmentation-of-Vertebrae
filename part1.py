"""import PIL
from PIL import Image
im = Image.open('/Users/Akshita/Documents/MATLAB/JPG IMAGES/image_24.jpg')
print(im)
print(im.format, im.size, im.mode)"""


from roipoly import roipoly
from PIL import Image
import pylab as pl
import numpy as np
from scipy.misc import toimage
from PIL import ImageEnhance
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from numpy import array, histogram, unique

from skimage import data, img_as_float
from skimage import exposure
# Define a function which takes an image, lets the user choose ROI and displays mean
def MeanROI(image):
    # show the image
    pl.imshow(image, interpolation='nearest', cmap="gray")
    pl.colorbar()
    pl.title('Select ROI from foreground')

    # let user draw first ROI
    ROI1 = roipoly(roicolor='r') #let user draw first ROI

    # show the image with the first ROI
    pl.imshow(image, interpolation='nearest', cmap="gray")
    pl.colorbar()
    ROI1.displayROI()
    pl.title('select ROI from background')
    ROI2 = roipoly(roicolor='b')
    pl.imshow(image, interpolation='nearest', cmap="gray")
    pl.colorbar()
    [x.displayROI() for x in [ROI1, ROI2]]
    [x.displayMean(image) for x in [ROI1, ROI2]]
    pl.title('The two ROIs')
    pl.show()
    meanFG,meanBG = [x.displayMean(image) for x in [ROI1, ROI2]]
    pl.close()
    return meanFG, meanBG

#def histEq():

# Calculate the class means for 5 images of Spine
spineImage_1 = array(Image.open('/Users/Akshita/Documents/MATLAB/JPG IMAGES/image_24.jpg'))
hist, bin_edges = histogram((spineImage_1.flatten()))
pl.plot(hist)
pl.show()
print(bin_edges)
"""FG_1,BG_1 = MeanROI(spineImage_1)
spineImage_2 = Image.open('/Users/Akshita/Documents/MATLAB/JPG IMAGES/image_5.jpg')
FG_2,BG_2 = MeanROI(spineImage_2)
spineImage_3 = Image.open('/Users/Akshita/Documents/MATLAB/JPG IMAGES/image_10.jpg')
FG_3,BG_3 = MeanROI(spineImage_3)
spineImage_4 = Image.open('/Users/Akshita/Documents/MATLAB/JPG IMAGES/image_18.jpg')
FG_4,BG_4 = MeanROI(spineImage_4)
spineImage_5 = Image.open('/Users/Akshita/Documents/MATLAB/JPG IMAGES/image_21.jpg')
FG_5,BG_5 = MeanROI(spineImage_5)
mean_FG = (FG_1 + FG_2 + FG_3 + FG_4 + FG_5) / 5
mean_BG = (BG_1 + BG_2 + BG_3 + BG_4 + BG_5) / 5
print ('The mean of x1:{0}, x2:{1}, x3:{2}, x4:{3}, x5:{4}'.format(FG_1,FG_2,FG_3,FG_4,FG_5))
print ('The mean of y1:{0}, y2:{1}, y3:{2}, y4:{3}, y5:{4}'.format(BG_1,BG_2,BG_3,BG_4,BG_5))
print("mean of foreground:{0}".format(mean_FG))
print("mean of background:{0}".format(mean_BG))



# Minimum distance to class means
image_1 = np.asarray(spineImage_1.convert('L'))
rows, columns = image_1.shape
segmented = [[0 for row in range(rows)] for column in range(columns)]
for i in range(0,rows):
    for j in range(0,columns):
        diff_FG = abs(image_1[i][j] - mean_FG)
        diff_BG = abs(image_1[i][j] - mean_BG)
        if (diff_FG < diff_BG):
            segmented[i][j] = 255

toimage(segmented).show()"""

