% IP_FOP_EXAMPLE Example program for Foerstner Interest Point Dector
% @author Marc Luxen
%         Department of Photogrammetry,
%         Institute for Geodesy and Geoinformation,
%         University of Bonn, Germany
%
% @date 08.01.2005
%       with changes from 10.03.2011
close all, clear all, clc;

%% Read input image 
g = imread('Quadrate.tif');

%% Call with default parameters
% [win, corner, circ, noclass] = ip_fop(g);

%% Call with other control parameters
disp('Calling ip_fop ...');
[win, corner, circ, noclass]=ip_fop( ...
    g,                                       ... intensity image (one channel, grey-level image)
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


%% Output:
disp('Results:');
% a) integer positions of window centers
disp('Positions of window centers (actually were integers in the internally scaled image):');
for i=1:length(win)
    fprintf('%5.1f   %5.1f\n',win(i).r,win(i).c);
end

% b) subpixel positions of corners with covariance matrix
disp('Subpixel positions of corners with covariance matrix');
for i=1:length(corner)
    r=corner(i).r
    c=corner(i).c
    cov=corner(i).cov
end

% c) subpixel positions of circular points with covariance matrix
disp('Subpixel positions of circular points with covariance matrix:');
for i=1:length(circ)
    r=circ(i).r
    c=circ(i).c
    cov=circ(i).cov
end

% d) window centers of points with could not be classified unambiguously  
disp('Window centers of points with could not be classified unambiguously:');
for i=1:length(noclass)
    r=noclass(i).r
    c=noclass(i).c    
end
