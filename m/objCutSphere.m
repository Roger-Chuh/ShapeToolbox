function model = objCutSphere(model,n)

% OBJCUTSPHERE
%
% Usage: model = objCutSphere(model,n)
  
% Copyright (C) 2017, 2018 Toni Saarela
% 2017-12-22 - ts - first version
% 2018-01-18 - ts - help
  
% TODO:
% Figure out which way is up, and cut the first/last n rows.
% 
  
  if ~strcmp(model.shape,'sphere')
    error('Only works with sphere.');
  end
  
  x = 1:model.n;
  y = (1:model.m)';
  [X,Y] = meshgrid(x,y);

  % idx  = Y < (model.m - n + 1);
  % OR
  idx  = Y > n;
  
  idx = idx';
  idx = idx(:);
  


  model.Theta = model.Theta(idx);
  model.Phi = model.Phi(idx);
  model.R = model.R(idx);
  
  model.m = model.m - n;
  
  model = objMakeVertices(model);
  
end
