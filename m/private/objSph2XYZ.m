function [x,y,z] = objSph2XYZ(theta,phi,r,rtorus,super)

% OBJSPH2XYZ
%
% Usage: [x,y,z] = objSph2XYZ(theta,phi,r,[rtorus])
%        [x,y,z] = objSph2XYZ(spher_coords,[rtorus])
% Or:        xyz = objSph2XYZ(...)
%
% Spherical to cartesian coordinates.  Theta is the angle re positive
% y-axis.  Phi is the angle re x-z plane, and equals 0 when on that
% plane.  r is the radius.
% 
% With three input arguments, this is the traditional spherical
% coordinate conversion (y is "up").  With an additional fourth input
% argument (radius of a torus, distance from origin to center of
% tube), convert torus coordinates to cartesian.
%
% The input coordinates can be given as a matrix with each
% coordinate in a column.
  
% Copyright (C) 2015 Toni Saarela
% 2015-05-29 - ts - first version
% 2015-05-29 - ts - eats torus coordinates, too
% 2017-12-05 - ts - accepts matrix input, help updated
% 2018-02-09 - ts - added support for ellipsoid, superellipsoid, supertoroid

  if nargin == 1
    if size(theta,2)==3
      r = theta(:,3);
      phi = theta(:,2);
      theta = theta(:,1);
    elseif size(theta,2)==4
      rtorus = theta(:,4);
      r = theta(:,3);
      phi = theta(:,2);
      theta = theta(:,1);
    else
      error('The input matrix has to have 3 or 4 columns.');
    end
  elseif nargin == 2
    rtorus = phi;
    r = theta(:,3);
    phi = theta(:,2);
    theta = theta(:,1);    
  elseif nargin == 3
    rtorus = 0;
    %elseif nargin ~= 4 
    %error('Invalid number of input args.');
  end
  
  if isempty(rtorus)
    rtorus = 0;
  end

  if size(rtorus,2)==1
    rtorus = rtorus * [1 1];
  end
  
  if size(r,2)==1
    r = r * [1 1 1];
  end

  if nargin>4 && any(super~=1)
    s = @(x,n) sign(sin(x)).*abs(sin(x)).^n;
    c = @(x,n) sign(cos(x)).*abs(cos(x)).^n;    

    y =                 r(:,2) .* s(phi,super(1));
    x =  (rtorus(:,1) + r(:,1) .* c(phi,super(1))) .* c(theta,super(2));
    z = -(rtorus(:,2) + r(:,3) .* c(phi,super(1))) .* s(theta,super(2));
    
    % rp =  rtorus + r .* c(phi,super(1));
    % y =   r .* s(phi,super(1));
    % x =  rp .* c(theta,super(2));
    % z = -rp .* s(theta,super(2));
  else
    y =                 r(:,2) .* sin(phi);
    x =  (rtorus(:,1) + r(:,1) .* cos(phi)) .* cos(theta);
    z = -(rtorus(:,2) + r(:,3) .* cos(phi)) .* sin(theta);
    
    % rp =  rtorus + r .* cos(phi);
    % y =   r .* sin(phi);
    % x =  rp .* cos(theta);
    % z = -rp .* sin(theta);
  end
  
  if ~nargout || nargout==1
    x = [x,y,z];
  end

end
