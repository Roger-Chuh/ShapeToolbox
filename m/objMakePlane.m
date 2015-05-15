function plane = objMakePlane(cprm,varargin)

% OBJMAKEPLANE
% 
% Usage:          objMakePlane()
%                 objMakePlane(cpar,[options])
%                 objMakePlane(cpar,mpar,[options])
%        OR:
%                 plane = objMakePlane(...)
%
% A 3D model of a plane perturbed by sinusoidal modulation(s).  The 
% function writes the vertices and faces into a Wavefront OBJ-file
% and optionally returns them as a structure.
%
% Without any input arguments, makes the default plane with a
% modulation along the x-direction at frequency of 8 cycle/object,
% amplitude of 0.1, and phase of 0.
%
% The width of the plane object is 1.  The modulation of the plane is
% in the same units (e.g., amplitude of 0.1 results in the values in
% the z-direction ranging from -0.1 to 0.1, or 10% of the width of the
% plane).  
%
% The input argument cpar defines the parameters for the modulation.
% The parameters are the frequency, amplitude, phase, and
% orientation/angle:
%   CPAR = [FREQ AMPL PH ANGLE]
%
% The frequency for modulation is in cycle/plane object.  Both the 
% x- and y-coordinates have zero in the middle of the plane.  All
% modulations are sine modulations (phase 0 is the sine phase).  The
% orientation of the modulation is given in degrees, 0 is vertical.
%
% It is possible to define several component modulations.  These
% modulations are added together.  Several components are defined in
% different rows of cpar:
%   CPAR = [FREQ1 AMPL1 PH1 ANGLE1
%           FREQ2 AMPL2 PH2 ANGLE2
%           ...
%           FREQN AMPLN PHN ANGLEN]
%
% Default values for amplitude, phase, and orientation are .1, 0, and 0,
% respectively.  If the number of columns in cpar is less that four,
% the default values will be filled in.
%
% To produce more complex modulations, separate carrier and
% modulator components can be defined with the input argument mpar.
% The carrier components are defined exactly as above.  The
% modulator modulates the amplitude of the carrier.  The parameters
% of the modulator(s) are given in the input argument mpar.  The
% format is the same as in defining the carrier components
% in cpar.  If several modulator components are defined, they are
% added together.  Typically, you will probably want to use a very
% simple (usually a single-component) modulator. Default values are 1 
% for amplitude, 0 for phase and orientation.
% 
% You can also define group indices to carriers and modulators
% to specify which modulators modulate which carriers.  See details in
% the online help on in the help for objMakeSphere.
%
% Optional input arguments can be given to define the number of vertex
% points or the filename for saving the object.
%
% To define the number of vertices in the model, use the option
% 'npoints' followed by a vector of length giving the number of points
% in the y- and x-directions:
%  > objMakePlane(...,'npoints',[m n],...)
% Default numbers are m=256 (y-direction), n=256 (x-direction).
%
% The model is saved in a text file.  The default name of the output
% text file is 'plane.obj'.  A different filename can be gives as a
% string:
%   > objMakePlane(...,'myfilename',...)
% If the custom filename does not have an obj-extension, it will be
% added.
%
% If the output argument is specified, the vertices and faces plus
% some other information are returned in the fields of the output 
% structure.
%
% Examples:
% > objMakePlane()             % Default, 8 cycles in the x-direction
% > objMakePlane([6 .2])       % Six modulation cycles, amplitude 0.2
%
% Modulation components in the two directions (added), save to plaid.obj:
% > objMakePlane([8 .2 0 0; 4 .1 0 90],'plaid.obj') 
% (This will produce a kind of "plaid" pattern.)
%
% Same as above, but use fewer points for a quicker testing (will not
% look good when rendered, but might be useful for experimenting):
% > objMakePlane([8 .2 0 0; 4 .1 0 90],'npoints',[128 128],'plaid.obj') 
%
% Makes a smooth bump:
% > objMakePlane([1 .1 pi/2 0; 1 .1 pi/2 90])    
%
% Two modulation components in the same (azimuth) direction,
% frequencies 4 and 12:
% > objMakePlane([4 .15 0 0; 12 .15 0 0]) 
%
% A vertical carrier with 8 cycles, its amplitude modulated by a
% 2-cycle, vertical modulator, also return the model in the structure
% pln:
% > pln = objMakePlane([8 .2 0 0],[2 1 0 0]) 
%

% Copyright (C) 2013,2014,2015 Toni Saarela
% 2013-10-09 - ts - first version
% 2014-07-31 - ts - an optional modulator can be used to modulate the
%                     carrier
%                   option to give grid size as input
%                   write more specs to obj file; return more specs
%                     with structure
% 2014-08-07 - ts - simplified the computation of carriers and
%                    modulators a little, new format for giving the modulation
%                    parameters; better initialization of matrices;
%                    significantly speeded up the computation of
%                    faces; carriers and modulators can have arbitrary
%                    orientations; wrote help
% 2014-10-11 - ts - both phase and orientation are given in degrees now
% 2014-10-11 - ts - now possible to use the modulators to modulate
%                    between two (or more) carriers
% 2014-10-12 - ts - changed default value for modulator amplitude (1)
%                   fixed a bug affecting the case when there are
%                   carriers AND modulators only in group 0
% 2014-10-14 - ts - added an option to compute texture coordinates and
%                    include a mtl file reference
% 2014-10-28 - ts - minor changes
% 2014-11-22 - ts - fixed call to newly named objMakeSineComponents
% 2015-03-05 - ts - fixed computation of faces (they were defined CW,
%                    should be CCW.  oops.)
%                   added computation of vertex normals
%                   improved writing of specs in comments
% 2015-03-06 - ts - updates to help
% 2015-04-03 - ts - calls the new objSaveModelPlane-function to
%                    compute faces, normals, etc and save the model to a file
%                   saving the model is optional, an existing model
%                     can be updated
% 2015-05-04 - ts - added uv-option without materials;
%                   calls objParseArgs and objSaveModel
% 2015-05-12 - ts - changed plane width and height to 2 (from -1 to 1)
% 2015-05-14 - ts - improved setting default parameters

% TODO
% Add option for noise in the amplitude
% Add option for noise in the frequencies
% More error checking of parameters
% Should the x and y values go from -w/2 to w/2 or from -w/2 to
%   w/2-w/npoints?
% Add an option to define the size of plane
% Update help, add the modulation between carriers thing

%--------------------------------------------

% Carrier parameters

% Set default frequency, amplitude, phase, orientation and component group id

defprm = [8 .05 0 0 0];

if ~nargin || isempty(cprm)
  cprm = defprm;
end

[nccomp,ncol] = size(cprm);

% Fill in default carrier parameters if needed
if ncol<5
  defprm = ones(nccomp,1)*defprm;
  cprm(:,ncol+1:5) = defprm(:,ncol+1:5);
end
clear defprm

%cprm(:,1) = cprm(:,1)*(2*pi);
cprm(:,1) = cprm(:,1)*pi;
cprm(:,3:4) = pi * cprm(:,3:4)/180;

% Set the default modulation parameters to empty indicating no modulator; set default filename.
mprm  = [];
nmcomp = 0;

opts.filename = 'plane.obj';
opts.m = 256;
opts.n = 256;

[modpar,par] = parseparams(varargin);

% If modulator parameters are given as input, set mprm to these values
if ~isempty(modpar)
  mprm = modpar{1};
  % Set default values to modulator parameters as needed
  [nmcomp,ncol] = size(mprm);
  if ncol<5
    defprm = ones(nmcomp,1)*[1 0 0 0];
    mprm(:,ncol+1:5) = defprm(:,ncol:4);
    clear defprm
  end
  %mprm(:,1) = mprm(:,1)*(2*pi);
  mprm(:,1) = mprm(:,1)*pi;
  mprm(:,3:4) = pi * mprm(:,3:4)/180;
end

% Check other optional input arguments
[opts,plane] = objParseArgs(opts,par);

%--------------------------------------------

if opts.new_model
  m = opts.m;
  n = opts.n;

  w = 2; % width of the plane
  h = 2; % m/n * w;
  
  x = linspace(-w/2,w/2,n); % 
  y = linspace(-h/2,h/2,m)'; % 

  [X,Y] = meshgrid(x,y);
  X = X'; X = X(:);
  Y = Y'; Y = Y(:);
  Z = 0;
else
  m = plane.m;
  n = plane.n;
  X = plane.X;
  Y = plane.Y;
  Z = plane.Z;
end

Z = Z + objMakeSineComponents(cprm,mprm,X,Y);

vertices = [X Y Z];

if opts.new_model
  plane.prm.cprm = cprm;
  plane.prm.mprm = mprm;
  plane.prm.nccomp = nccomp;
  plane.prm.nmcomp = nmcomp;
  plane.prm.mfilename = mfilename;
  plane.normals = [];
else
  ii = length(plane.prm)+1;
  plane.prm(ii).cprm = cprm;
  plane.prm(ii).mprm = mprm;
  plane.prm(ii).nccomp = nccomp;
  plane.prm(ii).nmcomp = nmcomp;
  plane.prm(ii).mfilename = mfilename;
  plane.normals = [];
end
plane.shape = 'plane';
plane.filename = opts.filename;
plane.mtlfilename = opts.mtlfilename;
plane.mtlname = opts.mtlname;
plane.comp_uv = opts.comp_uv;
plane.comp_normals = opts.comp_normals;
plane.w = w;
plane.h = h;
plane.n = n;
plane.m = m;
plane.X = X;
plane.Y = Y;
plane.Z = Z;
plane.vertices = vertices;

if opts.dosave
  plane = objSaveModel(plane);
end

if ~nargout
   clear plane
end



