from roipoly import roipoly
import pylab as pl
import numpy as np
from scipy.misc import toimage
from numpy import *
from numpy import array, histogram, unique
from skimage import data, img_as_float, exposure
from skimage.color import rgb2gray
import numpy as np
import dicom
import skimage
from skimage import io
from PIL import Image,ImageChops, ImageEnhance

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

"""def histEq(im,nbr_bins=256):

    #get image histogram
    imhist,bins = histogram(im.flatten(),nbr_bins,normed=True)
    cdf = imhist.cumsum() #cumulative distribution function
    cdf = 255 * cdf / cdf[-1] #normalize
    #use linear interpolation of cdf to find new pixel values
    im2 = interp(im.flatten(),bins[:-1],cdf)
    return im2.reshape(im.shape), cdf
"""
# Calculate the class means for 5 images of Spine
spineImage_1 = Image.open('/Users/Akshita/Documents/MATLAB/JPG_IMAGES/image_24.jpg')
FG_1,BG_1 = MeanROI(spineImage_1)
spineImage_2 = Image.open('/Users/Akshita/Documents/MATLAB/JPG_IMAGES/image_5.jpg')
FG_2,BG_2 = MeanROI(spineImage_2)
spineImage_3 = Image.open('/Users/Akshita/Documents/MATLAB/JPG_IMAGES/image_10.jpg')
FG_3,BG_3 = MeanROI(spineImage_3)
spineImage_4 = Image.open('/Users/Akshita/Documents/MATLAB/JPG_IMAGES/image_18.jpg')
FG_4,BG_4 = MeanROI(spineImage_4)
spineImage_5 = Image.open('/Users/Akshita/Documents/MATLAB/JPG_IMAGES/image_21.jpg')
FG_5,BG_5 = MeanROI(spineImage_5)
mean_FG = (FG_1 + FG_2 + FG_3 + FG_4 + FG_5) / 5
mean_BG = (BG_1 + BG_2 + BG_3 + BG_4 + BG_5) / 5
print ('The mean of x1:{0}, x2:{1}, x3:{2}, x4:{3}, x5:{4}'.format(FG_1,FG_2,FG_3,FG_4,FG_5))
print ('The mean of y1:{0}, y2:{1}, y3:{2}, y4:{3}, y5:{4}'.format(BG_1,BG_2,BG_3,BG_4,BG_5))
print("mean of foreground:{0}".format(mean_FG))
print("mean of background:{0}".format(mean_BG))


np.set_printoptions(precision=5, threshold=np.inf)
img = skimage.io.imread('/Users/Akshita/Documents/MATLAB/JPG_IMAGES/image_24.jpg')
img = np.matrix(img)
i=0
j=0
labels =[]
centerPix =[]
for i in range(0,511,3):
    for j in range(0,511,3):
        a = img[i:i+3,j:j+3]
        center = a[1,1]
        diff_FG = abs(center - mean_FG)
        diff_BG = abs(center - mean_BG)
        centerPix.append(center)
        if (diff_FG < (diff_BG-40)):
            labels.append(1)
        else:
            labels.append(0)

print((labels==1).sum)
#print(centerPix)
"""img_gray = rgb2gray(img)
plt.imshow(img_gray, cmap ='gray')
print(img_gray.shape)
l = list(range(0,img_gray.shape[0]))
print(img_gray[l].shape)
im = Image.open('/Users/Akshita/Desktop/Project images/image24_BW.jpg')
bg = Image.new(im.mode,im.size,im.getpixel((0,0)))
diff = ImageChops.difference(im,bg)
diff = ImageChops.add(diff, diff, 2.00, -100)

bbox = diff.getbbox()
im = im.crop(bbox)
im.show()"""

