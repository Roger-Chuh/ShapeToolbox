function model = objMakeVertices(model)

% OBJMAKEVERTICES
%
% Usage: MODEL = objMakeVertices(model)
%
% Compute vertices for the model.  Do the necessary conversions (eg
% from spherical to cartesian) and add/update the field "vertices" in
% the model structure.

% Copyright (C) 2016 Toni Saarela
% 2016-01-21 - ts - first version
% 2018-02-09 - ts - added support for ellipsoid
  
  switch model.shape
    case 'ellipsoid'
      % s = @(x,n) sign(sin(x)).*abs(sin(x)).^n;
      % c = @(x,n) sign(cos(x)).*abs(cos(x)).^n;
      % y =  model.R(:,2) .* s(model.Phi,model.super(1));
      % x =  model.R(:,1) .* c(model.Phi,model.super(1)) .* c(model.Theta,model.super(2));
      % z = -model.R(:,3) .* c(model.Phi,model.super(1)) .* s(model.Theta,model.super(2));
      % model.vertices = [x y z];
      model.vertices = objSph2XYZ(model.Theta,model.Phi,model.R,[],model.super);
    case 'sphere'
      model.vertices = objSph2XYZ(model.Theta,model.Phi,model.R);
    case 'plane'
      model.vertices = [model.X model.Y model.Z];
    case {'cylinder','revolution','extrusion'}
      if model.flags.caps
        model = objAddCaps(model);
      end
      model.X =  model.R .* cos(model.Theta);
      model.Z = -model.R .* sin(model.Theta);
      X = model.X + model.spine.X;
      Z = model.Z + model.spine.Z;
      model.vertices = [X model.Y Z];
    case 'torus'
      model.vertices = objSph2XYZ(model.Theta,model.Phi,model.r,model.R,model.super);
    case 'worm'
      % TODO: objAddCaps
      model = objMakeWorm(model);
    case 'disk'
      model.vertices = [model.X model.Y model.Z];    
    otherwise
      error('Unknown shape.');
  end

end
