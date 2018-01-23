function h = objView(obj,func,campos,showaxes)

% OBJVIEW
%
% Usage: h = objView(model)
%        h = objView(model,[viewfunc],[campos],[showaxes])
%        h = objView(filename,...)
%
% View a 3D model returned by one of the make objMake-functions in
% the toolbox.  Alternatively, attempt to read such a model from a
% Wavefront obj -file (see help objRead for limitations of doing
% this). 
%
% Returns a handle h to the rendered graphics object.
%
% The optional input argument 'viewfunc' specifies the Octave/Matlab
% function for showing the object.  Possible values are 'surfl'
% (default), 'surf',  and 'mesh'.  A further option 'wireframe' is
% similar to 'mesh' but shows a see-through wireframe model. Note
% that not all lighting options etc. might be available on Octave.
%
% Examples:
% > sphere = objMakeSine('sphere');
% > objView(sphere)
% 
% > tor = objMakeNoise('torus');
% > objView(tor,'surf')
%
% The second optional input argument can be used to specify the
% camera position vector.
%
% The third optional input argument can be set to true to make the
% axes visible.  Default is false, axes not visible.
  
% Note: This function is just for quick and convenient viewing of
% the shape, without texture mapping or material properties. Only
% the shape is shown, using the vertex data.

% Copyright (C) 2014,2015,2016.2017,2018 Toni Saarela
% 2014-07-28 - ts - first version
% 2015-03-05 - ts - use shading interp; wrote help
% 2015-06-04 - ts - updated help
% 2015-06-04 - ts - fixed a bug in reshaping the matrices, which
%                    made the rendering to be distorted
%                   attemps to read a model from file if string
%                    given as input
% 2015-06-10 - ts - repeat the first row/column of vertices to avoid
%                    the missing 'wedge' in the rendered model
% 2015-10-14 - ts - 'mesh' shows only the vertex mesh, white faces
%                   'surf' does not use interpolation
%                   added 'wireframe' option for see-through wireframe model
%                   added 'worm' as a shape option
% 2015-10-15 - ts - different commands for matlab and octave to set
%                    viewing options
% 2016-06-14 - ts - minor changes to help
% 2016-12-13 - ts - improved viewing directions, rotation etc in Matlab
%                   can set axes visible
% 2016-12-16 - ts - camera position as optional input
% 2017-11-16 - ts - don't crash if function 'light' does not exist
%                    (older versions of matlab); help tweaked
% 2018-01-20 - ts - rewrote the switching of z and y axes
% 2018-01-21 - ts - renamed from objshow to objview
% 2018-01-23 - ts - work-around to get correct view position in octave
  
% TODO
% https://se.mathworks.com/help/matlab/examples/displaying-complex-three-dimensional-objects.html
% use patch object?
% material: shiny etc
% light position, ambient, specular etc
    
  if ischar(obj)
    obj = objRead(obj);
  end

  if nargin<2 || isempty(func)
    func = 'surfl';
  end

  if nargin<3 || isempty(campos)
    campos = [1.2 1.2 1.2];
  end
  
  if nargin<4 || isempty(showaxes)
    showaxes = false;
  end
  
  isoctave = exist('OCTAVE_VERSION');
  
  X = reshape(obj.vertices(:,1),[obj.n obj.m])';
  Y = reshape(obj.vertices(:,2),[obj.n obj.m])';
  Z = reshape(obj.vertices(:,3),[obj.n obj.m])';

  if isfield(obj,'shape')
    switch obj.shape
      case {'sphere','cylinder','revolution','extrusion','worm'}
        X = reshape(obj.vertices(:,1),[obj.n obj.m])';
        Y = reshape(obj.vertices(:,2),[obj.n obj.m])';
        Z = reshape(obj.vertices(:,3),[obj.n obj.m])';
        X = [X X(:,1)]; 
        Y = [Y Y(:,1)]; 
        Z = [Z Z(:,1)]; 
      case 'torus'
        X = reshape(obj.vertices(:,1),[obj.n obj.m])';
        Y = reshape(obj.vertices(:,2),[obj.n obj.m])';
        Z = reshape(obj.vertices(:,3),[obj.n obj.m])';
        X = [X X(:,1)]; 
        Y = [Y Y(:,1)]; 
        Z = [Z Z(:,1)]; 
        X = [X; X(1,:)]; 
        Y = [Y; Y(1,:)]; 
        Z = [Z; Z(1,:)]; 
    end
  end

  % Switch the y and z coordinates.  Matlab insists having z as the
  % up-direction when 3d rotation is on, so we do this to have y
  % up. Basically we should have Y = -Z, but it's better to switch
  % the Z axis direction. This is done further below. Either way,
  % we're effectively rotating the shape about the X-axis and then
  % relabeling z and y axes (or switching their labels) to get the
  % desired effect.
  tmp = Y;
  Y = Z;
  Z = tmp;
  
  %figure;
  switch lower(func)
    case 'surfl'
      h = surfl(X,Y,Z);%,[4 10 4]);%,'cdata');
      try
        hl = light(gca);
      end
      % if ~isoctave
      %   hl = light(gca);
      % end
      shading interp;
      colormap gray;
    case 'surf'
      h = surf(X,Y,Z);
      colormap gray;
    case 'mesh'
      h = mesh(X,Y,Z);
      set(h,'EdgeColor',[0 0 0],'FaceColor',[1 1 1]);
    case 'wireframe'
      h = mesh(X,Y,Z);
      set(h,'EdgeColor',[0 0 0],'FaceColor','none');
    otherwise
      error('Unknown viewing function.  Use ''surfl'', ''surf'', ''mesh'', or ''wireframe''.')
  end
  axis equal
  set(gca,'Visible','Off');

  if isoctave
    try
      set(gca,'CameraUpVector',[0 0 1]);
      % set(gca,'CameraUpVector',[0 0 1],...
      %       'CameraUpVectorMode','manual',...
      %       'CameraPosition',campos);
      
      % I think the view function in Octave ignores the fact that
      % we reverse the y-direction (really z in our coords). So we
      % have to flip the sign of y (z) in the camera position
      % vector. hacks galore.
      
      campos(2) = -campos(2);
      
      view(campos);
      rotate3d on
    catch
      ;
    end
  else
    set(gca,'CameraUpVector',[0 0 1],...
            'CameraUpVectorMode','manual',...
            'CameraPosition',campos);

    h3 = rotate3d;
    set(h3,'Enable','On');
    
    % Instead of rotate3d we could set the cameratoolbar visible
    % and let the user use the buttons. But Octave does not have it
    % yet, so use rotate3d and switch the z and y axes. Sigh.
    % cameratoolbar('Show')
  
  end

  xlabel('x')
  % Switch the labels of y and z, because Matlab insists having z
  % point up when 3d rotation is on.  For this reason, the y and
  % z coordinates are also switched (above) for viewing.
  ylabel('z')
  zlabel('y')
    
  if showaxes
    set(gca,'Visible','On')
  end
  
  % Do this instead of setting y = -z above
  set(gca,'ydir','reverse','xdir','normal')

  if ~nargout
    clear h
  end
end
