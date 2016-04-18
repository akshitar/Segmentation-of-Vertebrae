      Interest Point Detector by Förstner/Gülch (Förstner-Operator)
      =============================================================

This package implements the Förstner interest point detector in Matlab. The
algorithm extracts junction and circular points from a greyvalue image with 
subpixel accuracy. It also includes some extensions proposed by Köthe (2003).

Usage:
------
- The operator is implemented in the function ip_fop.m.
- See ip_fop_example.m for an example of calling the function. 
- To use the original criteria of Förstner, set DETECTION_METHOD='foerstner',
  to use the apapted one by Koehte, set DETECTION_METHOD='koethe'. The
  image resolution will always be doubled internally, as proposed by Koethe.
- The input and output parameters are explained in detail in
  ip_fop.m.

Author:
-------
Marc Luxen
Department of Photogrammetry
Institute of Geodesy and Geoinformation
University of Bonn, Germany.

As the author is no longer a staff member of the Institute, please use the 
following contact address for questions:
Thomas Läbe
Department of Photogrammetry
Institute of Geodesy and Geoinformation
University of Bonn, Germany.
laebe@ipb.uni-bonn.de

For the software there is NO warranty; not even for merchantability 
or fitness for a particular purpose.


References:
-----------
Förstner, Wolfgang / Gülch, Eberhard:
A Fast Operator for Detection and Precise Location of Distict Point, 
Corners and Centres of Circular Features.
In: Proceedings of the ISPRS Conference on Fast Processing of Photogrammetric 
Data. Interlaken 1987, S. 281-305.


Ullrich Köthe:
Edge and Junction Detection with an Improved Structure Tensor.
In: Lecture Notes in Computer Science (Proceedings of DAGM 2003)
    Volume 2781, 2003, DOI: 10.1007/b12010, p. 25-32,
    Springer, Heidelberg.

