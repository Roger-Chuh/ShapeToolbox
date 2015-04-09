function cylinder = objMakeCylinderBumpy(prm,varargin)

% OBJMAKECYLINDERBUMPY
% 
% Usage:          objMakeCylinderBumpy()

% Copyright (C) 2014, 2015 Toni Saarela
% 2014-10-19 - ts - first version
% 2015-04-03 - ts - calls the new objSaveModelCylinder-function to
%                    compute faces, normals, etc and save the model to a file
%                   saving the model is optional, an existing model
%                     can be updated


% TODO
% - return the locations of bumps
% - write help
%

%--------------------------------------------

if ~nargin || isempty(prm)
  prm = [20 .1 pi/12];
end

[nbumptypes,ncol] = size(prm);

switch ncol
  case 1
    prm = [prm ones(nccomp,1)*[.05 pi/12]];
  case 2
    prm = [prm ones(nccomp,1)*pi/12];
end

nbumps = sum(prm(:,1));

% Set default values before parsing the optional input arguments.
filename = 'cylinderbumpy.obj';
mtlfilename = '';
mtlname = '';
mindist = 0;
m = 256;
n = 256;
comp_normals = false;
dosave = true;
new_model = true;

[tmp,par] = parseparams(varargin);
if ~isempty(par)
  ii = 1;
  while ii<=length(par)
    if ischar(par{ii})
      switch lower(par{ii})
        case 'mindist'
          if ii<length(par) && isnumeric(par{ii+1})
             ii = ii+1;
             mindist = par{ii};
          else
             error('No value or a bad value given for option ''mindist''.');
          end
         case 'npoints'
           if ii<length(par) && isnumeric(par{ii+1}) && length(par{ii+1}(:))==2
             ii = ii + 1;
             m = par{ii}(1);
             n = par{ii}(2);
           else
             error('No value or a bad value given for option ''npoints''.');
           end
         case 'material'
           if ii<length(par) && iscell(par{ii+1}) && length(par{ii+1})==2
             ii = ii + 1;
             mtlfilename = par{ii}{1};
             mtlname = par{ii}{2};
           else
             error('No value or a bad value given for option ''material''.');
           end
         case 'normals'
           if ii<length(par) && isscalar(par{ii+1})
             ii = ii + 1;
             comp_normals = par{ii};
           else
             error('No value or a bad value given for option ''normals''.');
           end
         case 'save'
           if ii<length(par) && isscalar(par{ii+1})
             ii = ii + 1;
             dosave = par{ii};
           else
             error('No value or a bad value given for option ''save''.');
           end
         case 'model'
           if ii<length(par) && isstruct(par{ii+1})
             ii = ii + 1;
             cylinder = par{ii};
             new_model = false;
           else
             error('No value or a bad value given for option ''model''.');
           end
        otherwise
          filename = par{ii};
      end
    else
        
    end
    ii = ii + 1;
  end % while over par
end

if isempty(regexp(filename,'\.obj$'))
  filename = [filename,'.obj'];
end

%--------------------------------------------
% TODO:
% Throw an error if the asked minimum distance is a ridiculously large
% number.
%if mindist>
%  error('Yeah right.');
%end
%--------------------------------------------

if new_model
  r = 1; % radius
  h = 2*pi*r; % height
  theta = linspace(-pi,pi-2*pi/n,n); % azimuth
  y = linspace(-h/2,h/2,m); % 
  
  [Theta,Y] = meshgrid(theta,y);
  Theta = Theta'; Theta = Theta(:);
  Y = Y'; Y = Y(:);
  R = r * ones([m*n,1]);
else
  m = cylinder.m;
  n = cylinder.n;

  r = 1; % radius
  h = 2*pi*r; % height
  theta = linspace(-pi,pi-2*pi/n,n); % azimuth
  y = linspace(-h/2,h/2,m); % 

  Theta = cylinder.Theta;
  Y = cylinder.Y;
  R = cylinder.R;
end

for jj = 1:nbumptypes
    
  if mindist
     
    % Pick candidate locations (more than needed):
    nvec = 30*prm(jj,1);
    thetatmp = min(theta) + rand([nvec 1])*(max(theta)-min(theta));
    ytmp = min(y) + rand([nvec 1])*(max(y)-min(y));

    %d = sqrt((thetatmp*ones([1 nvec])-ones([nvec 1])*thetatmp').^2 + ...
    %         (ytmp*ones([1 nvec])-ones([nvec 1])*ytmp').^2);
    
    d = sqrt(wrapAnglePi(thetatmp*ones([1 nvec])-ones([nvec 1])*thetatmp').^2 + ...
             (ytmp*ones([1 nvec])-ones([nvec 1])*ytmp').^2);

    % Always accept the first vector
    idx_accepted = [1];
    n_accepted = 1;
    % Loop over the remaining candidate vectors and keep the ones that
    % are at least the minimum distance away from those already
    % accepted.
    idx = 2;
    while idx <= size(thetatmp,1)
      if all(d(idx_accepted,idx)>=mindist)
         idx_accepted = [idx_accepted idx];
         n_accepted = n_accepted + 1;
      end
      if n_accepted==prm(jj,1)
        break
      end
      idx = idx + 1;
    end

    if n_accepted<prm(jj,1)
       error(sprintf('Could not find enough vectors to satisfy the minumum distance criterion.\nConsider reducing the value of ''mindist''.'));
    end

    theta0 = thetatmp(idx_accepted,:);
    y0 = ytmp(idx_accepted,:);

  else
    %- pick n random locations
    theta0 = min(theta) + rand([prm(jj,1) 1])*(max(theta)-min(theta));
    y0 = min(y) + rand([prm(jj,1) 1])*(max(y)-min(y));

  end
    
  clear thetatmp ytmp

  %-------------------
    
  for ii = 1:prm(jj,1)
    % See comment in objMakeCylinderCustom
    deltatheta = abs(wrapAnglePi(Theta - theta0(ii)));
    deltax = deltatheta;% * r;
    
    deltay = Y - y0(ii);
    d = sqrt(deltax.^2+deltay.^2);
    
    idx = find(d<3.5*prm(jj,3));
    R(idx) = R(idx) + prm(jj,2)*exp(-d(idx).^2/(2*prm(jj,3)^2));      
    
  end
  
end

X = R .* cos(Theta);
Z = -R .* sin(Theta);
vertices = [X Y Z];

if new_model
  cylinder.prm.prm = prm;
  cylinder.prm.bumptypes = nbumptypes;
  cylinder.prm.nbumps = nbumps;
  cylinder.prm.mfilename = mfilename;
  cylinder.normals = [];
else
  ii = length(cylinder.prm)+1;
  cylinder.prm(ii).prm = prm;
  cylinder.prm(ii).bumptypes = nbumptypes;
  cylinder.prm(ii).nbumps = nbumps;
  cylinder.prm(ii).mfilename = mfilename;
  cylinder.normals = [];
end
cylinder.shape = 'cylinder';
cylinder.filename = filename;
cylinder.mtlfilename = mtlfilename;
cylinder.mtlname = mtlname;
cylinder.comp_normals = comp_normals;
cylinder.n = n;
cylinder.m = m;
cylinder.Theta = Theta;
cylinder.Y = Y;
cylinder.R = R;
cylinder.vertices = vertices;

if dosave
  cylinder = objSaveModelCylinder(cylinder);
end

if ~nargout
   clear cylinder
end

%----------------------------------------------------

function theta = wrapAnglePi(theta)

% WRAPANGLEPI
%
% Usage: theta = wrapAnglePi(theta)

% Toni Saarela, 2010
% 2010-xx-xx - ts - first version

theta = rem(theta,2*pi);
theta(theta>pi) = -2*pi+theta(theta>pi);
theta(theta<-pi) = 2*pi+theta(theta<-pi);
%theta(X==0 & Y==0) = 0;

