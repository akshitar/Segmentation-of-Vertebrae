# Segmentation-of-Vertebrae

STEP 1: Consider only the object and find interest points, collecting patches around those interest points

STEP 2: Use hierarchical agglomerative clustering and form clusters. Use these clusters to form feature id's(i.e: these are our features now) according to the cluster they lie in.

STEP 3: Design a classifier:
      
      a) Take object(lumbars) and non-object(background) patches. Assign each patch a feature-id as per the nearest or most           similar centroid.
      b) Now take the feature id's of all the patches(lumbars and background) and the pre-defined labels to design a                  classifier.
      
STEP 4: Testing:
      
      Slide a window across the image; input the patch to the classifier; observe the assigned label and segment it by giving       it color.
