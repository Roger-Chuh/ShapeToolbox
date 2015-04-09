function cylinder = objMakeCylinder(cprm,varargin)

% OBJMAKECYLINDER 
%

% Copyright (C) 2014, 2015 Toni Saarela
% 2014-10-10 - ts - first version
% 2014-10-19 - ts - switched to using an external function to compute
%                   the modulation
% 2014-10-20 - ts - added texture mapping
% 2015-01-16 - ts - fixed the call to renamed objMakeSineComponents
% 2015-04-03 - ts - calls the new objSaveModelCylinder-function to
%                    compute faces, normals, etc and save the model to a file
%                   saving the model is optional, an existing model
%                     can be updated


% TODO
% Add an option to define whether modulations are done in angle
% (theta) units or distance units.
% Add modulators
% More and better parsing of input arguments
% HEEEEEEEEEEEELLLLLLLLLLLPPPPPPPPPP

%--------------------------------------------

if ~nargin || isempty(cprm)
  cprm = [8 .1 0 0 0];
end

[nccomp,ncol] = size(cprm);

switch ncol
  case 1
    cprm = [cprm ones(nccomp,1)*[.1 0 0 0]];
  case 2
    cprm = [cprm zeros(nccomp,3)];
  case 3
    cprm = [cprm zeros(nccomp,2)];
  case 4
    cprm = [cprm zeros(nccomp,1)];
end

cprm(:,3:4) = pi * cprm(:,3:4)/180;

% Set the default modulation parameters to empty indicating no
% modulator; set default filename.
mprm  = [];
nmcomp = 0;
filename = 'cylinder.obj';
mtlfilename = '';
mtlname = '';
comp_normals = false;
dosave = true;
new_model = true;

% Number of vertices in the two directions
m = 256; 
n = 256;

[modpar,par] = parseparams(varargin);

% If modulator parameters are given as input, set mprm to these values
if ~isempty(modpar)
   mprm = modpar{1};
end

% Set default values to modulator parameters as needed
if ~isempty(mprm)
  [nmcomp,ncol] = size(mprm);
  switch ncol
    case 1
      mprm = [mprm ones(nccomp,1)*[1 0 0 0]];
    case 2
      mprm = [mprm zeros(nccomp,3)];
    case 3
      mprm = [mprm zeros(nccomp,2)];
    case 4
      mprm = [mprm zeros(nccomp,1)];
  end
  mprm(:,3:4) = pi * mprm(:,3:4)/180;
end

if ~isempty(par)
   ii = 1;
   while ii<=length(par)
     if ischar(par{ii})
       switch lower(par{ii})
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
     end
     ii = ii + 1;
   end
end
  
% Add file name extension if needed
if isempty(regexp(filename,'\.obj$'))
  filename = [filename,'.obj'];
end

%--------------------------------------------
% Vertices

if new_model
  r = 1; % radius
  h = 2*pi*r; % height
  theta = linspace(-pi,pi-2*pi/n,n); % azimuth
  y = linspace(-h/2,h/2,m); % 
  
  [Theta,Y] = meshgrid(theta,y);
  Theta = Theta'; Theta = Theta(:);
  Y = Y'; Y = Y(:);
else
  m = cylinder.m;
  n = cylinder.n;
  Theta = cylinder.Theta;
  Y = cylinder.Y;
  r = cylinder.R;
end

R = r + objMakeSineComponents(cprm,mprm,Theta,Y);;

% Convert vertices to cartesian coordinates
X =  R .* cos(Theta);
Z = -R .* sin(Theta);

vertices = [X Y Z];

if new_model
  cylinder.prm.cprm = cprm;
  cylinder.prm.mprm = mprm;
  cylinder.prm.nccomp = nccomp;
  cylinder.prm.nmcomp = nmcomp;
  cylinder.prm.mfilename = mfilename;
  cylinder.normals = [];
else
  ii = length(cylinder.prm)+1;
  cylinder.prm(ii).cprm = cprm;
  cylinder.prm(ii).mprm = mprm;
  cylinder.prm(ii).nccomp = nccomp;
  cylinder.prm(ii).nmcomp = nmcomp;
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
