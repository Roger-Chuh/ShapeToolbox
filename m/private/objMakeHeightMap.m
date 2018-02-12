function model = objMakeHeightMap(model)

% OBJMAKEHEIGHTMAP

% Copyright (C) 2015 Toni Saarela
% 2015-06-01 - ts - first version
% 2015-10-08 - ts - bug fixes
% 2015-10-09 - ts - added/fixed bump map support for planes,
%                    cylinders, tori
% 2015-10-10 - ts - added support for the worm shape
% 2015-10-29 - ts - renamed from objMakeBumpMap to objMakeHeightMap
% 2016-05-30 - ts - uses params from model.prm(model.idx) instead of
%                    model.opts, to make it work with the "new"
%                    objParseCustomParams
% 2016-12-20 - ts - handle worm separately from cylinder et al to
%                    make interpolation of height map work
% 2017-06-08 - ts - make the perturbation profiles but don't add
%                    them to the model yet
% 2018-02-11 - ts - perturbations were still added too early; fixed
%                   added support for ellipsoid

% TODO:
% - you now use both model.idx and ii to index the current
%   parameter set. unify.
  
ii = model.idx;

switch model.shape
  case {'sphere','ellipsoid'}
    % R = reshape(model.R,[model.n model.m])';
    % R = reshape(model.Rbase,[model.n model.m])';
    if model.prm(ii).mmap~=model.m || model.prm(ii).nmap~=model.n
      Theta = model.Theta;
      Phi = model.Phi;
      Theta = reshape(Theta,[model.n model.m])';
      Phi = reshape(Phi,[model.n model.m])';
      
      % theta2 = linspace(-pi,pi-2*pi/model.prm(ii).nmap,model.prm(ii).nmap); % azimuth
      theta2 = linspace(-pi,pi,model.prm(ii).nmap); % azimuth
      phi2 = linspace(-pi/2,pi/2,model.prm(ii).mmap); % elevation
      [Theta2,Phi2] = meshgrid(theta2,phi2);
      model.prm(ii).map = interp2(Theta2,Phi2,model.prm(ii).map,Theta,Phi);
    end
    % R = R + model.prm(ii).ampl * model.prm(ii).map;
    % R = R'; 
    % model.R = R(:);
    P = model.prm(ii).ampl * model.prm(ii).map;
    model.P(:,model.idx) = P(:);
  case 'plane'
    % Z = reshape(model.Z,[model.n model.m])';
    % Z = reshape(model.Zbase,[model.n model.m])';
    if model.prm(ii).mmap~=model.m || model.prm(ii).nmap~=model.n
      X = model.X;
      Y = model.Y;
      X = reshape(X,[model.n model.m])';
      Y = reshape(Y,[model.n model.m])';
      
      x2 = linspace(-model.width/2,model.width/2,model.prm(ii).nmap); % 
      y2 = linspace(-model.height/2,model.height/2,model.prm(ii).mmap)'; % 
      [X2,Y2] = meshgrid(x2,y2);
      model.prm(ii).map = interp2(X2,Y2,model.prm(ii).map,X,Y);
    end
    % Z = Z + model.prm(ii).ampl * model.prm(ii).map;
    % Z = Z'; 
    % model.Z = Z(:);
    P = model.prm(ii).ampl * model.prm(ii).map;
    model.P(:,model.idx) = P(:);
  case {'cylinder','revolution','extrusion'}
    % R = reshape(model.R,[model.n model.m])';
    % R = reshape(model.Rbase,[model.n model.m])';
    if model.prm(ii).mmap~=model.m || model.prm(ii).nmap~=model.n
      Theta = model.Theta;
      Y = model.Y;
      Theta = reshape(Theta,[model.n model.m])';
      Y = reshape(Y,[model.n model.m])';
      
      % theta2 = linspace(-pi,pi-2*pi/model.prm(ii).nmap,model.prm(ii).nmap); % azimuth
      theta2 = linspace(-pi,pi,model.prm(ii).nmap); % azimuth
      y2 = linspace(-model.height/2,model.height/2,model.prm(ii).mmap); % 
      [Theta2,Y2] = meshgrid(theta2,y2);
      model.prm(ii).map = interp2(Theta2,Y2,model.prm(ii).map,Theta,Y);
    end
    % R = R + model.prm(ii).ampl * model.prm(ii).map;
    % R = R'; 
    % model.R = R(:);
    P = model.prm(ii).ampl * model.prm(ii).map;
    model.P(:,model.idx) = P(:);
  case 'worm'
    % R = reshape(model.R,[model.n model.m])';
    % R = reshape(model.Rbase,[model.n model.m])';
    if model.prm(ii).mmap~=model.m || model.prm(ii).nmap~=model.n
      theta = linspace(-pi,pi-2*pi/model.n,model.n); % azimuth
      y = linspace(-model.height/2,model.height/2,model.m)'; %  
      [Theta,Y] = meshgrid(theta,y);
      
      % theta2 = linspace(-pi,pi-2*pi/model.prm(ii).nmap,model.prm(ii).nmap); % azimuth
      theta2 = linspace(-pi,pi,model.prm(ii).nmap); % azimuth      
      y2 = linspace(-model.height/2,model.height/2,model.prm(ii).mmap); % 
      [Theta2,Y2] = meshgrid(theta2,y2);
      model.prm(ii).map = interp2(Theta2,Y2,model.prm(ii).map,Theta,Y);
    end
    % R = R + model.prm(ii).ampl * model.prm(ii).map;
    % R = R'; 
    % model.R = R(:);
    P = model.prm(ii).ampl * model.prm(ii).map;
    model.P(:,model.idx) = P(:);
  case 'torus'
    % r = reshape(model.r,[model.n model.m])';
    % r = reshape(model.rbase,[model.n model.m])';
    if model.prm(ii).mmap~=model.m || model.prm(ii).nmap~=model.n
      Theta = model.Theta;
      Phi = model.Phi;
      Theta = reshape(Theta,[model.n model.m])';
      Phi = reshape(Phi,[model.n model.m])';
      
      % theta2 = linspace(-pi,pi-2*pi/model.prm(ii).nmap,model.prm(ii).nmap); % azimuth
      % phi2 = linspace(-pi,pi-2*pi/model.prm(ii).mmap,model.prm(ii).mmap); % elevation
      theta2 = linspace(-pi,pi,model.prm(ii).nmap); % azimuth
      phi2 = linspace(-pi,pi,model.prm(ii).mmap); % elevation
      [Theta2,Phi2] = meshgrid(theta2,phi2);
      model.prm(ii).map = interp2(Theta2,Phi2,model.prm(ii).map,Theta,Phi);
    end
    % r = r + model.prm(ii).ampl * model.prm(ii).map;
    % r = r'; 
    % model.r = r(:);
    P = model.prm(ii).ampl * model.prm(ii).map;
    model.P(:,model.idx) = P(:);
  case 'disk'
    % Z = reshape(model.Z,[model.n model.m])';
    % Z = reshape(model.Zbase,[model.n model.m])';
    if strcmp(model.opts.coords,'cartesian')
      error('Bumps in cartesian coordinates not implemented for shape ''disk''.');
    elseif strcmp(model.opts.coords,'polar')
      
      if model.prm(ii).mmap~=model.m || model.prm(ii).nmap~=model.n
        Theta = model.Theta;
        R = model.R;
        Theta = reshape(Theta,[model.n model.m])';
        R = reshape(R,[model.n model.m])';
        
        theta2 = linspace(-pi,pi,model.prm(ii).nmap); % 
        phi2 = linspace(-pi,pi,model.prm(ii).mmap); % 
        [Theta2,R2] = meshgrid(theta2,phi2);
        model.prm(ii).map = interp2(Theta2,R2,model.prm(ii).map,Theta,R);
      end
      % Z = Z + model.prm(ii).ampl * model.prm(ii).map;
      % Z = Z'; 
      P = model.prm(ii).ampl * model.prm(ii).map;
      model.P(:,model.idx) = P(:);
    end
end
