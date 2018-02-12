function model = objAddThickness(model,w,type)
  
% OBJADDTHICKNESS
%
% Usage: model = objAddThickness(model,w)
%        model = objAddThickness(model,w,'flat')
%
% Add wall thickness w to a model.
%
% All the objMake*-functions in the toolbox create shell models,
% that is, they just represent the outer boundary or shell of an
% object. For 3D printing, the model walls need to have a
% thickness. This function adds wall thickness to a model created
% using one of the objMake*-functions. 
%
% The thickness is given by the input argument w. By default, the
% inner wall of the object follows the same perturbation that has been
% added to the model. If you want a flat inner wall (or "back wall"),
% give the optional third input argument 'flat'. Be careful when using
% this option: If you have added a high-amplitude perturbation and add
% a too thin wall thickness using the 'flat'-option, the perturbation
% in the "front wall" might go trough the "back wall".
%
% Example:
%
%   s = objMakeBump('sphere');
%   s = objCutSphere(s,32);
%   s = objAddThickness(s,0.2);
%   objView(s)
%
%   m = objMakeNoise('plane');
%   m1 = objAddThickness(m,0.1);
%   m1 = objSet(m1,'filename','thick1');
%   objSave(m1);
%
%   m2 = objAddThickness(m,0.1,'flat');
%   m2 = objSet(m2,'filename','thick2');
%   objSave(m2);
%
% You see the model with thick walls properly only when viewing the
% save model with a 3D model viewer---viewing it with objView will not
% necessarily (depending a bit on the base shape) show the solid model
% shape properly.
%
% NOTE: When making 3D models and preparing them for 3D printing,
% using this function to add thickness to the walls should be
% absolutely the last step you take using ShapeToolbox. After this,
% trying to add perturbations will result in an error (or if it
% does not, the results are almost certainly not what you would
% expect). So do this last.  
  
% Copyright (C) 2017, 2018 Toni Saarela
% 2017-12-22 - ts - first version
% 2018-01-18 - ts - help
% 2018-01-22 - ts - works prperly with all shapes except torus
%                   added a sort of help
% 2018-02-10 - ts - added support for ellipsoid
  
  if strcmp(model.shape,'torus')
    error('Sorry, wall thickness thing not yet implemented for tori.');
  end
  
  if nargin>2 && ischar(type) && strcmp(type,'flat')
    flat = true;
  else
    flat = false;
  end
  
  switch model.shape
    case 'sphere'
      
      Theta = reshape(model.Theta,[model.n model.m])';
      Phi = reshape(model.Phi,[model.n model.m])';
      R = reshape(model.R,[model.n model.m])';
      
      Theta = [flipud(Theta); Theta];
      Phi = [flipud(Phi); Phi];
      
      if flat
        Rbase = reshape(model.Rbase,[model.n model.m])';
        Rtmp = flipud(Rbase)-w;
      else
        Rtmp = flipud(R)-w;
      end
      
      R = [Rtmp; R];
      
      Theta = Theta'; Phi = Phi'; R = R';
      model.Theta = Theta(:);
      model.Phi = Phi(:);
      model.R = R(:);
      
      model.m = 2*model.m;

    case 'torus'
      
      Theta = reshape(model.Theta,[model.n model.m])';
      Phi = reshape(model.Phi,[model.n model.m])';
      r = reshape(model.r,[model.n model.m])';
      
      Theta = [flipud(Theta); Theta];
      Phi = [flipud(Phi); Phi];
      
      if flat
        rbase = reshape(model.rbase,[model.n model.m])';
        rtmp = flipud(rbase)-w;
      else
        rtmp = flipud(r)-w;
      end
      
      r = [rtmp; r];
      
      Theta = Theta'; Phi = Phi'; r = r';
      model.Theta = Theta(:);
      model.Phi = Phi(:);
      model.r = r(:);
      
      model.m = 2*model.m;
      
    case 'ellipsoid'
      
      Theta = reshape(model.Theta,[model.n model.m])';
      Phi = reshape(model.Phi,[model.n model.m])';
      R = permute(reshape(model.R,[model.n model.m 3]),[2 1 3]);
      
      Theta = [flipud(Theta); Theta];
      Phi = [flipud(Phi); Phi];
      
      if flat
        Rbase = permute(reshape(model.Rbase,[model.n model.m 3]),[2 1 3]);
        Rtmp = flipud(Rbase)-w;
      else
        Rtmp = flipud(R)-w;
      end
      
      R = [Rtmp; R];
      
      Theta = Theta'; Phi = Phi'; R = permute(R,[2 1 3]);
      model.Theta = Theta(:);
      model.Phi = Phi(:);
      model.R = reshape(R,[2*model.m*model.n 3]);
      
      model.m = 2*model.m;
      
    case {'plane', 'disk'}
      
      X = reshape(model.X,[model.n model.m])';
      Y = reshape(model.Y,[model.n model.m])';
      Z = reshape(model.Z,[model.n model.m])';
      
      X = [flipud(X); X];
      Y = [flipud(Y); Y];
      
      if flat
        Zbase = reshape(model.Zbase,[model.n model.m])';
        Ztmp = flipud(Zbase)-w;
      else
        Ztmp = flipud(Z)-w;
      end
      
      Z = [Ztmp; Z];
      
      X = X'; Y = Y'; Z = Z';
      model.X = X(:);
      model.Y = Y(:);
      model.Z = Z(:);
      
      model.m = 2*model.m;
      
    case {'cylinder','revolution','extrusion'}
      
      Theta = reshape(model.Theta,[model.n model.m])';
      Y = reshape(model.Y,[model.n model.m])';
      R = reshape(model.R,[model.n model.m])';
      
      Theta = [flipud(Theta); Theta];
      Y = [flipud(Y); Y];
      
      if flat
        Rbase = reshape(model.Rbase,[model.n model.m])';
        Rtmp = flipud(Rbase)-w;
      else
        Rtmp = flipud(R)-w;
      end
      
      R = [Rtmp; R];
      
      Theta = Theta'; Y = Y'; R = R';
      model.Theta = Theta(:);
      model.Y = Y(:);
      model.R = R(:);

      % Spine
      X = reshape(model.spine.X,[model.n model.m])';
      Y = reshape(model.spine.Y,[model.n model.m])';
      Z = reshape(model.spine.Z,[model.n model.m])';
      
      X = [flipud(X); X];
      Y = [flipud(Y); Y];
      Z = [flipud(Z); Z];
      
      X = X'; Y = Y'; Z = Z';
      model.spine.X = X(:);
      model.spine.Y = Y(:);
      model.spine.Z = Z(:);
      
      model.m = 2*model.m;
  end

  model = objMakeVertices(model);
  model.flags.thickwalls = true;
  
end
