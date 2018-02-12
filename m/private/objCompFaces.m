function s = objCompFaces(s)

% OBJCOMPFACES
%
% Usage:    MODEL = objCompNormals(MODEL)

% Copyright (C) 2015 Toni Saarela
% 2015-10-12 - ts - first version, separated from objSaveModel
% 2016-05-27 - ts - added group handling for spheres et al.
% 2016-05-28 - ts - groups ok for all shapes
% 2017-11-22 - ts - experimental support for boxifying a plane
%                   correction to help
% 2018-02-09 - ts - added support for ellipsoid

%------------------------------------------------------------
  
m = s.m;
n = s.n;


switch s.shape
  case {'sphere'}
    s.faces = zeros((m-1)*n*2,3);
    F = ([1 1]'*[1:n]);
    F = F(:) * [1 1 1];
    F(:,2) = F(:,2) + [repmat([n+1 1]',[n-1 1]); [1 1-n]'];
    F(:,3) = F(:,3) + [repmat([n n+1]',[n-1 1]); [n 1]'];
    for ii = 1:m-1
      s.faces((ii-1)*n*2+1:ii*n*2,:) = (ii-1)*n + F;
    end
  case {'cylinder','revolution','extrusion','worm','ellipsoid'}
    if ~s.flags.thickwalls
      s.faces = zeros((m-1)*n*2,3);
    else
      s.faces = zeros(m*n*2,3);
    end
    F = ([1 1]'*[1:n]);
    F = F(:) * [1 1 1];
    F(:,2) = F(:,2) + [repmat([n+1 1]',[n-1 1]); [1 1-n]'];
    F(:,3) = F(:,3) + [repmat([n n+1]',[n-1 1]); [n 1]'];
    for ii = 1:m-1
      s.faces((ii-1)*n*2+1:ii*n*2,:) = (ii-1)*n + F;
    end
    
    if s.flags.thickwalls
      F = (m-1)*n + F;
      F(F>m*n) = F(F>m*n) - m*n;
      s.faces((m-1)*n*2+1:m*n*2,:) = F;
    end
    
  case {'plane','disk'}
    if ~s.flags.thickwalls
      s.faces = zeros((m-1)*(n-1)*2,3);
    else
      s.faces = zeros(m*(n-1)*2,3);
    end
    ftmp = [[1 1]'*[1:n-1]];
    F(:,1) = ftmp(:);
    % OR:
    %F(:,1) = ceil([1:(2*n-2)]'/2);
    ftmp = [n+2:2*n; 2:n];
    F(:,2) = ftmp(:);
    ftmp = [[1 1]' * [n+1:2*n]];
    ftmp = ftmp(:);
    F(:,3) = ftmp(2:end-1);    
    for ii = 1:m-1
      s.faces((ii-1)*(n-1)*2+1:ii*(n-1)*2,:) = (ii-1)*n + F;
    end

    if s.flags.thickwalls
      F = (m-1)*n + F;
      F(F>m*n) = F(F>m*n) - m*n;
            
      s.faces((m-1)*(n-1)*2+1:m*(n-1)*2,:) = F;
      
      % TODO: compute correct size above, now it doesn't include
      % the sides
      
      ftmp = [[1 1]'*[(m-1):-1:(m/2+1)]];
      F(:,1) = ftmp(:);
      ftmp = [1:(m/2-1); 0:(m/2-2)];
      F(:,2) = ftmp(:);
      ftmp = [(m-2):-1:(m/2); 1:(m/2-1)];
      F(:,3) = ftmp(:);
      s.faces = [s.faces; F*n+1];
      
      ftmp = [[1 1]'*[1:(m/2-1)]];
      F(:,1) = ftmp(:);
      ftmp = [(m-1):-1:(m/2+1); m:-1:(m/2+2)];
      F(:,2) = ftmp(:);
      ftmp = [2:(m/2); (m-1):-1:(m/2+1)];
      F(:,3) = ftmp(:);
      s.faces = [s.faces; F*n];
      
    end
    
    % if s.flags.caps
    %   s.faces = [s.faces; 1 n m*n; 1 m*n (m-1)*n+1];
    % end
    
  case 'torus'
    s.faces = zeros(m*n*2,3);
    % The first part is the same as with the sphere:
    F = ([1 1]'*[1:n]);
    F = F(:) * [1 1 1];
    F(:,2) = F(:,2) + [repmat([n+1 1]',[n-1 1]); [1 1-n]'];
    F(:,3) = F(:,3) + [repmat([n n+1]',[n-1 1]); [n 1]'];
    % But loop until m, not m-1 as phi goes -pi to pi here (not -pi/2 to
    % pi/2) and faces wrap around the "tube".
    for ii = 1:m
      s.faces((ii-1)*n*2+1:ii*n*2,:) = (ii-1)*n + F;
    end
    % Finally, to wrap around properly in the phi-direction:
    s.faces = 1 + mod(s.faces-1,m*n);
end

if isfield(s.group,'groups')
  [s.group.groups,idx] = sort(s.group.groups);
  s.faces = s.faces(idx,:);
end

