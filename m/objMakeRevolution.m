function solid = objMakeRevolution(curve,cprm,varargin)

% OBJMAKEREVOLUTION
%
% Usage: solid = objMakeRevolution(curve,[CPAR],[MPAR],[OPTIONS])
%
% Make a 3D surface-of-revolution model and write it into .obj-file.
% The input argument `curve' is a vector that gives the distance from
% the y-axis at each point.  The 3D-shape is created by rotating this
% curve around the y-axis.
%
% The surface-of-revolution shape can be modulated, as any other shape
% in the toolbox, with sinusoidal components.  Briefly, the optional
% input argument CPAR defines the parameters for the sinusoid(s):
%   CPAR = [FREQ AMPL PH ANGLE]
%
% See details for the modulation and other options in the online help
% or in the help for objMakeSphere.
%
% The default resolution (number of vertices) is the length of the
% input vector 'curve'.  You can change this by setting the input
% argument 'npoints':
% > objMakeRevolution(...,'npoints',[m n],...)
%
% Examples:
% > x = linspace(0,2*pi,256);
% > curve = sin(.5*x).*(1+.5*sin(1.5*x));
% > figure; plot(curve)
% > objMakeRevolution(curve)
%
% The same but with added modulation
% > objMakeRevolution(curve,[8 .1 0 60],[1 1 90 90])

% Toni Saarela, 2015
% 2015-01-16 - ts - first version
% 2015-01-17 - ts - added the usual sine modulations; wrote a sort of help
% 2015-03-06 - ts - fixed interpolation of the curve; other small
%                    fixes; updated help
%

% TODO: 
% - add an option to give a function handle (or the function as a
%   string) as input?
% - check input: curve must be a vector
% - add modulator in the theta direction

ncurve = length(curve);
m = ncurve;
n = ncurve;

if nargin<2 || isempty (cprm)
  cprm = [8 .1 0 0 0];
end

[nccomp,ncol] = size(cprm);

switch ncol
  case 1
    cprm = [cprm ones(nccomp,1)*[.0 0 0 0]];
  case 2
    cprm = [cprm zeros(nccomp,3)];
  case 3
    cprm = [cprm zeros(nccomp,2)];
  case 4
    cprm = [cprm zeros(nccomp,1)];
end

cprm(:,3:4) = pi * cprm(:,3:4)/180;


% set default filename and other stuff
mprm  = [];
nmcomp = 0;
filename = 'revolution.obj';
mtlfilename = '';
mtlname = '';
comp_normals = false;
dosave = true;
new_model = true;

% Number of vertices in azimuth and elevation directions
%m = 256; 
%n = 256;

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
             solid = par{ii};
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
  m = solid.m;
  n = solid.n;
  Theta = solid.Theta;
  Y = solid.Y;
  r = solid.R;
end

if ncurve~=m
   curve = interp1(linspace(0,1,ncurve),curve,linspace(0,1,m));
end

R = r*repmat(curve(:)',[n 1]);
R = R(:);

R = R + objMakeSineComponents(cprm,mprm,Theta,Y);

X =  R .* cos(Theta);
Z = -R .* sin(Theta);

vertices = [X Y Z];

if new_model
  solid.prm.cprm = cprm;
  solid.prm.mprm = mprm;
  solid.prm.nccomp = nccomp;
  solid.prm.nmcomp = nmcomp;
  solid.prm.mfilename = mfilename;
  solid.normals = [];
else
  ii = length(solid.prm)+1;
  solid.prm(ii).cprm = cprm;
  solid.prm(ii).mprm = mprm;
  solid.prm(ii).nccomp = nccomp;
  solid.prm(ii).nmcomp = nmcomp;
  solid.prm(ii).mfilename = mfilename;
  solid.normals = [];
end
solid.shape = 'revolution';
solid.filename = filename;
solid.mtlfilename = mtlfilename;
solid.mtlname = mtlname;
solid.comp_normals = comp_normals;
solid.curve = curve;
solid.n = n;
solid.m = m;
solid.Theta = Theta;
solid.Y = Y;
solid.R = R;
solid.vertices = vertices;

if dosave
  solid = objSaveModelCylinder(solid);
end

if ~nargout
   clear solid
end



