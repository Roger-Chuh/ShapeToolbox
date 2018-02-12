function model = objMake(shape,perturbation,varargin)

% OBJMAKE
%
% Usage:  MODEL = OBJMAKE(SHAPE,PERTURBATION) 
%         MODEL = OBJMAKE(SHAPE,PERTURBATION,[OPTIONS])
%                 OBJMAKE(SHAPE,PERTURBATION,[OPTIONS])
%
% Produce a 3D model mesh object of a given shape and optionally save 
% it to a file in Wavefront obj-format and/or return a structure that
% holds the model information.
%
% Normally you would not call this function directly but would use one
% of the objMake* wrappers, such as objMakePlain, objMakeSine, etc.

% Copyright (C) 2016,2017,2018 Toni Saarela
% 2016-01-22 - ts - first version, based on objMake*-functions
% 2016-01-28 - ts - minor changes
% 2016-02-19 - ts - handles custom perturbations
% 2016-03-25 - ts - renamed objMake (from objMakeMaster)
% 2016-03-26 - ts - calls the renamed objSave (formerly objSaveModel)
% 2016-04-08 - ts - cleaning up
% 2016-10-22 - ts - cleaning up; pushed checking new/existing model
%                    to objDefaultStruct
% 2016-10-23 - ts - changed saving calling function names from
%                    dbstack
% 2017-05-26 - ts - minor change to help. or well, "help"
% 2018-01-15 - ts - save tilt axis and angle for sphere in prm
% 2018-02-09 - ts - added support for ellipsoid
  
%------------------------------------------------------------

% Set up the model structure
model = objDefaultStruct(shape);
clear shape

% Set default parameters for the given perturbation:
if isempty(perturbation)
  perturbation = 'none';
end
model = objDefaultPerturbationPrms(model,perturbation);

% Check and parse optional input arguments
[tmp,par] = parseparams(varargin);
model = objParseArgs(model,par);

% Do shape-dependent things if needed
switch model.shape
  case 'sphere'
    if length(model.radius)~=1
      error('Sphere radius must be a scalar.');
    end
  case 'torus'
    if isscalar(model.radius)
      model.radius = model.radius * [1 1];
    elseif length(model.radius)~=2
      error('Torus radius must be a scalar or a vector of length 2.');
    end
  case {'plane','disk'}
    ;
  case {'cylinder','revolution','extrusion','worm'}
    model = objInterpCurves(model);
  case 'ellipsoid'
    if isscalar(model.radius)
      model.radius = model.radius * [1 1 1];
    elseif length(model.radius)~=3
      error('Ellipsoid radius must be a scalar or a vector of length 3.');
    end
  otherwise
    error('Unknown shape'); % not needed, already checked by objDefaultStruct
end

% Do perturbation-dependent things if needed
switch model.prm(model.idx).perturbation
  case 'none'
  case 'sine'
  case 'noise'
  case 'bump'
  case 'custom'
    model = objParseCustomParams(model);
end

%-------------------------------------------------------------
% Vertices
if model.flags.new_model
  model = objSetCoords(model);
end
model = objAddPerturbation(model);
model = objMakeVertices(model);

%-------------------------------------------------------------
% 

ii = model.idx;

% Get the calling functions from the debugging stack.  Keep the
% name of this function and any wrapper functions (starting
% objMake*) from ShapeToolbox that called this one.  In objSave,
% write them in the obj-file for reference.
stack = dbstack;

for jj = 1:length(stack)
  if strncmp(stack(jj).name,'objMake',7)
    model.prm(ii).mfilestack{jj} = stack(jj).name;
  else
    break
  end
end

switch model.shape
  case 'sphere'
    model.prm(ii).tilt_axis = model.opts.tilt_axis;
    model.prm(ii).tilt_angle = model.opts.tilt_angle;
  case 'torus'
    model.prm(ii).rprm = model.opts.rprm;
end

if model.flags.dosave
  model = objSave(model);
end

if ~nargout
   clear model
end




