function model = objCutSphere(model,n)

% OBJCUTSPHERE
%
% Usage: model = objCutSphere(model,n)
%
% Cut out a portion of a sphere. 
%
% Cut out the bottom n "rows" of vertices from the model. The
% following example creates a default bumpy sphere, which has 64
% vertices in the elevation direction, then cuts 32 out to return a
% bumpy hemisphere:
%
%   model = objMakeBump('sphere');
%   model = objCutSphere(model,32);
%   objView(model);
%
% will return a hemisphere.
%
% The main intended use of this function is preparing models for 3D
% printing with certain printing techniques. With SLA printing, you
% might want to cut out a piece of a sphere before printing to avoid a
% "suction" effect between the model and the bottom of the resin tank,
% which can possibly ruin/break the print. When preparing a model
% sphere for 3D printing by cutting out a portion of the model and
% adding thickness to the model walls, make sure you do it in that
% order: first cut, then add thickness. These should be the last steps
% you take using ShapeToolbox; add all perturbations first.
  
% Copyright (C) 2017, 2018 Toni Saarela
% 2017-12-22 - ts - first version
% 2018-01-18 - ts - help
% 2018-01-22 - ts - properly modify all relevant matrices
%                    (including Rbase, P)
%                   added help
% 2018-02-10 - ts - added support for ellipsoid

  if ~any(strcmp(model.shape,{'sphere','ellipsoid'}))
    error('Only works with sphere and ellipsoid.');
  end
  
  x = 1:model.n;
  y = (1:model.m)';
  [X,Y] = meshgrid(x,y);

  idx  = Y > n;
  
  idx = idx';
  idx = idx(:);

  model.Theta = model.Theta(idx);
  model.Phi = model.Phi(idx);
  model.R = model.R(idx,:);
  model.Rbase = model.Rbase(idx,:);
  model.P = model.P(idx,:);
  
  model.m = model.m - n;
  
  model = objMakeVertices(model);
  
end
