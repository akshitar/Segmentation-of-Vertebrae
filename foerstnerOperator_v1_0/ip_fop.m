function [win, corner, dot_point, noclass] = ip_fop(G,varargin)
% IP_FOP interest point extraction by Förstner/Gülch 1987
% 
% The following items are extracted out of an intensity image (with one
% channel):
% - optimal search windows for least-squares matching and accurate point
%   extraction
% - accurate junction (or corner) points
% - accurate circular points
%
% Calling examples:
% =================
% 
% [win, corner, dot_point, noclass] = ip_fop(img) - uses default values for all control parameters
%
% [win, corner, dot_point, noclass] = ip_fop(img, 'ParameterName',ParameterValue,...) 
%                                          - defines control parameters
%
% Input parameters:
% =================
% img : input intensity image (must have one channel)
%
% 'ParameterName',ParameterValue,... : 
%       List of control parameters and their
%       values. The following control parameters are available:
%       1.) Important parameters which should be set according to the input
%           image:
%
%           'DETECTION_METHOD' : method for detection of optimal windows for 
%                                for point detection:
%                                'foerstner': According to foerstner*87:fast
%                                'koethe'   : According to koethe03:edge
%                                default: DETECTION_METHOD = 'foerstner';
%
%           'SIGMA_N' : noise as standard deviation (constant for all image
%                       intensities)
%                       default: SIGMA_N = 2.5 [greyvalues]
%
%           'DERIVATIVE_FILTER' : convolution filter used for gradient
%                    'gaussian1d' : one-dimensional gaussian filter
%                    'gaussian2d' : two-dimensional gaussian filter
%                    default: 'gaussian2d'
%
%           'INTEGRATION_FILTER': convolution filter for integration 
%                    'gaussian'   : two-dimensional gaussian filter
%                    'box_filt'   : two-dimensional box filter
%                    default: 'box_filt'
%
%            'SIGMA_DERIVATIVE_FILTER': size of gradient filter (sigma)
%                    default SIGMA_DIFF=0.7 [pel]
%
%            'SIGMA_INTEGRATION_FILTER' : size of integration filter (sigma)
%                    for 'gaussian': standard deviation of gaussian 
%                    for 'box_filt': size of box filter, also given as standard deviation 
%                                    (sigma)
%                    default: SIGMA_INT=1.41*SIGMA_DIFF;
%
%            'VISUALIZATION' : 'on' - the results are displayed in a figure.
%                              'off' - no visualization
%
%            2.) Control parameters where defaults nearly always can be used
%                    (only to be set in very special situations)
%
%            'PRECISION_THRESHOLD' : threshold for point localization
%                    Only those points with precision less than this
%                    threshold are accepted
%                    default: PREC_THRESH  = 0.5 pixel
%
%            'ROUNDNESS_THRESHOLD' : threshold for roundness of an image window
%                    default: ROUNDN_THRESH=0.3;
%
%            'SIGNIFICANCE_LEVEL' : significance level for the
%                    classification of points into junction and circular points.
%                    default: ROUNDN_THRESH = 0.999;
%
% Output parameters:
% ==================
%
%           win     :  coordinates of window centers for optimal point
%                      detection (were integer values in the scaled image)
%                          win(i).r: row coordinate of the i-th point
%                          win(i).c: column coordinate of the i-th point
%
%           corner  :  coordinates of points classified as junction points
%                        corner(i).r   : row coordinate of the i-th junction (real number)
%                        corner(i).c   : column coorindate of the i-th junction (real number)
%                        corner(i).cov : covariance matrix (2x2) of i-th junction
%
%           dot_point: coordinates of points classified as circular points
%                        dot_point(i).r   : row coordinate of the i-th point (real number)
%                        dot_point(i).c   : column coorindate of the i-th point (real number)
%                        dot_point(i).cov : covariance matrix (2x2) of i-th point
%     
%           noclass  : window centers of unclassified points
%                        noclass(i).r     : row coordinate of the i-th point
%                        noclass(i).c     : column coordinate of the i-th point
%
%   WARNING for inconsistency when using a Gaussian kernel for integration: 
%      When a GAUSSIAN kernel was used for integration, classification
%      and precise localization is done in a rectangular window,
%      with equal weights of the observations.
%      To be consistent, estimation has to be done with gaussian
%      weighting of the observations, but this is not implemented yet.
%  
% 
% @author Marc Luxen, Department of Photogrammetry, Institute of Geodesy
%         and Geoinformation, University of Bonn, Germany
% @date 13.01.2005


CONTROL_PARAMETER = ip_fop_getControlParameters(varargin);

SIGMA_N          = CONTROL_PARAMETER.SIGMA_N;
DIFF_KERNEL      = CONTROL_PARAMETER.DIFF_KERNEL;
INT_KERNEL       = CONTROL_PARAMETER.INT_KERNEL;
SIGMA_DIFF       = CONTROL_PARAMETER.SIGMA_DIFF;
SIGMA_INT        = CONTROL_PARAMETER.SIGMA_INT;
PREC_THRESH      = CONTROL_PARAMETER.PREC_THRESH;
ROUNDN_THRESH    = CONTROL_PARAMETER.ROUNDN_THRESH;
ALPHA_CLASSI     = CONTROL_PARAMETER.ALPHA_CLASSI;
DETECTION_METHOD = CONTROL_PARAMETER.DETECTION_METHOD;
VISUALIZATION    = CONTROL_PARAMETER.VISUALIZATION;

% Obligatorischer Parameter: Radius für Nonmaximum-Unterdrückung:
% Abstand zweier Maxima entspricht der Fenstergröße eines
% Box-Filters mit der Weite SIGMA_INT
radius_NONMAXSUP = ceil( sqrt( 12 * SIGMA_INT^2 + 1) );

global g sigma_n

% Wurde ein Bild übergeben?
if (nargin>0)
    [rows_G, cols_G, chans] = size(G);
    image_type          = class(G); % Datentyp
    
    % Bildformat überprüfen    
    if chans==1
        % Falls ein einkanaliges Bild vorliegt, wird dieses unabhängig vom
        % Bildtyp in ein double-Bild konvertiert. Die Standardabweichung
        % des Rauschens wird entsprechend skaliert.    
        switch class(G)    
            case 'uint8'        
                g       = im2double(G);           
                sigma_n = SIGMA_N/255;     
            case 'uint16'        
                g       = im2double(G);        
                sigma_n = SIGMA_N/65535;       
            case 'logical'        
                g       = im2double(G);        
                sigma_n = SIGMA_N;       
            case 'double'        
                Gmin    = min(min(G));        
                Gmax    = max(max(G));                
                g       = ( G - Gmin ) / ( Gmax - Gmin );        
                sigma_n = SIGMA_N/(Gmax-Gmin);    
            otherwise             
                error(['ip_fop: Wrong image type. Images of class "logical", "double", "uint8" or "uint16" required!']);                
        end  % of switch
    else % chans=~=1
        error(['ip_fop: Wrong number of channels! Only images with one channel are accepted!']);
    end  % 
else  % nargin == 0      
    error('ip_fop: No image specified!');    
end %



% Bild mit Faktor 2 skalieren. (Vorschlag von U. Köthe, DAGM-Hauptpreis
% 2003) und Kontrollparameter auf vergroeßertes Bild anpassen:        
KOETHE_scale = 2;    
inv_squareOf_KOETHE_scale = 1.0 / ( KOETHE_scale ^2 );
g = imresize(g,KOETHE_scale,'bilinear');    

% Werte für Bildformat anpassen:
[rows, cols, chans] = size(g);
% Steuerparameter anpassen:
SIGMA_DIFF  = KOETHE_scale * SIGMA_DIFF;
SIGMA_INT   = KOETHE_scale * SIGMA_INT;
PREC_THRESH = KOETHE_scale * PREC_THRESH;
radius_NONMAXSUP = KOETHE_scale * radius_NONMAXSUP;

%%%% Differentiations-und Integrationskern aufbauen:
%% Differentiationskern
[Diff_r, Diff_c] = ip_fop_diff_kernel(DIFF_KERNEL, SIGMA_DIFF);

% Integrationskern
[Int, radius_INT] = ip_fop_int_kernel(INT_KERNEL, SIGMA_INT);

%%%% Gradient %%%%
r=1; c=2;
dg(:,:,r)=imfilter(g,Diff_r);
dg(:,:,c)=imfilter(g,Diff_c);

clear Diff_r Diff_c g

%%%% Quadratischer Gradient %%%%
rr=1; cc=2; rc=3;
gamma(:,:,rr:cc) = dg(:,:,r:c) .^2;
gamma(:,:,rc)    = dg(:,:,r) .* dg(:,:,c);
clear dg

%%%% Mittlerer quadratischer Gradient %%%%
mean_gamma = imfilter(gamma,Int);
 
% Spur und Determinante des mittleren quad. Gradienten
Spur = mean_gamma(:,:,rr) + mean_gamma(:,:,cc);
Det  = mean_gamma(:,:,rr) .* mean_gamma(:,:,cc) - mean_gamma(:,:,rc).^2;

% Gewichte
w = Det ./ (Spur + eps);

% Schwellwert für Punktgenauigkeit:
Tw=(sigma_n/PREC_THRESH)^2;  


%%%% Bestimmung der Fenstermitten %%%%
switch DETECTION_METHOD
    case 'foerstner'                       
        % Rundheit
        q = 4 * Det ./ ( Spur.^2 + eps) ;
        clear Spur Det
                      
        % Regionen, in denen Punkte liegen:
        candidate_regions = ((q>ROUNDN_THRESH).*(w>Tw)).*w;       
        clear q
        
        % Erste Nonmaximum-Unterdrückung, 3x3-Fenster
        weighted_window_centers    = imregionalmax( candidate_regions ) .* w;
        clear candidate_regions w         
  
    case 'koethe'
        %KOETHE 2:     
        clear Det
        tmp = sqrt( (mean_gamma(:,:,rr) - mean_gamma(:,:,cc)).^2 + 4*mean_gamma(:,:,rc).^2);
        
        mu2 = 0.5 * ( Spur  - tmp );
        clear tmp Spur
                
        % Erste Nonmaximum-Unterdrückung, 3x3-Fenster
        candidate_regions =  ((w>Tw)) .* mu2;
        clear w;
        
        weighted_window_centers  = imregionalmax( candidate_regions ) .* mu2;
        clear candidate_regions mu2
        
    otherwise
        error('ip_fop: This method for finding optimal windows is unknown to me');
end
[rWin cWin] = find(weighted_window_centers > 0);      

% Falls kein einziges Pixel die Bedingungen erfüllt, gibt imregionalmax
% aus, dass jedes Pixel ein lokales Maximum ist, so dass rWin und cWin
% sämtliche Pixel des Bildes enthalten. In diesem Fall müssen rWin und cWin
% zurückgesetzt werden.
if length(rWin) == (rows*cols)
    rWin=[];
    cWin=[];
end

% Zweite Nonmaximumunterdrückung: Randpixel und Nicht-Maxima ausschließen
win=[];

nonmax_window = -radius_NONMAXSUP:radius_NONMAXSUP;
border  = max([radius_INT, radius_NONMAXSUP])+1;
upperborder_r = rows-border;
upperborder_c = cols-border;

idx = find((rWin>border) .* (cWin>border) .* (rWin<upperborder_r) .* (cWin<upperborder_c));
rWin = rWin(idx);
cWin = cWin(idx);

for i=1:length(rWin)
    rW = rWin(i);
    cW = cWin(i);    
    compWin = weighted_window_centers( rW + nonmax_window, cW + nonmax_window);        
    if (weighted_window_centers(rW, cW) >= max(max(compWin))) 
        cent.r=rW;
        cent.c=cW;
        win =[win, cent];
    end    
end
clear weighted_window_centers rWin cWin


%%%%% Subpixelpositionen %%%%

switch INT_KERNEL
    case 'box_filt'
    case 'gaussian'
%   WARNING: 
%             '!INCONSISTENCY!: ',...
%             'Although a GAUSSIAN kernel was used for integration, classification',...
%             'and precise localization is done in a rectangular window, with ',...
%             'equal weights of the observations.',...            
%             'To be consistent, estimation has to be done with gaussian weighting',...
%             'of the observations, but this is not implemented yet.'...
%             ))
    otherwise 
        error('Das kann nicht vorkommen!');
end

% Für die Punktklassifikation und die Schätzung des optimalen Punktes wird
% unabhängig vom Integrationsfilter ein rechteckiges Fenster gewählt, in
% dem alle Gradienten gleich gewichtet werden. 
% Als Fenstergroesse wird dabei die Fenstergröße eines Box-Filters mit 
% der Filterweite SIGMA_INT gewählt. Die Breite eines Fensters ist dann 
%                n = sqrt(12*SIGMA_INT^2+1)
% Siehe Vorlesung BV (WS 2003/2004), S. 6-10
% Alternativ könnte man die Fensterbreite des Gaußfilters mit Filterweite 
% SIGMA_INT wählen, d.h.
%                n = 2 * alpha_fractile * SIGMA_INT +1,
% was zu einem größeren Fenster führen würde

radius_EST = ceil( sqrt( 12 * SIGMA_INT ^ 2 + 1 ) / 2 ) + 1;

% Anzahl der Pixel im Fenster:
N_EST      = ( 2 * radius_EST + 1 ) ^ 2;

% Redundanz der Schätzung im Klassifikationsfenster:
redundancy_EST = N_EST - 2;

% Fuer Test auf Ecke
T_crit_corner=finv(ALPHA_CLASSI, redundancy_EST, redundancy_EST);  
% Fuer Test auf Zirkulaer
T_crit_dot=finv(1-ALPHA_CLASSI, redundancy_EST, redundancy_EST);

% Anzahl von Eckpunkten und zirkulaeren Punkten
corner     = [];
dot_point  = [];
noclass    = [];

% Matrizen, die die Koordinaten der Pixelpositionen enthalten:
[dc dr]    = meshgrid(-radius_EST:radius_EST,-radius_EST:radius_EST);

% Für die Transformation der im skalierten Bild erhaltenen Koordinaten in
% Koordinaten des ursprünglichen Bildes:
% Transformation ist getrennt für r und c zu machen.
% x = a * x' + b

transf_ar = (1.0 - rows_G)/(1.0 - KOETHE_scale * rows_G);
transf_br = (1.0 - KOETHE_scale) * rows_G / (1.0 - KOETHE_scale * rows_G);

transf_ac = (1.0 - cols_G)/(1.0 - KOETHE_scale * cols_G);
transf_bc = (1.0 - KOETHE_scale) * cols_G / (1.0 - KOETHE_scale * cols_G);

% Abbildungsmatrix
transf_H = [transf_ar      0     ;
               0       transf_ac];
transf_v = [ transf_br;
             transf_bc];     
      
for k=1:length(win)   
    
    %    Gegeben: Fenstermittelpunkt
    rw = win(k).r;
    cw = win(k).c;    
    
    % Bildkoordinaten der Pixel im Fenster
    ri  = rw + dr;
    ci  = cw + dc;
    
    % PRÄZISE SCHÄTZUNG                            
    
    %    Entsprechenden Ausschnitt aus Gamma ausschneiden                        
    idx_r      = rw - radius_EST : rw + radius_EST;  
    idx_c      = cw - radius_EST : cw + radius_EST;  
                        
    gamma_rr = gamma(idx_r,idx_c,rr);
    gamma_cc = gamma(idx_r,idx_c,cc);
    gamma_rc = gamma(idx_r,idx_c,rc);                
    
    %     Normalgleichungssysteme für die beiden Modelle
    sum_gr_gr   = sum(sum(gamma_rr));
    sum_gc_gc   = sum(sum(gamma_cc));
    sum_gr_gc   = sum(sum(gamma_rc));        
    
    sum_gr_gr_r = sum(sum( gamma_rr .* ri ));
    sum_gr_gr_c = sum(sum( gamma_rr .* ci ));            
    sum_gc_gc_r = sum(sum( gamma_cc .* ri ));
    sum_gc_gc_c = sum(sum( gamma_cc .* ci ));            
    sum_gr_gc_r = sum(sum( gamma_rc .* ri ));
    sum_gr_gc_c = sum(sum( gamma_rc .* ci ));
    
    % Ecken: 
    %| r_e |    | sum_i (g_r^2)       sum_i (g_r * g_c) |^(-1)   | sum_i (g_r^2 * r) + sum_i (g_r * g_c * c)|
    %|     | =  |                                       |      * |                                          |
    %| c_e |    |sum_i (g_r * g_c)    sum_i (g_c^2)     |        | sum_i (g_c^2 * c) + sum_i (g_r * g_c * r)|
    
    corner_N     = [  sum_gr_gr ,  sum_gr_gc ;  sum_gr_gc, sum_gc_gc ];
    corner_l     = [ sum_gr_gr_r + sum_gr_gc_c;  sum_gr_gc_r + sum_gc_gc_c];
    corner_N_inv = inv( corner_N );
    corner_est   = corner_N_inv * corner_l;
    
    % Zirkuläre Punkte
    %| r_c |    | sum_i (g_c^2)      -sum_i (g_r * g_c) |^(-1)   | sum_i (g_c^2 * r) - sum_i (g_r * g_c * c)|
    %|     | =  |                                       |      * |                                          |
    %| c_c |    |-sum_i (g_r * g_c)   sum_i (g_r^2)     |        | sum_i (g_r^2 * c) - sum_i (g_r * g_c * r)|
            
    dot_N      = [  sum_gc_gc , -sum_gr_gc ; -sum_gr_gc, sum_gr_gr ];
    dot_l      = [ sum_gc_gc_r - sum_gr_gc_c; -sum_gr_gc_r + sum_gr_gr_c];
    dot_N_inv  = inv( dot_N );
    dot_est    = dot_N_inv * dot_l;
    
    %% KLASSIFIKATION 
    
    %   Residuen der Beobachtungen in den beiden Modellen
    corner_residuals_r  = ri - corner_est(1);
    corner_residuals_c  = ci - corner_est(2);                        
            
    dot_residuals_r     = ri - dot_est(1);
    dot_residuals_c     = ci - dot_est(2);
            
    corner_residuals_rr = corner_residuals_r .^ 2;
    corner_residuals_rc = corner_residuals_r .* corner_residuals_c;
    corner_residuals_cc = corner_residuals_c .^ 2;
            
    dot_residuals_rr = dot_residuals_r .^ 2;
    dot_residuals_rc = dot_residuals_r .* dot_residuals_c;
    dot_residuals_cc = dot_residuals_c .^ 2;
       
    %  Quadratsummen der mit Gamma gewichteten Residuen in den beiden Modellen:            
    corner_Omega = sum(sum( gamma_rr .* corner_residuals_rr + 2 * gamma_rc .* corner_residuals_rc + gamma_cc .* corner_residuals_cc ));
    dot_Omega    = sum(sum( gamma_cc .* dot_residuals_rr    - 2 * gamma_rc .* corner_residuals_rc + gamma_rr .* corner_residuals_cc ));
   
    %  Entscheiden ob Ecke oder Zirkulaerer Punkt
    %  Testgroesse
    T = corner_Omega/dot_Omega;

    pointClass = (T<T_crit_corner) - (T>T_crit_dot); % liefert 1 Für Ecke, -1 für Kreis, 0 sonst
   
    %%%% ENDE der Klassifikation
       
    switch pointClass    
        case 1 % Ecke                                
            % Nach Punktextraktion die Skalierung wieder aufheben:
            tmp            = (transf_H * corner_est + transf_v)';
            new_point.r    = tmp(1);
            new_point.c    = tmp(2);
            
            new_point.cov  = corner_Omega/redundancy_EST * corner_N_inv;                     
            new_point.cov  = transf_H * new_point.cov * transf_H';
            
            corner = [corner, new_point];               
                            
        case -1 % Zirk. Punkt                  
            tmp            = (transf_H * dot_est + transf_v)';  
            new_point.r    = tmp(1);
            new_point.c    = tmp(2);         
            new_point.cov  = dot_Omega / redundancy_EST * dot_N_inv;                     
            new_point.cov  = transf_H * new_point.cov * transf_H';                    
            
            dot_point = [dot_point, new_point];               
        
        otherwise % weder Ecke noch zirkulärer Punkt   
            noclass = [noclass, win(k)];                       
    end  
    tmp = (transf_H * [win(k).r; win(k).c] + transf_v)';
    win(k).r = tmp(1);
    win(k).c = tmp(2);     
end;

% Für visualisierung Skalierung rückgängig machen
radius_EST = radius_EST/KOETHE_scale;

%%% Visualisierung
if strcmp(VISUALIZATION,'on')
    figure
    imshow(G)
    hold on        
    % Fenstermitten     
    % Visualisierung : r und c vertauschen.            
    plot([win.c], [win.r], 'r+', 'MarkerSize', 10);                
    % Fenster:         
    for t=1:length(win)                    
        rw=win(t).c;       
        cw=win(t).r;
        line([rw-radius_EST, rw+radius_EST],[cw-radius_EST,cw-radius_EST],'Color','red');           
        line([rw-radius_EST, rw+radius_EST],[cw+radius_EST,cw+radius_EST],'Color','red');           
        line([rw-radius_EST, rw-radius_EST],[cw-radius_EST,cw+radius_EST],'Color','red');           
        line([rw+radius_EST, rw+radius_EST],[cw-radius_EST,cw+radius_EST],'Color','red');                       
    end    
   
    
        % Falls vorhanden, Eckpunkte anzeigen
        if length(corner)>0    
            plot([corner.c],[corner.r],'bx', 'MarkerSize',8);    
        
            % Fehlerellipsen plotten
            for i=1:length(corner)                
                %% Man BEACHTE den FAKTOR 100...
                [xell yell]=ip_errell(corner(i).r, corner(i).c, 100*corner(i).cov);            
                plot(yell, xell,'b-');
            end;
        end    
    
    % Falls vorhanden, zirkuläre Punkte anzeigen
         if length(dot_point)>0
             plot([dot_point.c],[dot_point.r],'yx', 'MarkerSize',8);  
            % Fehlerellipsen plotten            
            for i=1:length(dot_point)                
                %% Man BEACHTE den FAKTOR 100...
                [xell yell]=ip_errell(dot_point(i).r, dot_point(i).c, 100*dot_point(i).cov);            
                plot(yell, xell,'y-');
            end;
        end;

        % Falls vorhanden, nicht klassifizierte Punkte anzeigen
        if length(noclass)>0
            plot([noclass.c],[noclass.r], 'bs');    
        end       
    hold off
end   
return


% -----------------------------------------------------------
function P = ip_fop_getControlParameters(varargin)
% -----------------------------------------------------------

% Default-Parameter:
P.SIGMA_N          = 2;                   % Standardabweichung des konstanten Bildrauschens 
P.DIFF_KERNEL      = 'gaussian2d';        % Typ des Differentiationsfilters
P.INT_KERNEL       = 'box_filt';          % Typ des Integrationsfilters
P.SIGMA_DIFF       = 1.0;                 % Filterweite Differentiationsfilter
P.SIGMA_INT        = 1.41 * P.SIGMA_DIFF;   % Filterweite Integrationsfilter
P.PREC_THRESH      = 0.5;                 % Schwellwert fuer Lagefehler
P.ROUNDN_THRESH    = 0.3;                 % Rundheits-Schwellwert
P.ALPHA_CLASSI     = 0.999;               % Signifikanzniveau für Klassifikation
P.DETECTION_METHOD = 'foerstner';         % Methode, nach der der quadratische Gradient für die Fenstersuche ausgewertet wird.
P.VISUALIZATION    = 'off';               % Falls 'on', wird visualisiert.

for arg=1 : ( length(varargin{1}) -1 )
    name     = varargin{1}{arg};
    argument = varargin{1}{arg+1};
    if isstr(name)
        switch name                
            case 'SIGMA_N'                            
                if isnumeric(argument)            
                    P.SIGMA_N  = argument;                                    
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end            
            case 'DERIVATIVE_FILTER'
                if isstr(argument)            
                    P.DIFF_KERNEL       = argument;                    
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end                   
            case 'INTEGRATION_FILTER'
                if isstr(argument)            
                    P.INT_KERNEL        = argument;                    
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end               
            case 'SIGMA_DERIVATIVE_FILTER'
                if isnumeric(argument)            
                    P.SIGMA_DIFF        = argument;                    
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end         
            case 'SIGMA_INTEGRATION_FILTER'
                if isnumeric(argument)            
                    P.SIGMA_INT         = argument;                    
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end        
            case 'PRECISION_THRESHOLD'
                if isnumeric(argument)            
                    P.PREC_THRESH       = argument;                    
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end        
            case 'ROUNDNESS_THRESHOLD'
                if isnumeric(argument)            
                    P.ROUNDN_THRESH        = argument;                    
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end        
            case 'SIGNIFICANCE_LEVEL'
                if isnumeric(argument)            
                    P.ALPHA_CLASSI       = argument;                    
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end        
            case 'DETECTION_METHOD'           
                if isstr(argument)                          
                    P.DETECTION_METHOD       = argument;
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end  
            case 'VISUALIZATION'
                if isstr(argument)                          
                    P.VISUALIZATION      = argument;
                    arg = arg + 1;
                else
                    warning(['Parameter ',name, ' not properly specified! Default Parameter is used.']);                
                end  
            case {'gaussian1d','gaussian2d', 'gaussian','box_filt', 'foerstner', 'koethe', 'on', 'off'}                
            otherwise
                warning(['Parameter ',name, ' is not known!']);    
        end             
    end 
end

return


function [Diff_r, Diff_c] = ip_fop_diff_kernel(DIFF_KERNEL, SIGMA_DIFF)
%%%% Differentiationskern aufbauen:

%%%% Fenstergroesse %%%%
% alpha: Flaeche unter der Gaussfunktion
%        auf dem durch das Fenster definierten Bereich.
% alpha = 0.999;
% alpha_fractile*sigma: Halbe Breite des Filters.
alpha_fractile = 3.3; %=norminv(1-(1-alpha)/2);

switch DIFF_KERNEL
    case 'gaussian1d'
        % 1.) Gausssche Differentiationskerne eindimensional: 
        %     Ableitungen der eindimensionalen Gaussfunktion
        radius = ceil(alpha_fractile*SIGMA_DIFF); % Halbe Fensterbreite des Kerns
        x      = -radius:radius;
        
        Diff_c=1/(sqrt(2*pi) * SIGMA_DIFF^3) * x .* exp(- x.^2 ./ (2 * SIGMA_DIFF^2) );    
        Diff_r=Diff_c';
    case 'gaussian2d'
        % 2.) Gausssche Differentiationskerne zweidimensional: 
        %     Eindimensionalen Gauß-Ableitungskerne werden nochmal senkrecht 
        %     zur Differentiationsrichtung mit einem Gaussfilter der gleichen 
        %     Filterweite geglaettet.  
        radius = ceil(alpha_fractile*SIGMA_DIFF);
        x      = -radius:radius;

        Diff_c = 1/(sqrt(2*pi) * SIGMA_DIFF^3) * x .* exp(- x.^2 ./ (2 * SIGMA_DIFF^2) ); 
        Diff_c = conv2(Diff_c, fspecial('gaussian',[length(x) 1],SIGMA_DIFF));
        Diff_r=Diff_c';   
    otherwise
        error('The selected gradient filter is not implemented yet!');    
end
return

    

    
    
function [Int, radius_INT] = ip_fop_int_kernel(INT_KERNEL, SIGMA_INT)
    
% Integrationskern
alpha_fractile = 3.3;
switch INT_KERNEL
    case 'gaussian'     
        % 1.) Gausscher Integrationskern
        %     Radius, d.i. die Halbe Fensterbreite des Integrationskerns
        radius_INT = ceil( alpha_fractile * SIGMA_INT );
        %     Fenster geht von -radius_INT bis +radius_INT
        %     Das sind 2*radius_INT+1 Pixel
        Int        = fspecial('gaussian', 2 * radius_INT + 1 , SIGMA_INT);  
    case 'box_filt'
        % 2.) Box-Filter
        % Die Fenstergröße des Box-Filters wird so gewählt, dass SIGMA_INT
        % die Weite des Box-Filters, d.h. seine Standardabweichung angibt.
        radius_INT = ceil( sqrt(12*SIGMA_INT^2+1)/2 );
        Int        = fspecial('average',2*radius_INT+1);
    otherwise
        error('The selected integration filter is not implemented yet!');
end

return





