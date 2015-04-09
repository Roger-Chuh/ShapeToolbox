function plane = objMakePlaneNoisy(nprm,varargin)

% OBJMAKEPLANENOISY
%
% Usage:           objMakePlaneNoisy()
%                  objMakePlaneNoisy(NPAR,[OPTIONS])
%                  objMakePlaneNoisy(NPAR,MPAR,[OPTIONS])
%         sphere = objMakePlaneNoisy(...)
%
% A 3D model plane modulated in the z-direction by filtered noise.
%
% Without any input arguments, makes an example plane with default
% parameters adn saves the model in planenoisy.obj.
%
% The parameters for the filtered noise are given in the input
% argument NPAR:
%   NPAR = [FREQ FREQWDT OR ORWDT AMPL],
% with
%   FREQ    - middle frequency, in cycles per plane
%   FREQWDT - full width at half height, in octaves
%   OR      - orientation in degrees (0 is 'vertical')
%   ORWDT   - orientation bandwidth (FWHH), in degrees
%   AMPL    - amplitude
% 
% The width and height of the plane is 1.
%
% Several modulation components can be defined in the rows of NPAR.
% The components are added.
%   NPAR = [FREQ1 FREQWDT1 OR1 ORWDT1 AMPL1
%           FREQ2 FREQWDT2 OR2 ORWDT2 AMPL2
%           ...
%           FREQN FREQWDTN ORN ORWDTN AMPLN]
%
% To produce more complex modulations, separate carrier and
% modulator components can be defined.  The carrier components are
% defined exactly as above.  The modulator modulates the amplitude
% of the carrier.  The parameters of the modulator(s) are given in
% the input argument MPAR.  The modulators are sinusoidal; their
% parameters are identical to those in the function objMakePlane.
% The parameters are frequency, amplitude, orientation, and phase:
%   MPAR = [FREQ AMPL OR PH]
% 
% You can also define group indices to noise carriers and modulators
% to specify which modulators modulate which carriers.  See details in
% the online help on in the help for objMakeSphere.
%
% By default, saves the object in planenoisy.obj.  To save in a
% different file, define the output file name as a string:
%   > objMakeSphereNoisy(...,'newfilename',...)
%
% The default number of vertices when providing a function handle as
% input is 256x256.  To define a different
% number of vertices:
%   > objMakePlaneNoisy(...,'npoints',[N M],...)
%
% To turn on the computation of surface normals (which will increase
% computation time):
%   > objMakePlaneNoisy(...,'normals',true,...)
%
% For texture mapping, see help to objMakePlane or online help.
%

% Examples:
% TODO

% Copyright (C) 2013,2014,2015 Toni Saarela
% 2013-10-15 - ts - first, rudimentary version
% 2014-10-09 - ts - improved speed, included filtering function,
%                   added input arguments/options
% 2014-10-11 - ts - improved filtering function, added orientation filtering
% 2014-10-11 - ts - now possible to use the modulators to modulate
%                    between two (or more) carriers
%                   can have different sizes in x and y directions
%                    (not tested properly yet)
% 2014-10-12 - ts - fixed a bug affecting the case when there are
%                   carriers AND modulators only in group 0
% 2014-10-15 - ts - added an option to compute texture coordinates and
%                    include a mtl file reference
% 2014-10-28 - ts - minor changes
% 2015-03-05 - ts - fixed computation of faces (they were defined CW,
%                    should be CCW.  oops.)
%                   vertex normals; write specs in comments; help
% 2015-04-03 - ts - calls the new objSaveModelPlane-function to
%                    compute faces, normals, etc and save the model to a file
%                   saving the model is optional, an existing model
%                     can be updated

%--------------------------------------------

% TODO
% Add an option for unequal size in x and y -- see objMakePlane
% If orientation full width is zero, that means no orientation
% filtering.  Or wait, should it be Inf?

if ~nargin || isempty(nprm)
  nprm = [8 1 0 45 .1 0];
end

[nncomp,ncol] = size(nprm);

if ncol==5
  nprm = [nprm zeros(nncomp,1)];
elseif ncol<5
  error('Incorrect number of columns in input argument ''nprm''.');
end

nprm(:,3:4) = pi * nprm(:,3:4)/180;

% Set the default modulation parameters to empty indicating no modulator; set default filename.
mprm  = [];
nmcomp = 0;
filename = 'planenoisy.obj';
use_rms = false;
mtlfilename = '';
mtlname = '';
comp_normals = false;
dosave = true;
new_model = true;

% Number of vertices in y and x directions, default values
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
      mprm = [mprm ones(nmcomp,1)*[1 0 0 0]];
    case 2
      mprm = [mprm zeros(nmcomp,3)];
    case 3
      mprm = [mprm zeros(nmcomp,2)];
    case 4
      mprm = [mprm zeros(nmcomp,1)];
  end
  mprm(:,1) = mprm(:,1)*(2*pi);
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
           if ii<length(par) && (isnumeric(par{ii+1}) || islogical(par{ii+1}))
             ii = ii + 1;
             comp_normals = par{ii};
           else
             error('No value or a bad value given for option ''normals''.');
           end
         case 'rms'
           use_rms = true;
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
     end
     ii = ii + 1;
   end
end
  
% Add file name extension if needed
if isempty(regexp(filename,'\.obj$'))
  filename = [filename,'.obj'];
end

%--------------------------------------------

if new_model
  w = 1; % width of the plane
  h = 1; % m/n * w;
  
  x = linspace(-w/2,w/2,n); % 
  y = linspace(-h/2,h/2,m)'; % 

  [X,Y] = meshgrid(x,y);
  Z = 0;
else
  m = plane.m;
  n = plane.n;
  X = reshape(plane.X,[n m])';
  Y = reshape(plane.Y,[n m])';
  Z = reshape(plane.Z,[n m])';
end

%--------------------------------------

Z = Z + objMakeNoiseComponents(nprm,mprm,X,Y,use_rms);

X = X'; X = X(:);
Y = Y'; Y = Y(:);
Z = Z'; Z = Z(:);

vertices = [X Y Z];


if new_model
  plane.prm.nprm = nprm;
  plane.prm.mprm = mprm;
  plane.prm.nncomp = nncomp;
  plane.prm.nmcomp = nmcomp;
  plane.prm.use_rms = use_rms;
  plane.prm.mfilename = mfilename;
  plane.normals = [];
else
  ii = length(plane.prm)+1;
  plane.prm(ii).nprm = nprm;
  plane.prm(ii).mprm = mprm;
  plane.prm(ii).nncomp = nncomp;
  plane.prm(ii).nmcomp = nmcomp;
  plane.prm(ii).use_rms = use_rms;
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
