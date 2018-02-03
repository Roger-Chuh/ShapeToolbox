function model = objSetCoords(model)

% OBJSETCOORDS
%
% model = objSetCoords(model)
%
% Called by objMake*-functions.

% Copyright (C) 2015 Toni Saarela
% 2015-05-30 - ts - first version
% 2015-06-08 - ts - separate arguments for revolution and extrusion
%                    profiles, can be combined
% 2015-06-10 - ts - radius, width, height not set here anymore
% 2015-10-08 - ts - added handling of the 'spinex' and 'spinez' options
% 2015-10-10 - ts - added support for worm shape
% 2016-01-19 - ts - added disk shape
% 2016-09-23 - ts - include spiney in cylinder-like shapes to allow
%                    blending with worms
% 2017-06-08 - ts - renamed the perturbation dimension (R, Z, r
%                    ...) to Rbase etc. to keep the original and
%                    just add the perturbations to it; allows
%                    "recovering" the original; see also objAddPerturbation
% 2017-06-22 - ts - disk is in the same plane as, well, the plane
%                     (xy plane, perturbation along z; instead of xz, y)
% 2018-02-03 - ts - compute spines here
  
switch model.shape
  case 'sphere'
    theta = linspace(-pi,pi-2*pi/model.n,model.n); % azimuth
    phi = linspace(-pi/2,pi/2,model.m)'; % elevation
    [Theta,Phi] = meshgrid(theta,phi);
    Theta = Theta'; Phi   = Phi';
    model.Theta = Theta(:);
    model.Phi   = Phi(:);
    model.Rbase = model.radius*ones(model.m*model.n,1);
  case 'plane'
    model.x = linspace(-model.width/2,model.width/2,model.n); % 
    model.y = linspace(-model.height/2,model.height/2,model.m)'; % 
    [X,Y] = meshgrid(model.x,model.y);
    X = X'; Y = Y'; 
    model.X = X(:);
    model.Y = Y(:);
    model.Zbase = zeros(model.m*model.n,1);
  case {'cylinder','revolution','extrusion'}
    model.theta = linspace(-pi,pi-2*pi/model.n,model.n); % azimuth
    if ~isfield(model,'y')
      model.y = linspace(-model.height/2,model.height/2,model.m)'; %  
    end
    [Theta,Y] = meshgrid(model.theta,model.y);
    Theta = Theta'; Y = Y'; 
    model.Theta = Theta(:);
    model.Y = Y(:);
    switch model.shape
      case 'cylinder'
        model.Rbase = model.radius * ones(model.m*model.n,1);
      case 'revolution'
        if isfield(model,'ecurve')
          R = model.radius * model.ecurve' * model.rcurve;
        else
          R = model.radius * repmat(model.rcurve,[model.n 1]);
        end
        model.Rbase = R(:);
      case 'extrusion'
        if isfield(model,'rcurve')
          R = model.radius * model.ecurve' * model.rcurve;
        else
          R = model.radius * repmat(model.ecurve',[1 model.m]);
        end
        model.Rbase = R(:);
    end
    
    if ~model.flags.custom_spine(1)
      model.spine.x = zeros(1,model.m);
    end
    if ~model.flags.custom_spine(2)
      model.spine.y = linspace(-model.height/2,model.height/2,model.m);
    end
    if ~model.flags.custom_spine(3)
      model.spine.z = zeros(1,model.m);
    end    
    
    model.spine.X = ones(model.n,1) * model.spine.x;
    model.spine.X = model.spine.X(:);
    model.spine.Y = ones(model.n,1) * model.spine.y;
    model.spine.Y = model.spine.Y(:);
    model.spine.Z = ones(model.n,1) * model.spine.z;
    model.spine.Z = model.spine.Z(:);
  case 'worm'
    model.theta = linspace(-pi,pi-2*pi/model.n,model.n); % azimuth
    model.y = linspace(-model.height/2,model.height/2,model.m)'; %  
    [Theta,Y] = meshgrid(model.theta,model.y);
    Theta = Theta'; Y = Y'; 
    model.Theta = Theta(:);
    model.Y = Y(:);    

    if isfield(model,'ecurve') && isfield(model,'rcurve')
      R = model.radius * model.ecurve' * model.rcurve;
      model.Rbase = R(:);
    elseif isfield(model,'rcurve')
      R = model.radius * repmat(model.rcurve,[model.n 1]);
      model.Rbase = R(:);
    elseif isfield(model,'ecurve')
      R = model.radius * repmat(model.ecurve',[1 model.m]);
      model.Rbase = R(:);
    else
      model.Rbase = model.radius * ones(model.m*model.n,1);
    end
    
    if ~model.flags.custom_spine(1)
      model.spine.x = zeros(1,model.m);
    end
    if ~model.flags.custom_spine(2)
      model.spine.y = linspace(-model.height/2,model.height/2,model.m);
    end
    if ~model.flags.custom_spine(3)
      model.spine.z = zeros(1,model.m);
    end    

    if model.flags.scaley
       model.spine.y_orig = model.spine.y;
       model.spine.y = arcscale(model.spine.y',model.spine.x',model.spine.z',model.height)';
       % model.spine.y = model.spine.y - mean(model.spine.y);
       if any(~isreal(model.spine.y))
         error('Scaling failed. ');
       end
    end

    % Direction/"derivative" of the spine in the case of "worm"
    model.spine.D = numderiv([model.spine.x; model.spine.y; model.spine.z]');

    model.spine.X = ones(model.n,1) * model.spine.x;
    model.spine.X = model.spine.X(:);
    model.spine.Y = ones(model.n,1) * model.spine.y;
    model.spine.Y = model.spine.Y(:);
    model.spine.Z = ones(model.n,1) * model.spine.z;
    model.spine.Z = model.spine.Z(:);

  case 'torus'
    model.theta = linspace(-pi,pi-2*pi/model.n,model.n);
    model.phi = linspace(-pi,pi-2*pi/model.m,model.m); 
    [Theta,Phi] = meshgrid(model.theta,model.phi);
    Theta = Theta'; Phi = Phi';
    model.Theta = Theta(:);
    model.Phi   = Phi(:);
    model.R = model.radius*ones(model.m*model.n,1);
    model.rbase = model.tube_radius*ones(model.m*model.n,1);
  case 'disk'
    %model.theta = linspace(-pi,pi-2*pi/model.n,model.n);
    model.theta = linspace(-pi,pi,model.n);
    model.r = linspace(0,model.radius,model.m);
    [Theta,R] = meshgrid(model.theta,model.r);
    Theta = Theta'; R = R';
    model.Theta = Theta(:);
    model.R     = R(:);
    [model.X, model.Y] = pol2cart(model.Theta,model.R);
    model.Zbase = zeros(model.m*model.n,1);
end



%------------------------------------------------------------
% Functions
function D = numderiv(M)

% NUMDERIV

% Copyright (C) 2015 Toni Saarela
% 2015-10-09 - ts - first version

M1 = M(1:end-2,:);
M2 = M(3:end,:);
D = (M2-M1)/2;
D = [M(2,:)-M(1,:); D; M(end,:)-M(end-1,:)];
l = (D.^2*[1 1 1]').^.5;
D = D ./ (l*[1 1 1]);


function x = arcscale(x,y,z,l)

% ARCSCALE

% Copyright (C) 2015 Toni Saarela
% 2015-10-11 - ts - first version
% 2015-10-20 - ts - fixed a bug when returning without scaling

% Works in both two and three dimensions; just set the third
% coordinate to zero if only two given.
if isempty(z)
  x = [x y];
  x(:,3) = 0;
else
  x = [x y z];
end

% Desired size of each segment:
%dl = l/(length(x)-1);
dl = l/(size(x,1)-1);

% Differences between consecutive coordinates
d = diff(x,[],1);

% If the current length (l2) is very close to the desired length,
% don't do anything:
l2 = sum(sqrt(sum(d.^2,2)));
if abs(l-l2)<.00001
   x = x(:,1);
  return
end

% otherwise, scale the first coordinate so that the curve will have
% the desired length:
k = sqrt(dl.^2 - d(:,2).^2 - d(:,3).^2)./d(:,1);
x(2:end,1) = x(1,1) + cumsum(k .* d(:,1));

x = x(:,1);
