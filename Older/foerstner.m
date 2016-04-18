function [x,q] = foerstner(ima,win,cmd)
% FORSTNER    Forstner corner finder (interest operator)
%
%      [x, q] = forstner(ima,win,cmd)
%
%      x - coordinates of corner
%		 q - condition number and gradient magnitude
%      ima  - image
%      win  - x_min, x_max, y_min, y_max of subimage where the search is started
%		cmd - command string: 'corner' is default, also 'circle'
%

% (c) Pietro Perona
%    Apr 26, 1999


x1 = win(1); x2 = win(2); y1 = win(3); y2 = win(4);

subima = ima(y1:y2,x1:x2);
figure(3); clf; imagesc(subima); colormap(gray);

[rr,cc] = size(subima);
AA = rr*cc;
[X,Y] = meshgrid(2:cc-1,2:rr-1);

ima_x = conv2(subima,[1 0 -1],'valid'); ima_x = ima_x(2:rr-1,:);
ima_y = conv2(subima,[1 0 -1]','valid'); ima_y = ima_y(:,2:cc-1);
if (nargin > 2) & (cmd == 'circle'),
   tmp = ima_x; ima_x = -ima_y; ima_y = tmp;
end;

Ix2 = ima_x.^2;
IxIy = ima_x .* ima_y;
Iy2 = ima_y.^2;

M11 = sum(sum(Ix2))/AA;
M12 = sum(sum(IxIy))/AA; M21 = M12;
M22 = sum(sum(Iy2))/AA;
M = [M11 M12; M21 M22];

c = cond(M);
gm = sqrt(M11+M22);
q = [c, gm];

if c > 20, fprintf(1,'Warning: high condition number =%f',c); end;
if gm < 10, fprintf(1,'Warning: low gradient magnitude =%f', gm); end;


V1 = sum(sum(Ix2 .* X + IxIy .* Y))/AA;
V2 = sum(sum(IxIy .* X + Iy2 .* Y))/AA;
V = [V1; V2];

x = inv(M) * V;
figure(3); hold on; plot(x(1), x(2), 'g.'); hold off

x = x + [x1-1; y1-1];

    
