function plane = objMakePlaneBumpy(prm,varargin)

% OBJMAKEPLANEBUMPY
%
% Usage:          objMakePlaneBumpy()
%                 objMakePlaneBumpy(PAR,[OPTIONS])
%        PLANE = objMakePlaneBumpy(...)
%
% A 3D model plane perturbed in the z-direction by Gaussian
% 'bumps'.  The input vector defines the number of bumps and their
% amplitude and spread:
%   PAR = [NBUMPS AMPL SD]
% 
% The width of the plane is 1.  The bumbs are added to the plane so
% that they modulate the plane in the z-direction with amplitude AMPL.
% So an amplitude of 0.1 means a bump height that is 10% of the plane 
% width.  The amplitude can be negative to produce dents. The spread 
% (standard deviation) of the bumps is given by SD.
%
% To have a mix of different types of bump in the same plane, define 
% several sets of parameters in the rows of PAR:
%   PAR = [NBUMPS1 AMPL1 SD1
%          NBUMPS2 AMPL2 SD2
%          ...
%          NBUMPSN AMPLN SDN]
%
% Options:
% 
% By default, saves the object in planebumpy.obj.  To save in a
% different file, define the output file name as a string:
%   > objMakePlaneBumpy(...,'newfilename',...)
%
% Other optional arguments are key-value pairs.  To set the minimum
% distance between the bumps, use:
%  > objMakePlaneBumpy(...,'mindist',DMIN)
%
% The default number of vertices is 256x256.  To define a different
% number of vertices:
%   > objMakePlaneBumpy(...,'npoints',[N M],...)
%
% To turn on the computation of surface normals (which will increase
% coputation time):
%   > objMakePlaneBumpy(...,'NORMALS',true,...)
%
% For texture mapping, see help to objMakeSphere or online help.
%
% Note: The minimum distance between bumps only applies to bumps of
% the same type.  If several types of bumps are defined (in rows of
% the imput argument prm), different types of bumps might be closer
% together than mindist.  This might change in the future.
%

% Examples:
% TODO

% Copyright (C) 2014,2015 Toni Saarela

% 2014-10-17 - ts - first version
% 2015-03-05 - ts - fixed computation of faces (they were defined CW,
%                    should be CCW.  oops.)
%                   added vertex normals; better writing of specs in comments
% 2015-04-03 - ts - calls the new objSaveModelPlane-function to
%                    compute faces, normals, etc and save the model to a file
%                   saving the model is optional, an existing model
%                     can be updated

%--------------------------------------------

if ~nargin || isempty(prm)
  prm = [20 .05 .05];
end

[nbumptypes,ncol] = size(prm);

switch ncol
  case 1
    prm = [prm ones(nccomp,1)*[.05 .05]];
  case 2
    prm = [prm ones(nccomp,1)*.05];
end

nbumps = sum(prm(:,1));

% Set default values before parsing the optional input arguments.
filename = 'planebumpy.obj';
mtlfilename = '';
mtlname = '';
mindist = 0;
comp_normals = false;
dosave = true;
new_model = true;

% Number of vertices in y and x directions, default values
m = 256;
n = 256;

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
           if ii<length(par) && (isnumeric(par{ii+1}) || islogical(par{ii+1}))
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
             plane = par{ii};
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
  w = 1; % width of the plane
  h = 1; % m/n * w;
  
  x = linspace(-w/2,w/2,n); % 
  y = linspace(-h/2,h/2,m)'; % 

  [X,Y] = meshgrid(x,y);
  X = X'; X = X(:);
  Y = Y'; Y = Y(:);
  Z = zeros(size(X));
else
  m = plane.m;
  n = plane.n;

  w = 1; % width of the plane
  h = m/n * w;
  x = linspace(-w/2,w/2,n); % 
  y = linspace(-h/2,h/2,m)'; % 

  X = plane.X;
  Y = plane.Y;
  Z = plane.Z;
end

for jj = 1:nbumptypes

  if mindist

    % Pick candidate locations (more than needed):
    nvec = 30*prm(jj,1);
    xtmp = min(x) + rand([nvec 1])*(max(x)-min(x));
    ytmp = min(y) + rand([nvec 1])*(max(y)-min(y));

    
    d = sqrt((xtmp*ones([1 nvec])-ones([nvec 1])*xtmp').^2 + (ytmp*ones([1 nvec])-ones([nvec 1])*ytmp').^2);

    % Always accept the first vector
    idx_accepted = [1];
    n_accepted = 1;
    % Loop over the remaining candidate vectors and keep the ones that
    % are at least the minimum distance away from those already
    % accepted.
    idx = 2;
    while idx <= size(xtmp,1)
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

    x0 = xtmp(idx_accepted,:);
    y0 = ytmp(idx_accepted,:);

  else
    %- pick n random locations
    x0 = min(x) + rand([prm(jj,1) 1])*(max(x)-min(x));
    y0 = min(y) + rand([prm(jj,1) 1])*(max(y)-min(y));

  end

  clear xtmp ytmp

  %-------------------
  
  for ii = 1:prm(jj,1)

    deltax = X - x0(ii);
    deltay = Y - y0(ii);
    d = sqrt(deltax.^2+deltay.^2);
    
    idx = find(d<3.5*prm(jj,3));
    Z(idx) = Z(idx) + prm(jj,2)*exp(-d(idx).^2/(2*prm(jj,3)^2));
  end

end

vertices = [X Y Z];

if new_model
  plane.prm.prm = prm;
  plane.prm.nbumptypes = nbumptypes;
  plane.prm.nbumps = nbumps;
  plane.prm.mfilename = mfilename;
  plane.normals = [];
else
  ii = length(plane.prm)+1;
  plane.prm(ii).prm = prm;
  plane.prm(ii).nbumptypes = nbumptypes;
  plane.prm(ii).nbumps = nbumps;
  plane.prm(ii).mfilename = mfilename;
  plane.normals = [];
end
plane.shape = 'plane';
plane.filename = filename;
plane.mtlfilename = mtlfilename;
plane.mtlname = mtlname;
plane.comp_normals = comp_normals;
plane.n = n;
plane.m = m;
plane.X = X;
plane.Y = Y;
plane.Z = Z;
plane.vertices = vertices;

if dosave
  plane = objSaveModelPlane(plane);
end

if ~nargout
   clear plane
end
