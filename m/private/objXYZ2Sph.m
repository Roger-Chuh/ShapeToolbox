function [theta,phi,r] = objXYZ2Sph(x,y,z)

% OBJXYZ2SPH
%  
% [theta,phi,r] = objXYZ2Sph(x,y,z)
% [theta,phi,r] = objXYZ2Sph(xyz)
% spher_coords  = objXYZ2Sph(...)
  
% Copyright (C) 2017 Toni Saarela
% 2017-12-05 - ts - written
  
  if nargin == 1
    z = x(:,3);
    y = x(:,2);
    x = x(:,1);
  end
  
  r = sqrt(x.^2+y.^2+z.^2);
  theta = atan2(-z,x);
  phi = asin(y./r);
  
  if nargout<2
    theta = [theta phi r];
  end

end
