function m = objScale(m,scale)

% OBJSCALE
%
% m = objScale(m,scale)
%
% Scale an object. This might be marginally useful when prepping
% models for 3D printing. (When rendering, you can always scale the
% models when importing them to the scene to be rendered.)
  
% Copyright (C) 2017, 2018 Toni Saarela
% 2017-12-21 - ts - first version
% 2018-01-22 - ts - works prperly with all shapes (torus has a bug)
%                   added a sort of help
% 2018-02-10 - ts - added support for ellipsoid

  if ~isscalar(scale)
    error('Scaling factor must be scalar.');
  end
  
  switch m.shape
    case 'sphere'
      m.R = scale * m.R;
      m.Rbase = scale * m.Rbase;
      m.P = scale * m.P;
      m = objMakeVertices(m);
    case 'ellipsoid'
      m.R = scale * m.R;
      m.Rbase = scale * m.Rbase;
      m.P = scale * m.P;
      m = objMakeVertices(m);
    case {'plane', 'disk'}
      m.X = scale * m.X;
      m.Y = scale * m.Y;
      m.Z = scale * m.Z;
      m.P = scale * m.P;
      m.Zbase = scale * m.Zbase;
      m.vertices = scale * m.vertices;
    case {'cylinder','revolution','extrusion','worm'}
      m.R = scale * m.R; 
      m.Y = scale * m.Y;
      m.spine.X = scale * m.spine.X;
      m.spine.Y = scale * m.spine.Y;
      m.spine.Z = scale * m.spine.Z;
      m.P = scale * m.P;
      m.Rbase = scale * m.Rbase;
      m = objMakeVertices(m);
    case 'torus'
      m.R = scale * m.R;
      m.r = scale * m.r;
      m.P = scale * m.P;
      m.rbase = scale * m.rbase;
      m = objMakeVertices(m);
  end
  
  m.scale = scale;
  
end
