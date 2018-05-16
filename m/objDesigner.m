function objDesigner()

  % OBJDESIGNER
%
% Usage: objDesigner()
%
% A rudimentary graphical tool built on top of the shapetoolbox
% functions. This can be used to design models and test the effect
% of different surface perturbations etc. It's mainly useful for
% quick testing and trying out / learning to use the toolbox. It
% does not offer all the options that are available in the toolbox
% functions. For full functionality, it's better to call the
% objMake*- and other functions from your own code.
%
% The current version works only on Matlab.

% Copyright (C) 2018 Toni Saarela
% 2018-02-14 - ts - first version
% 2018-xx-xx - ts - several updates
% 2018-05-16 - ts - polish
  
  %------------------------------------------------------------
  % Set things up   for gui
  
  scrsize = get(0,'ScreenSize');
  scrsize = scrsize(3:4);
  
  fontsize = 8;
  margin = 10;
  col.txt.act   = [0 0 0];
  col.txt.inact = [.5 .5 .5];
  
  figsize  = [800 500];  % size of main application window
  shapesize = [245 450]; % size of shape parameter panel
  pertsize = shapesize;  % perturbation parameter panel
  prevsize = [265 400];  % preview pane;
  % This is the axis size for preview, not figure window size:
  prevfigsize = 200;
  
  listfigsize = [200 300];
  curvefigsize = [300 600];
  
  isoctave = exist('OCTAVE_VERSION');  
  
  %------------------------------------------------------------
  % Default model values
  
  default.shape.shape = 'sphere';
  default.shape.types = {'sphere','ellipsoid','plane','cylinder','torus','disk','revolution','extrusion','worm'};  

  default.shape.sphere.npoints = [64 128];
  default.shape.sphere.radius = '1';
  
  default.shape.plane.npoints = [128 128];
  default.shape.plane.height  = '1';
  default.shape.plane.width   = '1';
  
  default.shape.disk.npoints = [128 128];
  default.shape.disk.radius = '1';

  default.shape.cylinder.npoints = [128 128];
  default.shape.cylinder.height  = '2*pi';
  default.shape.cylinder.radius  = '1';
  default.shape.cylinder.caps  = 0;
  
  default.shape.revolution = default.shape.cylinder;
  default.shape.revolution.curve(1).rcurve = ones(default.shape.revolution.npoints(1),1);
  default.shape.revolution.curve(1).xdata = [1 1];
  default.shape.revolution.curve(1).ydata = [-pi pi];
  default.shape.revolution.curve(1).ysmooth = linspace(-pi,pi,default.shape.revolution.npoints(1))';
  default.shape.revolution.curve(1).xsmooth = ones(default.shape.revolution.npoints(1),1);
  default.shape.revolution.curve(1).connect = false;
  default.shape.revolution.curve(1).interp = 'spline';

  default.shape.revolution.curve(2).ecurve = ones(default.shape.revolution.npoints(2)+1,1);
  default.shape.revolution.curve(2).xdata = [1 0 -1 0];
  default.shape.revolution.curve(2).ydata = [0 1 0 -1];
  default.shape.revolution.curve(2).ysmooth = sin(linspace(0,2*pi,default.shape.revolution.npoints(2)+1))';
 default.shape.revolution.curve(2).xsmooth = cos(linspace(0,2*pi,default.shape.revolution.npoints(2)+1))';

 default.shape.extrusion  = default.shape.revolution;
  default.shape.worm       = default.shape.revolution;
  
  default.shape.ellipsoid.npoints = [128 128];
  default.shape.ellipsoid.radius  = '1 1 1';
  default.shape.ellipsoid.super   = '1 1';
  
  default.shape.torus.npoints      = [128 128];
  default.shape.torus.radius       = '1 1';
  default.shape.torus.minor_radius = '.4';
  default.shape.torus.super        = '1 1';
  default.shape.torus.rpar        = '';
  
  % Set all default values for shapes ABOVE this line
  
  % Copy parameter values from default fields for each shape
  fns = fieldnames(default.shape);
  for ii = 1:length(fns)
    model.shape.(fns{ii}) = default.shape.(fns{ii});
  end
  
  
  % Default perturbation values
  
  default.perturbation.name = 'none';
  
  default.perturbation.types = {'none','sine','noise','bump','custom'};

  default.perturbation.none = [];
  
  default.perturbation.sine.cpar = [8 0 0 .1 0];
  default.perturbation.sine.mpar = [];
  default.perturbation.sine.tiltaxis = [];
  default.perturbation.sine.tiltangle = [];
  
  default.perturbation.noise.npar = [8 1 0 30 .1 0];
  default.perturbation.noise.mpar = [];
  
  default.perturbation.bump.par = [20 pi/12 .1];
  default.perturbation.bump.max = false;
  
  default.perturbation.custom.par = {{},{},{},{}};
  
  % default.perturbation.list = [];
  
  % Set all default values for perturbations ABOVE this line
  
  % Copy parameter values from default fields for each shape
  fns = fieldnames(default.perturbation);
  for ii = 1:length(fns)
    model.perturbation.list(1).(fns{ii}) = default.perturbation.(fns{ii});
  end
  
  % The perturbation being edited.
  model.perturbation.current = 1;
  model.perturbation.use = 1;
  
  % List of perturbations:
  %model.list = [];
  
  % Field m holds the actual model
  model.m = [];

  %------------------------------------------------------------
  % Main application window  
  
  h.main.f = figure('Color','white',...
                    'Units','pixels',...
                    'NumberTitle','Off',...
                    'Name','objDesigner',...
                    'Visible','Off');
  
  pos = [scrsize/2-figsize(1,:)/2 figsize(1,:)];
  set(h.main.f,'Position',pos);
  
  %------------------------------------------------------------
  % Main panels
  
  % Preview area and axes
  h.main.prev.pn = uipanel(h.main.f,'Title','Preview','FontSize',12,...
                           'BackgroundColor','white',...
                           'Units','pixels',...
                           'Position',...
                           [(figsize(1,1)-prevsize(1,1))/2 figsize(1,2)-prevsize(1,2)-margin prevsize]);
  
  % Shape selection and parameters
  h.main.shape.pn = uipanel(h.main.f,'Title','Shape','FontSize',12,...
                            'BackgroundColor','white',...
                            'Units','pixels',...
                            'Position',[margin figsize(1,2)-shapesize(1,2)-margin shapesize]);  
  

  % Perturbation
  h.main.pert.pn = uipanel(h.main.f,'Title','Perturbation','FontSize',12,...
                           'BackgroundColor','white',...
                           'Units','pixels',...
                           'Position',[figsize(1)-pertsize(1,1)-margin figsize(1,2)-pertsize(1,2)-margin pertsize]); 
  
  % Command
  % h.main.cmd.pn = uipanel(h.main.f,'Title','Command','FontSize',12,...
  %                         'BackgroundColor','white',...
  %                         'Units','pixels',...
  %                         'Position',[margin margin 500 60]); 
  
  
  %------------------------------------------------------------
  % Shape and shape parameters
  h.main.shape.shape = uicontrol('Parent',h.main.shape.pn,...
                                 'Style', 'popupmenu',...
                                 'String', default.shape.types,...
                                 'FontSize',10,...
                                 'Position', [10 shapesize(2)-40 100 20]);
  

  pos = get(h.main.pert.pn,'position');
  parentsize = pos(3:4);
  
  panelsize = [225 70; 225 110; 225 140];
  
  
  % Resolution / number of vertices
  h.main.shape.reso.pn = uipanel(h.main.shape.pn,'Title','Model resolution','FontSize',10,...
                                 'BackgroundColor','white',...
                                 'Units','pixels',...
                                 'Position',[margin parentsize(2)-panelsize(1,2)-50 panelsize(1,1) panelsize(1,2)]);  
  
  h.main.shape.reso.npoints(1) = uicontrol('Parent',h.main.shape.reso.pn,...
                                           'Style', 'edit',...
                                           'Position', [10 10 90 20],...
                                           'HorizontalAlignment','left',...
                                           'String','',...
                                           'enable', 'on');
  h.main.shape.reso.npoints_lab(1) = uicontrol('Parent',h.main.shape.reso.pn,...
                                               'Style','text',...
                                               'Position',[10 30 90 14],...
                                               'FontSize',fontsize,...
                                               'horizontalalignment','left',...
                                               'foregroundcolor',col.txt.act,...
                                               'String','Y or elevation');
  
  h.main.shape.reso.npoints(2) = uicontrol('Parent',h.main.shape.reso.pn,...
                                           'Style', 'edit',...
                                           'Position', [120 10 90 20],...
                                           'HorizontalAlignment','left',...
                                           'String','',...
                                           'enable', 'on');
  h.main.shape.reso.npoints_lab(2) = uicontrol('Parent',h.main.shape.reso.pn,...
                                               'Style','text',...
                                               'Position',[120 30 90 14],...
                                               'FontSize',fontsize,...
                                               'horizontalalignment','left',...
                                               'foregroundcolor',col.txt.act,...
                                               'String','X or azimuth');

  % Model size and other basic prms
  panelwidth = panelsize(2,1);
  panelheight = panelsize(2,2);
  h.main.shape.basic_pn = uipanel(h.main.shape.pn,'Title','Model size','FontSize',10,...
                                  'BackgroundColor','white',...
                                  'Units','pixels',...
                                  'Position',[margin parentsize(2)-sum(panelsize(1:2,2))-60 panelsize(2,1) panelsize(2,2)]);  

  h.main.shape.height = uicontrol('Parent',h.main.shape.basic_pn,...
                                  'Style', 'edit',...
                                  'Position', [10 panelheight-60 90 20],...
                                  'HorizontalAlignment','left',...
                                  'String','',...
                                  'enable', 'off');
  h.main.shape.height_lab = uicontrol('Parent',h.main.shape.basic_pn,...
                                      'Style','text',...
                                      'Position',[10 panelheight-40 90 14],...
                                      'FontSize',fontsize,...
                                      'horizontalalignment','left',...
                                      'foregroundcolor',col.txt.inact,...
                                      'String','Height');

  h.main.shape.width = uicontrol('Parent',h.main.shape.basic_pn,...
                                 'Style', 'edit',...
                                 'Position', [120 panelheight-60 90 20],...
                                 'HorizontalAlignment','left',...
                                 'String','',...
                                 'enable', 'off');
  h.main.shape.width_lab = uicontrol('Parent',h.main.shape.basic_pn,...
                                     'Style','text',...
                                     'Position',[120 panelheight-40 90 14],...
                                     'FontSize',fontsize,...
                                     'horizontalalignment','left',...
                                     'foregroundcolor',col.txt.inact,...
                                     'String','Width');
  
  
  h.main.shape.radius = uicontrol('Parent',h.main.shape.basic_pn,...
                                  'Style', 'edit',...
                                  'Position', [10 panelheight-100 90 20],...
                                  'HorizontalAlignment','left',...
                                  'String','');
  h.main.shape.radius_lab = uicontrol('Parent',h.main.shape.basic_pn,...
                                      'Style','text',...
                                      'Position',[10 panelheight-80 100 14],...
                                      'FontSize',fontsize,...
                                      'horizontalalignment','left',...
                                      'String','Radius');
  
  h.main.shape.minor_radius = uicontrol('Parent',h.main.shape.basic_pn,...
                                        'Style', 'edit',...
                                        'Position', [120 panelheight-100 90 20],...
                                        'HorizontalAlignment','left',...
                                        'String','',...
                                        'TooltipString','Radius of the ''tube'' of the torus');
  h.main.shape.minor_radius_lab = uicontrol('Parent',h.main.shape.basic_pn,...
                                            'Style','text',...
                                            'Position',[120 panelheight-80 90 14],...
                                            'FontSize',fontsize,...
                                            'horizontalalignment','left',...
                                            'String','Minor radius',...
                                            'TooltipString','Radius of the ''tube'' of the torus');
  
  
  % Other shape prms
  panelwidth = panelsize(3,1);
  panelheight = panelsize(3,2);
  h.main.shape.other_pn = uipanel(h.main.shape.pn,'Title','Other params','FontSize',10,...
                                  'BackgroundColor','white',...
                                  'Units','pixels',...
                                  'Position',[margin parentsize(2)-sum(panelsize(1:3,2))-60 225 panelheight]);  
  
  h.main.shape.super = uicontrol('Parent',h.main.shape.other_pn,...
                                 'Style', 'edit',...
                                 'Position', [10 panelheight-60 60 20],...
                                 'HorizontalAlignment','left',...
                                 'String','',...
                                 'enable', 'off',...
                                 'TooltipString','Two values, try something between 0 and 3');
  h.main.shape.super_lab = uicontrol('Parent',h.main.shape.other_pn,...
                                     'Style','text',...
                                     'Position',[10 panelheight-40 120 14],...
                                     'FontSize',fontsize,...
                                     'horizontalalignment','left',...
                                     'foregroundcolor',col.txt.inact,...
                                     'String','Superellipsoid prm',...
                                     'TooltipString','Two values, try something between 0 and 3');

  tooltip = 'Modulate main radius of torus: radial_freq, phase, amplitude';
  h.main.shape.rpar = uicontrol('Parent',h.main.shape.other_pn,...
                                'Style', 'edit',...
                                'Position', [10 panelheight-100 120 20],...
                                'HorizontalAlignment','left',...
                                'String','',...
                                'enable', 'off',...
                                'TooltipString',tooltip);
  h.main.shape.rpar_lab = uicontrol('Parent',h.main.shape.other_pn,...
                                    'Style','text',...
                                    'Position',[10 panelheight-80 120 14],...
                                    'FontSize',fontsize,...
                                    'horizontalalignment','left',...
                                    'foregroundcolor',col.txt.inact,...
                                    'TooltipString',tooltip,...
                                    'String','Radius modulation');
  
  
  h.main.shape.caps = uicontrol('Parent',h.main.shape.other_pn,...
                                'Style', 'checkbox',...
                                'Value',0,...
                                'Position', [10 panelheight-130 100 20],...
                                'HorizontalAlignment','left',...
                                'enable', 'off',...
                                'String','Caps',...
                                'FontSize',fontsize,...
                                'TooltipString','Close cylinder-like shapes with caps.');
  
  % % Reset
  h.main.shape.reset = uicontrol('Parent',h.main.shape.pn,...
                                 'Style', 'pushbutton',...
                                 'String', 'Reset',...
                                 'FontSize',fontsize,...
                                 'Position', [10 10 60 20],...
                                 'TooltipString','Reset shape to default values');   
  %------------------------------------------------------------
  % Preview, model export etc.
  
  pos = get(h.main.prev.pn,'position');
  parentsize = pos(3:4);

  h.main.prev.ax = axes('Parent',h.main.prev.pn,'Units','pixels','Position',...
                        [(parentsize(1)-prevfigsize)/2 ...
                      (parentsize(1)-prevfigsize)/2+(parentsize(2)-parentsize(1)) ...
                      prevfigsize ...
                      prevfigsize]);
  
  h.main.prev.showax = uicontrol('Parent',h.main.prev.pn,'Units','pixels',...
                                 'Style', 'checkbox',...
                                 'Position', [10 10 100 20],...
                                 'String','Show axes',...
                                 'FontSize',fontsize,...
                                 'Value', 0);

  
  h.main.export.lab = uicontrol('Parent',h.main.prev.pn,'Units','pixels',...
                                 'Style','text',...
                                'Position',[10 35 55 20],...
                                'HorizontalAlignment','left',...
                                'String','Variable',...
                                'FontSize',fontsize);
  
  h.main.export.var = uicontrol('Parent',h.main.prev.pn,'Units','pixels',...
                                'Style','edit',...
                                'Position',[70 35 50 20],...
                                'HorizontalAlignment','left',...
                                'String','model',...
                                'TooltipString','Give a variable name for the model structure',...
                                'FontSize',fontsize);
  
  h.main.export.btn = uicontrol('Parent',h.main.prev.pn,'Units','pixels',...
                                'Style', 'pushbutton',...
                                'String', 'Export to workspace',...
                                'TooltipString','Export the model structure to Matlab workspace',...
                                'Position', [125 35 130 20],...
                                'FontSize',fontsize);
  
  
  h.main.save.model.lab = uicontrol('Parent',h.main.prev.pn,'Units','pixels',...
                                 'Style','text',...
                                'Position',[10 65 55 20],...
                                'HorizontalAlignment','left',...
                                'String','Filename',...
                                'FontSize',fontsize);
  
  h.main.save.model.filename = uicontrol('Parent',h.main.prev.pn,'Units','pixels',...
                                'Style','edit',...
                                'Position',[70 65 50 20],...
                                'HorizontalAlignment','left',...
                                'String','model',...
                                'TooltipString','Give a file name to save to',...
                                'FontSize',fontsize);
  
  h.main.save.model.btn = uicontrol('Parent',h.main.prev.pn,'Units','pixels',...
                                'Style', 'pushbutton',...
                                'String', 'Save .obj file',...
                                'TooltipString','Save the model to a Wavefront obj file',...
                                'Position', [125 65 130 20],...
                                'FontSize',fontsize);  
  
  h.main.prev.reset.btn = uicontrol('Parent',h.main.prev.pn,'Units','pixels',...
                                'Style', 'pushbutton',...
                                'String', 'Reset view',...
                                'TooltipString','Restore default view of the model',...
                                'Position', [125 10 130 20],...
                                'FontSize',fontsize);  
    
  %------------------------------------------------------------
  % Perturbations
  
  h.main.pert.pert = uicontrol('Parent',h.main.pert.pn,...
                               'Style', 'popupmenu',...
                               'String', default.perturbation.types,...
                               'Position', [10 pertsize(2)-40 100 20],...
                               'FontSize',10);
  
  h.main.pert.none.pn = [];
  
  % Set dialogs etc for sine perturbation
    
  pos = get(h.main.pert.pn,'position');
  parentsize = pos(3:4);
  
  panelsize = [225 125; 225 125; 225 80];
  
  % panelheight = 140;
  panelwidth = panelsize(1,1);
  panelheight = panelsize(1,2);
  
  h.main.pert.sine.pn = uipanel(h.main.pert.pn,'Title','Carrier parameters','FontSize',10,...
                            'BackgroundColor','white',...
                            'Units','pixels',...
                            'Position',[10 parentsize(2)-panelheight-45 panelwidth panelheight]);  

  lines = panelheight - (15:20:135);

  x = 10:32:170; % x = [10 50 90 130 170];
  labels = {'Freq','Ori','Ph','Ampl','Grp'};
  tooltip = {'Frequency','Orientation','Phase','Amplitude','Group'};
  for ii = 1:length(labels)
    h.main.pert.sine.label(1,ii) = uicontrol('Parent',h.main.pert.sine.pn,...
                                             'Style','text',...
                                             'Position',[x(ii) lines(2) 30 14],...
                                             'FontSize',fontsize,...
                                             'String',labels{ii},...
                                             'TooltipString',tooltip{ii});
  end

  y = lines(3:6);
  for ii = 1:4
    for jj = 1:5
      h.main.pert.sine.cpar(ii,jj) = uicontrol('Parent',h.main.pert.sine.pn,...
                                               'Style', 'edit',...
                                               'Position', [x(jj) y(ii) 30 20],...
                                               'TooltipString',tooltip{jj});
    end
  end

  % h.main.pert.sine.reset.cpar = uicontrol('Parent',h.main.pert.sine.pn,...
  %                                   'Style', 'pushbutton',...
  %                                   'String', 'Reset',...
  %                                   'FontSize',fontsize,...
  %                                   'Position', [10 lines(7) 50 20],...
  %                                   'TooltipString','Reset to default values.');
    
  
  panelwidth = panelsize(2,1);
  panelheight = panelsize(2,2);  
  h.main.pert.sine.pn(2) = uipanel(h.main.pert.pn,'Title','Modulator parameters','FontSize',10,...
                                   'BackgroundColor','white',...
                                   'Units','pixels',...
                                   'Position',[10 parentsize(2)-sum(panelsize(1:2,2))-45 panelwidth panelheight]);  

  lines = panelheight - (15:20:135);

  % x = [10 50 90 130 170];
  labels = {'Freq','Ori','Ph','Ampl','Grp'};
  tooltip = {'Frequency','Orientation','Phase','Amplitude','Group'};
  for ii = 1:length(labels)
    h.main.pert.sine.label(2,ii) = uicontrol('Parent',h.main.pert.sine.pn(2),...
                                             'Style','text',...
                                             'Position',[x(ii) lines(2) 30 14],...
                                             'FontSize',fontsize,...
                                             'String',labels{ii},...
                                             'TooltipString',tooltip{ii});
  end

  y = lines(3:6);
  for ii = 1:4
    for jj = 1:5
      h.main.pert.sine.mpar(ii,jj) = uicontrol('Parent',h.main.pert.sine.pn(2),...
                                               'Style', 'edit',...
                                               'Position', [x(jj) y(ii) 30 20],...
                                               'TooltipString',tooltip{jj});
    end
  end

  % h.main.pert.sine.reset.mpar = uicontrol('Parent',h.main.pert.sine.pn(2),...
  %                                   'Style', 'pushbutton',...
  %                                   'String', 'Reset',...
  %                                   'FontSize',fontsize,...
  %                                   'Position', [10 lines(7) 50 20],...
  %                                   'TooltipString','Reset to default values.');
  
  
  panelwidth = panelsize(3,1);
  panelheight = panelsize(3,2);  
    
  h.main.pert.sine.pn(3) = uipanel(h.main.pert.pn,'Title','Rotation','FontSize',10,...
                                   'BackgroundColor','white',...
                                   'Units','pixels',...
                                   'Position',[10 parentsize(2)-sum(panelsize(:,2))-45 panelwidth panelheight]);  
  
  tooltip = {'Axis about which to rotate shape before adding perturbation',...
             'Rotation angle in degrees'};
  
  h.main.pert.sine.tilt_lab(1) = uicontrol('Parent',h.main.pert.sine.pn(3),...
                                            'Style','text',...
                                            'Position',[10 30 90 14],...
                                            'FontSize',fontsize,...
                                            'horizontalalignment','left',...
                                            'foregroundcolor',col.txt.inact,...
                                            'String','Rotation axis',...
                                            'TooltipString',tooltip{1});
  h.main.pert.sine.tilt(1) = uicontrol('Parent',h.main.pert.sine.pn(3),...
                                        'Style', 'edit',...
                                        'horizontalalignment','left',...
                                        'enable','on',...
                                        'Position', [10 10 90 20],...
                                        'TooltipString',tooltip{1});
      
  
  h.main.pert.sine.tilt_lab(2) = uicontrol('Parent',h.main.pert.sine.pn(3),...
                                            'Style','text',...
                                            'Position',[120 30 90 14],...
                                            'FontSize',fontsize,...
                                            'horizontalalignment','left',...
                                            'foregroundcolor',col.txt.inact,...
                                            'String','Rotation angle',...
                                            'TooltipString', tooltip{2});
  h.main.pert.sine.tilt(2) = uicontrol('Parent',h.main.pert.sine.pn(3),...
                                         'Style', 'edit',...
                                         'horizontalalignment','left',...
                                         'enable','on',...
                                         'Position', [120 10 90 20],...
                                         'TooltipString',tooltip{2});  
  
  
  set(h.main.pert.sine.pn,'Visible','Off');
  

  
  
  
  % Set dialogs etc for noise perturbation
    
  pos = get(h.main.pert.pn,'position');
  parentsize = pos(3:4);
  
  panelsize = [225 125];
  
  panelwidth = panelsize(1);
  panelheight = panelsize(2);  
  
  h.main.pert.noise.pn = uipanel(h.main.pert.pn,'Title','Carrier parameters','FontSize',10,...
                            'BackgroundColor','white',...
                            'Units','pixels',...
                            'Position',[10 parentsize(2)-panelheight-45 panelwidth panelheight]);  

  lines = panelheight - (15:20:135);

  x = 10:32:170;% [10 50 90 130 170];
  labels = {'Freq','BW','Ori','BW','Ampl','Grp'};
  tooltip = {'Frequency','Frequency bandwidth','Orientation',...
             'Orientation bandwidth','Amplitude','Group'};
  for ii = 1:length(labels)
    h.main.pert.noise.label(1,ii) = uicontrol('Parent',h.main.pert.noise.pn,...
                                             'Style','text',...
                                             'Position',[x(ii) lines(2) 30 14],...
                                             'FontSize',fontsize,...
                                             'String',labels{ii},...
                                             'TooltipString',tooltip{ii});
  end
  
  y = lines(3:6);
  for ii = 1:4
    for jj = 1:6
      h.main.pert.noise.npar(ii,jj) = uicontrol('Parent',h.main.pert.noise.pn,...
                                               'Style', 'edit',...
                                               'Position', [x(jj) y(ii) 30 20],...
                                               'TooltipString',tooltip{jj});
    end
  end

  % h.main.pert.noise.reset.npar = uicontrol('Parent',h.main.pert.noise.pn,...
  %                                   'Style', 'pushbutton',...
  %                                   'String', 'Reset',...
  %                                   'FontSize',fontsize,...
  %                                   'Position', [10 lines(7) 50 20],...
  %                                   'TooltipString','Reset to default values.');
    
  
  h.main.pert.noise.pn(2) = uipanel(h.main.pert.pn,'Title','Modulator parameters','FontSize',10,...
                                   'BackgroundColor','white',...
                                   'Units','pixels',...
                                   'Position',[10 parentsize(2)-2*panelheight-45 panelwidth panelheight]);  

  lines = panelheight - (15:20:135);

  %x = [10 50 90 130 170];
  labels = {'Freq','Ori','Ph','Ampl','Grp'};
  tooltip = {'Frequency','Orientation','Phase','Amplitude','Group'};
  for ii = 1:length(labels)
    h.main.pert.noise.label(2,ii) = uicontrol('Parent',h.main.pert.noise.pn(2),...
                                             'Style','text',...
                                             'Position',[x(ii) lines(2) 30 14],...
                                             'FontSize',fontsize,...
                                             'String',labels{ii},...
                                             'TooltipString',tooltip{ii});
  end

  y = lines(3:6);
  for ii = 1:4
    for jj = 1:5
      h.main.pert.noise.mpar(ii,jj) = uicontrol('Parent',h.main.pert.noise.pn(2),...
                                               'Style', 'edit',...
                                               'Position', [x(jj) y(ii) 30 20],...
                                               'TooltipString',tooltip{jj});
    end
  end

  % h.main.pert.noise.reset.mpar = uicontrol('Parent',h.main.pert.noise.pn(2),...
  %                                   'Style', 'pushbutton',...
  %                                   'String', 'Reset',...
  %                                   'FontSize',fontsize,...
  %                                   'Position', [10 lines(7) 50 20],...
  %                                   'TooltipString','Reset to default values.');
    
  set(h.main.pert.noise.pn,'Visible','Off');
  

  
  % Set dialogs etc for bumps
    
  pos = get(h.main.pert.pn,'position');
  parentsize = pos(3:4);
  
  panelsize = [225 125];
  
  panelwidth = panelsize(1);
  panelheight = panelsize(2);  
  
  h.main.pert.bump.pn = uipanel(h.main.pert.pn,'Title','Bump parameters','FontSize',10,...
                            'BackgroundColor','white',...
                            'Units','pixels',...
                            'Position',[10 parentsize(2)-panelheight-45 panelwidth panelheight]);  

  lines = panelheight - (15:20:135);

  x = 10:32:170;% [10 50 90 130 170];
  labels = {'N','Size','Ampl'};
  tooltip = {'Number of bumps','Size (sd of Gaussian)','Amplitude/height'};
  for ii = 1:length(labels)
    h.main.pert.bump.label(1,ii) = uicontrol('Parent',h.main.pert.bump.pn,...
                                             'Style','text',...
                                             'Position',[x(ii) lines(2) 30 14],...
                                             'FontSize',fontsize,...
                                             'String',labels{ii},...
                                             'TooltipString',tooltip{ii});
  end
  
  y = lines(3:6);
  for ii = 1:4
    for jj = 1:3
      h.main.pert.bump.par(ii,jj) = uicontrol('Parent',h.main.pert.bump.pn,...
                                               'Style', 'edit',...
                                               'Position', [x(jj) y(ii) 30 20],...
                                               'TooltipString',tooltip{jj});
    end
  end
  
  % Set dialogs etc for custom perturbation
    
  pos = get(h.main.pert.pn,'position');
  parentsize = pos(3:4);
  
  panelsize = [225 75];
  
  panelwidth = panelsize(1);
  panelheight = panelsize(2);  
  
  h.main.pert.custom.pn(1) = uipanel(h.main.pert.pn,'Title','Function from file','FontSize',10,...
                                     'BackgroundColor','white',...
                                     'Units','pixels',...
                                     'Position',[10 parentsize(2)-panelheight-45 panelwidth panelheight]);  
  
  h.main.pert.custom.pn(2) = uipanel(h.main.pert.pn,'Title','Anonymous function (@)','FontSize',10,...
                                    'BackgroundColor','white',...
                                    'Units','pixels',...
                                    'Position',[10 parentsize(2)-2*panelheight-45 panelwidth panelheight]);  
  
  h.main.pert.custom.pn(3) = uipanel(h.main.pert.pn,'Title','Matrix from workspace','FontSize',10,...
                                     'BackgroundColor','white',...
                                     'Units','pixels',...
                                     'Position',[10 parentsize(2)-3*panelheight-45 panelwidth panelheight]);  
  
  
  h.main.pert.custom.pn(4) = uipanel(h.main.pert.pn,'Title','Image file','FontSize',10,...
                                    'BackgroundColor','white',...
                                    'Units','pixels',...
                                    'Position',[10 parentsize(2)-4*panelheight-45 panelwidth panelheight]);  
  
  lines = panelheight - [45 65];
  x = [10 80 160];

  labels = {'File','Args'};
  tooltip = {'Filename','Input arguments for the function'};
  for ii = 1:length(labels)
    h.main.pert.custom.label(ii,1) = uicontrol('Parent',h.main.pert.custom.pn(1),...
                                               'Style','text',...
                                             'horizontalalignment','left',...
                                               'Position',[x(1) lines(ii) 60 14],...
                                               'FontSize',fontsize,...
                                               'String',labels{ii},...
                                               'TooltipString',tooltip{ii});
  end
  
  wdt = [80 130];
  for ii = 1:2
    h.main.pert.custom.par(ii,1) = uicontrol('Parent',h.main.pert.custom.pn(1),...
                                             'Style', 'edit',...
                                             'horizontalalignment','left',...
                                             'Position', [x(2) lines(ii) wdt(ii) 20],...
                                             'TooltipString',tooltip{ii});
  end  
  
  h.main.pert.custom.selectfile(1) = uicontrol('Parent',h.main.pert.custom.pn(1),...
                                            'Style', 'pushbutton',...
                                            'String', 'Browse',...
                                            'FontSize',8,...
                                            'Position', [x(3) lines(1) 60 20],...
                                            'Callback', {@select_mfile_CB,h.main.pert.custom.par(1,1)});  
    
    
  labels = {'Function','Args'};
  tooltip = {'Anonymous function','Input arguments for the function'};
  for ii = 1:length(labels)
    h.main.pert.custom.label(ii,2) = uicontrol('Parent',h.main.pert.custom.pn(2),...
                                               'Style','text',...
                                             'horizontalalignment','left',...
                                               'Position',[x(1) lines(ii) 60 14],...
                                               'FontSize',fontsize,...
                                               'String',labels{ii},...
                                               'TooltipString',tooltip{ii});
  end
  
  for ii = 1:2
    h.main.pert.custom.par(ii,2) = uicontrol('Parent',h.main.pert.custom.pn(2),...
                                             'Style', 'edit',...
                                             'horizontalalignment','left',...
                                             'Position', [x(2) lines(ii) 130 20],...
                                             'TooltipString',tooltip{ii});
  end  
  
  labels = {'Matrix','Amplitude'};
  tooltip = {'Variable name','Max amplitude'};
  for ii = 1:length(labels)
    h.main.pert.custom.label(ii,3) = uicontrol('Parent',h.main.pert.custom.pn(3),...
                                               'Style','text',...
                                               'horizontalalignment','left',...
                                               'Position',[x(1) lines(ii) 60 14],...
                                               'FontSize',fontsize,...
                                               'String',labels{ii},...
                                               'TooltipString',tooltip{ii});
  end
  
  wdt = [130 60];
  for ii = 1:2
    h.main.pert.custom.par(ii,3) = uicontrol('Parent',h.main.pert.custom.pn(3),...
                                             'Style', 'edit',...
                                             'horizontalalignment','left',...
                                             'Position', [x(2) lines(ii) wdt(ii) 20],...
                                             'TooltipString',tooltip{ii});
  end  
    
  labels = {'File','Amplitude'};
  tooltip = {'Image file name','Max amplitude'};
  for ii = 1:length(labels)
    h.main.pert.custom.label(ii,4) = uicontrol('Parent',h.main.pert.custom.pn(4),...
                                               'Style','text',...
                                               'horizontalalignment','left',...
                                               'Position',[x(1) lines(ii) 60 14],...
                                               'FontSize',fontsize,...
                                               'String',labels{ii},...
                                               'TooltipString',tooltip{ii});
  end
  
  wdt = [80 60];
  for ii = 1:2
    h.main.pert.custom.par(ii,4) = uicontrol('Parent',h.main.pert.custom.pn(4),...
                                             'Style', 'edit',...
                                             'horizontalalignment','left',...
                                             'Position', [x(2) lines(ii) wdt(ii) 20],...
                                             'TooltipString',tooltip{ii});
  end  
  
  h.main.pert.custom.selectfile(2) = uicontrol('Parent',h.main.pert.custom.pn(4),...
                                            'Style', 'pushbutton',...
                                            'String', 'Browse',...
                                            'FontSize',8,...
                                            'Position', [x(3) lines(1) 60 20],...
                                            'Callback', {@select_figfile_CB,h.main.pert.custom.par(1,4)});  
    
  set(h.main.pert.custom.pn,'Visible','Off');
  
  % Update prm
  h.main.pert.update = uicontrol('Parent',h.main.pert.pn,...
                                 'Style', 'pushbutton',...
                                 'String', 'Update',...
                                 'FontSize',fontsize,...
                                 'Position', [10 10 60 20],...
                                 'TooltipString','Update perturbations');  


  % Reset prm
  h.main.pert.reset = uicontrol('Parent',h.main.pert.pn,...
                                 'Style', 'pushbutton',...
                                 'String', 'Reset',...
                                 'FontSize',fontsize,...
                                 'Position', [80 10 60 20],...
                                 'TooltipString','Reset perturbation parameters');
  
  
  % Add to list (to be implemented)
  h.main.pert.addtolist = uicontrol('Parent',h.main.pert.pn,...
                                    'Style', 'pushbutton',...
                                    'String', 'Add new',...
                                    'FontSize',fontsize,...
                                    'Position', [150 10 65 20],...
                                    'TooltipString','Add a new perturbation');
  

  
  %------------------------------------------------------------
  % Text box for showing the command to produce the model

  % h.main.cmd.cmd = uicontrol('Parent',h.main.cmd.pn,...
  %                            'Style', 'edit',...
  %                            'Position', [10 10 480 20],...
  %                            'HorizontalAlignment','left',...
  %                            'FontSize',fontsize,...
  %                            'String','');

  %------------------------------------------------------------
  % Perturbation list window
  h.list.f = figure('Color','white',...
                    'Units','pixels',...
                    'NumberTitle','Off',...
                    'Name','Perturbations',...
                    'Visible','Off',...
                    'menubar','none','toolbar','none');  
  
  
  pos = get(h.list.f,'Position');
  pos(3:4) = listfigsize;
  set(h.list.f,'Position',pos);  
  
  panelheight = listfigsize(2)-20;
  panelwidth = listfigsize(1)-20;
  h.list.pn = uipanel(h.list.f,'Title','Perturbations','FontSize',10,...
                      'BackgroundColor','white',...
                      'Units','pixels',...
                      'Position',[10 listfigsize(2)-panelheight panelwidth panelheight]);  
  
  lines = panelheight - (75:20:235);
  x = [10 120];
  for ii = 1:length(lines)

    h.list.pert.select(ii) = uicontrol('Parent',h.list.pn,...
                                       'Style', 'checkbox',...
                                       'Value',0,...
                                       'Position',[x(1) lines(ii) 100 20],...
                                       'HorizontalAlignment','left',...
                                       'enable', 'off',...
                                       'tag',num2str(ii),...
                                       'String','',...
                                       'FontSize',fontsize,...
                                       'TooltipString','Select to edit');

    h.list.pert.use(ii) = uicontrol('Parent',h.list.pn,...
                                    'Style', 'checkbox',...
                                    'Value',0,...
                                    'Position',[x(2) lines(ii) 20 20],...
                                    'HorizontalAlignment','left',...
                                    'enable', 'off',...
                                    'tag',num2str(ii),...
                                    'String','',...
                                    'FontSize',fontsize,...
                                    'TooltipString','Use this perturbation');
  end
  
  set(h.list.pert.select(1),'value',1,'enable','on');
  set(h.list.pert.use(1),'value',1,'enable','on');
  model.perturbation.current = 1;
  
  % Update prm
  h.list.pert.delete = uicontrol('Parent',h.list.pn,...
                                 'Style', 'pushbutton',...
                                 'String', 'Delete',...
                                 'FontSize',fontsize,...
                                 'Position', [10 10 60 20],...
                                 'TooltipString','Delete selected');    
  

  %------------------------------------------------------------
  % Revolution / extrusion profile window

  h.curve.f = figure('Color','white',...
                    'Units','pixels',...
                    'NumberTitle','Off',...
                    'Name','Curves',...
                    'Visible','Off',...
                    'menubar','none','toolbar','none');      
  
  pos = get(h.curve.f,'Position');
  pos(3:4) = curvefigsize;
  set(h.curve.f,'Position',pos);  
  
  panelheight(1) = 2/3*curvefigsize(2)-15;
  panelheight(2) = 1/3*curvefigsize(2)-15;
  panelwidth = curvefigsize(1)-20;
  h.curve.pn(1) = uipanel(h.curve.f,'Title','Revolution','FontSize',10,...
                      'BackgroundColor','white',...
                      'Units','pixels',...
                      'Position',[10 curvefigsize(2)-panelheight(1)-15 panelwidth panelheight(1)]);  
  h.curve.pn(2) = uipanel(h.curve.f,'Title','Extrusion','FontSize',10,...
                      'BackgroundColor','white',...
                      'Units','pixels',...
                      'Position',[10 10 panelwidth panelheight(2)]);  
  
  h.curve.ax(1) = axes('Parent',h.curve.pn(1),'Units','pixels','Position',[30 30 130 280]);
  h.curve.ax(2) = axes('Parent',h.curve.pn(2),'Units','pixels','Position',[30 30 130 130]);
    
  h.curve.reset(1) = uicontrol('Parent',h.curve.pn(1),...
                               'Style', 'pushbutton',...
                               'String', 'Reset',...
                               'FontSize',fontsize,...
                               'Position', [170 30 60 20],...
                               'TooltipString','Reset to default curve');   
 
  h.curve.reset(2) = uicontrol('Parent',h.curve.pn(2),...
                               'Style', 'pushbutton',...
                               'String', 'Reset',...
                               'FontSize',fontsize,...
                               'Position', [170 30 60 20],...
                               'TooltipString','Reset to default curve');   
 
  
  %------------------------------------------------------------
  % Profiles for revolution and extrusion

  pause(1)
  set(0,'CurrentFigure',h.curve.f);
  
  % Start with the default resolution for a revolution
  npoints = default.shape.revolution.npoints;
  
  xscale = 2;
  yscale = pi;

  connect = default.shape.revolution.curve(1).connect;
  interp = default.shape.revolution.curve(1).interp;
  
  %------------------------------------------------------------
  % Set up things for the revolution curve
  set(h.curve.f,'CurrentAxes',h.curve.ax(1));
  xlim = [-xscale xscale];
  ylim = [-yscale yscale];
  axis equal
  set(h.curve.ax(1),'XLim',xlim,'YLim',ylim,'Box','On');
  hold on

  % y = ylim;
  % x = xscale/2*[1 1];
  
  x = default.shape.revolution.curve(1).xdata;
  y = default.shape.revolution.curve(1).ydata;
  x1 = default.shape.revolution.curve(1).xsmooth;
  y1 = default.shape.revolution.curve(1).ysmooth;  
  

  h.curve.smooth_orig(1,1) = plot(x1,y1,'Visible','Off');
  h.curve.dat_orig(1,1) = plot(x,y,'Visible','Off');
  h.curve.smooth_orig(1,2) = plot(-x1,y1,'Visible','Off');
  h.curve.dat_orig(1,2) = plot(-x,y,'Visible','Off');
  
  h.curve.smooth(1,1) = plot(x1,y1,'-','color',.5*[1 1 1]);
  h.curve.dat(1,1) = plot(x,y,'o','MarkerEdgeColor',.1*[1 1 1],'MarkerFaceColor',.1*[1 1 1]);
  h.curve.smooth(1,2) = plot(-x1,y1,'-','Color',.75*[1 1 1]);
  h.curve.dat(1,2) = plot(-x,y,'o','MarkerFaceColor',.5*[1 1 1],'MarkerEdgeColor',.5*[1 1 1]);
  drawnow
    
  %------------------------------------------------------------
  % Set up things for the extrusion curve
  
  set(h.curve.f,'CurrentAxes',h.curve.ax(2));
  
  
  % polarplot exists only in Matlab 2016a and later; use code that works
  % in older versions.  Note that unlike Octave, Matlab's polar
  % doesn't support RLim.  You have to hack the axis limit by plotting
  % an invisible point at the wanted distance.
  
  plot(0,0,'ok','MarkerFaceColor','k');
  hold on    

  set(h.curve.ax(2),'XLim',xlim,'YLim',xlim);


  x = default.shape.revolution.curve(2).xdata;
  y = default.shape.revolution.curve(2).ydata;
  x1 = default.shape.revolution.curve(2).xsmooth;
  y1 = default.shape.revolution.curve(2).ysmooth;  
  
  h.curve.smooth_orig(2,1) = plot(x1,y1,'Visible','Off');
  h.curve.dat_orig(2,1) = plot(x,y,'Visible','Off');
  h.curve.smooth(2,1) = plot(x1,y1,'-','color',.5*[1 1 1]);
  h.curve.dat(2,1) = plot(x,y,'o','MarkerEdgeColor',.1*[1 1 1],'MarkerFaceColor',.1*[1 1 1]);
  
  axis equal
  
  drawnow  
  
  % Latest points
  set(h.curve.f,'CurrentAxes',h.curve.ax(1));
  h.curve.late(1) = plot(-100,-100,'o');
  set(h.curve.f,'CurrentAxes',h.curve.ax(2));
  h.curve.late(2) = plot(-100,-100,'o');
  set(h.curve.late,'MarkerEdgeColor',.1*[1 1 1],'MarkerFaceColor',.1*[1 1 1]);
  
  % Point being moved in a lighter color
  set(h.curve.f,'CurrentAxes',h.curve.ax(1));
  h.curve.move(1) = plot(-100,-100,'o','MarkerSize',8,...
                  'MarkerEdgeColor',.75*[1 1 1],...
                  'MarkerFaceColor',.75*[1 1 1]);
  
  set(h.curve.f,'CurrentAxes',h.curve.ax(2));
  h.curve.move(2) = plot(-100,-100,'o','MarkerSize',8,...
                  'MarkerEdgeColor',.75*[1 1 1],...
                  'MarkerFaceColor',.75*[1 1 1]);
  
  
  setappdata(h.curve.ax(1),'profiletype','linear');
  setappdata(h.curve.ax(2),'profiletype','polar');
  
  setappdata(h.curve.f,'npoints',npoints);
  setappdata(h.curve.f,'connect',connect);
  setappdata(h.curve.f,'interp',interp);
  %setappdata(h.curve.f,'rdata',r1);
  %setappdata(h.curve.f,'rdata_orig',r1);
  setappdata(h.curve.f,'usercurve',true);
  setappdata(h.curve.f,'useecurve',true);  
  
  %------------------------------------------------------------
  % Menus
  
  set(h.main.f,'menubar','none','toolbar','none');
  h.menu.file.main    = uimenu(h.main.f,'Label','&File');
  h.menu.file.new     = uimenu(h.menu.file.main,'Label','&New','Accelerator','N');
  h.menu.file.open    = uimenu(h.menu.file.main,'Label','&Open','Accelerator','O');
  h.menu.file.save    = uimenu(h.menu.file.main,'Label','&Save','Accelerator','S');
  h.menu.file.saveas  = uimenu(h.menu.file.main,'Label','Save &As');
  h.menu.file.quit  = uimenu(h.menu.file.main,'Label','&Quit','Accelerator','Q');

  h.menu.win.main     = uimenu(h.main.f,'Label','&Window');
  h.menu.win.list     = uimenu(h.menu.win.main,'Label','&List','Checked','off');
  h.menu.win.curve     = uimenu(h.menu.win.main,'Label','&Curves','Checked','off');
    
  %------------------------------------------------------------
  % Callbacks
  set(h.main.shape.shape,'Callback', {@updatemodel_CB,h});
  
  % set(h.main.shape.reso.npoints(1),'KeyReleaseFcn', {@updatemodelreso_CB,h,1});
  % set(h.main.shape.reso.npoints(2),'KeyReleaseFcn', {@updatemodelreso_CB,h,2});
  set(h.main.shape.reso.npoints(1),'Callback', {@updatemodelreso_CB,h,1});
  set(h.main.shape.reso.npoints(2),'Callback', {@updatemodelreso_CB,h,2});
  
  set(h.main.shape.height,'Callback', {@updatemodelheight_CB,h});
  set(h.main.shape.width,'Callback', {@updatemodelwidth_CB,h});
  set(h.main.shape.radius,'Callback', {@updatemodelradius_CB,h});
  set(h.main.shape.minor_radius,'Callback', {@updatemodelminorradius_CB,h});
  set(h.main.shape.super,'Callback', {@updatemodelsuper_CB,h});
  set(h.main.shape.rpar,'Callback', {@updatemodelrpar_CB,h});
  set(h.main.shape.caps,'Callback', {@updatemodelcaps_CB,h});
  set(h.main.shape.reset,'Callback', {@resetmodelprm_CB,h});
  
  set(h.main.prev.showax,'Callback',{@toggleaxes_CB,h});  
  set(h.main.export.var,'Callback',{@exportmodel_CB,h});
  set(h.main.export.btn,'Callback',{@exportmodel_CB,h});
  set(h.main.save.model.filename,'Callback',{@savemodel_CB,h});
  set(h.main.save.model.btn,'Callback',{@savemodel_CB,h});
  set(h.main.prev.reset.btn,'Callback',{@resetview_CB,h});

  set(h.main.pert.pert,'Callback', {@updatepert_CB,h});
  % set(h.main.pert.sine.reset.cpar,'Callback', {@resetpertprm_CB,h,'cpar'});
  % set(h.main.pert.sine.reset.mpar,'Callback', {@resetpertprm_CB,h,'mpar'});
  % set(h.main.pert.noise.reset.npar,'Callback', {@resetpertprm_CB,h,'npar'});
  % set(h.main.pert.noise.reset.mpar,'Callback', {@resetpertprm_CB,h,'mpar'});
  set(h.main.pert.update,'Callback', {@updatepertprm_CB,h});
  set(h.main.pert.reset,'Callback', {@resetpertprm_CB,h,[]});
  set(h.main.pert.addtolist,'Callback', {@addtolist_CB,h});

  set(h.list.pert.select,'Callback', {@selectpert_CB,h});
  set(h.list.pert.delete,'Callback', {@deletepert_CB,h});
  
  set(h.curve.reset(1),'CallBack',{@resetcurve_CB,h,1});
  set(h.curve.reset(2),'CallBack',{@resetcurve_CB,h,2});
  
  set(h.curve.f,'windowbuttondownfcn',{@starttrackmouse_CB,h});
  set(h.curve.f,'keypressfcn',{@keyfunc_CB,h});
    
  
  %------------------------------------------------------------
  % Normalized units for automatic resize
  
  setnormalized(h);
  
  %------------------------------------------------------------
  % Create and show the initial model
  setappdata(h.main.f,'model',model);
  setappdata(h.main.f,'default',default);

  setappdata(h.main.f,'fontsize',fontsize);
  setappdata(h.main.f,'margin',margin);
  setappdata(h.main.f,'col',col);
  
  p = default.perturbation.types;
  for ii = 1:length(p)
    resetpertprm(h,p{ii});  
  end
  
  updatelist(h);
  updatemodel(h);
  resetview(h);

  %------------------------------------------------------------
  % Menu callbacks

  set(h.menu.file.new,'CallBack',{@newproject_CB,h});
  set(h.menu.file.open,'CallBack',{@openproject_CB,h});
  set(h.menu.file.save,'CallBack',{@saveproject_CB,h});
  set(h.menu.file.saveas,'CallBack',{@saveprojectas_CB,h});
  set(h.menu.file.quit,'CallBack',{@closeapp_CB,h,'main'});

  set(h.menu.win.list,'CallBack',{@togglewin_CB,h,'list'});
  set(h.menu.win.curve,'CallBack',{@togglewin_CB,h,'curve'});
  
  % Close request callabcks have to be registered after the menu
  % items are created above.
  set(h.main.f,'CloseRequestFcn',{@closeapp_CB,h,'main'});
  set(h.list.f,'CloseRequestFcn',{@closeapp_CB,h,'list'});
  set(h.curve.f,'CloseRequestFcn',{@closeapp_CB,h,'curve'});
  
  %------------------------------------------------------------
  % Show the main window
  
  % Start at center
  if ~isoctave
    movegui(h.main.f,'center')
  end

  % Show it
  set(h.main.f,'Visible','On');
  % set(h.list.f,'Visible','On');

  % keyboard

  
end % End main program

%------------------------------------------------------------
%------------------------------------------------------------
% Functions hereafter

% First callbacks:

% Menus

function newproject_CB(src,event,h)

  default = getappdata(h.main.f,'default');
  % setappdata(h.main.f,'model',default);
  
  % Copy parameter values from default fields for each shape
  fns = fieldnames(default.shape);
  for ii = 1:length(fns)
    model.shape.(fns{ii}) = default.shape.(fns{ii});
  end  
  
  % Copy parameter values from default fields for each shape
  fns = fieldnames(default.perturbation);
  model.perturbation.list = [];
  for ii = 1:length(fns)
    model.perturbation.list(1).(fns{ii}) = default.perturbation.(fns{ii});
  end
  
  % The perturbation being edited.
  model.perturbation.current = 1;
  model.perturbation.use = 1;
  
  % List of perturbations:
  %model.list = [];
  
  % Field m holds the actual model
  model.m = [];
  
  setappdata(h.main.f,'model',model);
  
  setappdata(h.main.f,'projectfilepath',[]);
  setappdata(h.main.f,'projectfilename',[]);
    
  updatelist(h);  
  updatemodel(h);
  resetview(h);  

end

function saveprojectas_CB(src,event,h)
  
  model = getappdata(h.main.f,'model');
  
  [filename,filepath] = uiputfile(...
      {'*.mat','Matlab/Octave files (*.mat)';...
       '*.*','All Files (*.*)'},...
      'Save project to file');
  
  if isequal(filename,0) || isequal(filepath,0)
    return
  end
    
  save('-v7',fullfile(filepath,filename),'model');
  
  setappdata(h.main.f,'projectfilepath',filepath);
  setappdata(h.main.f,'projectfilename',filename);

end

function saveproject_CB(src,event,h)
  
  model = getappdata(h.main.f,'model');

  filepath = getappdata(h.main.f,'projectfilepath');
  filename = getappdata(h.main.f,'projectfilename');
  
  ok = true;
  if isempty(filepath) || isempty(filename)
    ok = false;
  elseif ~exist(filepath,'dir')
    ok = false;
  end
  
  if ~ok
    [filename,filepath] = uiputfile(...
        {'*.mat','Matlab/Octave files (*.mat)';...
         '*.*','All Files (*.*)'},...
        'Save project to file');
  end
  
  if isequal(filename,0) || isequal(filepath,0)
    return
  end  
  
  save('-v7',fullfile(filepath,filename),'model');

end

function openproject_CB(src,event,h)
  
  [filename,filepath] = uigetfile(...
      {'*.mat','Matlab/Octave files (*.mat)';...
       '*.*','All Files (*.*)'},...
      'Select project file');
  
  if isequal(filename,0) || isequal(filepath,0)
    return
  end  
  
  model = load(fullfile(filepath,filename));
  
  ok = checkinput(model);
  
  if ~ok
    msgbox('Failed to open file. Not a valid project file.',...
           'Invalid file');
    return
  end
  
  setappdata(h.main.f,'projectfilepath',filepath);
  setappdata(h.main.f,'projectfilename',filename);
  setappdata(h.main.f,'model',model.model);
  
  % This is a bit clumsy to have here....
  for ii = 1:length(model.model.perturbation.use)
    set(h.list.pert.use(ii),'value',model.model.perturbation.use(ii));
  end

  if length(model.model.perturbation.list)>1
    set(h.menu.win.list,'Checked','on');
    set(h.list.f,'Visible','On');
  end
    
  updatelist(h);
  updatemodel(h);
  resetview(h);
  
end

%------------------------------------------------------------
% Shape:

function updatemodel_CB(src,event,h)
  s = get(src,'value');
  shapes = get(src,'String');
  model = getappdata(h.main.f,'model');
  model.shape.shape = shapes{s};
  setappdata(h.main.f,'model',model);
  updatemodel(h);
  openwin(h,'curve');
end

function updatemodelreso_CB(src,event,h,idx)
  % key = get(gcf,'CurrentKey');
  % if strcmp(key,'return')
  model = getappdata(h.main.f,'model');
  model.shape.(model.shape.shape).npoints(idx) = uint32(str2num(get(src,'String')));
  setappdata(h.main.f,'model',model);
  updatemodel(h);
  %end
end

function updatemodelheight_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  switch model.shape.shape
    case {'plane','cylinder','revolution','extrusion','worm'}
      model.shape.(model.shape.shape).height = get(src,'String');
  end
  setappdata(h.main.f,'model',model);
  updatemodel(h);
end

function updatemodelwidth_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  switch model.shape.shape
    case 'plane'
      model.shape.(model.shape.shape).width = get(src,'String');
  end
  setappdata(h.main.f,'model',model);
  updatemodel(h);
end

function updatemodelminorradius_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  switch model.shape.shape
    case 'torus'
      model.shape.(model.shape.shape).minor_radius = get(src,'String');
  end
  setappdata(h.main.f,'model',model);
  updatemodel(h);
end

function updatemodelradius_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  switch model.shape.shape
    case {'sphere','ellipsoid','torus','cylinder','revolution','extrusion','worm','disk'}
      model.shape.(model.shape.shape).radius = get(src,'String');
  end
  setappdata(h.main.f,'model',model);
  updatemodel(h);
end

function updatemodelsuper_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  switch model.shape.shape
    case {'ellipsoid','torus'}
      model.shape.(model.shape.shape).super = get(src,'String');
  end    
  setappdata(h.main.f,'model',model);
  updatemodel(h);
end

function updatemodelrpar_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  switch model.shape.shape
    case 'torus'
      model.shape.(model.shape.shape).rpar = get(src,'String');
  end
  setappdata(h.main.f,'model',model);
  updatemodel(h);
end  

function updatemodelcaps_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  switch model.shape.shape
    case {'cylinder','revolution','extrusion','worm'}
      model.shape.(model.shape.shape).caps = get(src,'Value');
  end
  setappdata(h.main.f,'model',model);
  updatemodel(h);
end

function resetmodelprm_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  resetmodelprm(h,model.shape.shape);
  updatemodel(h);
end  

function resetmodelprm(h,shape)
  model = getappdata(h.main.f,'model');
  default = getappdata(h.main.f,'default');
  switch model.shape.shape
    case {'revolution','extrusion','worm'}  
      tmp = model.shape.(shape).curve;
      model.shape.(shape) = default.shape.(shape);
      model.shape.(shape).curve = tmp;
    otherwise
      model.shape.(shape) = default.shape.(shape);
  end
  setappdata(h.main.f,'model',model);
end

%------------------------------------------------------------
% Preview:

function toggleaxes_CB(src,event,h)
  show = get(src,'Value');
  if show
    set(h.main.prev.ax,'Visible','On');
    % xlabel('x');
    % ylabel('z');
    % zlabel('y');
  else
    set(h.main.prev.ax,'Visible','Off');
  end
end

function exportmodel_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  htmp = h.main.export.var;
  bgcol = get(htmp,'BackgroundColor');
  varname = get(htmp,'String');
  try
    assignin('base',varname,model.m);
    set(htmp,'BackgroundColor',[.2 .8 .2]);
  catch
    set(htmp,'BackgroundColor',[1 .2 .2]);
  end    
  pause(.2);
  set(htmp,'BackgroundColor',bgcol);
end

function savemodel_CB(src,event,h)
  model = getappdata(h.main.f,'model');
  htmp = h.main.save.model.filename;
  bgcol = get(htmp,'BackgroundColor');
  
  filename = get(htmp,'String');
  if isempty(filename)
    set(htmp,'BackgroundColor',[1 .2 .2]);
  else
    try
      if isempty(regexp(filename,'\.obj$'))
        filename = [filename,'.obj'];
      end
      model.m = objSet(model.m,'filename',filename);
      objSave(model.m);
      set(htmp,'BackgroundColor',[.2 .8 .2]);
    catch
      set(htmp,'BackgroundColor',[1 .2 .2]);
    end
  end
  pause(.2);
  set(htmp,'BackgroundColor',bgcol);
end

function resetview_CB(src,event,h)
  resetview(h);
end

%------------------------------------------------------------
% Perturbations:

function updatepert_CB(src,event,h)
  
% Switch perturbation type
  
  model = getappdata(h.main.f,'model');
  p = get(src,'value');
  perts = get(src,'String');
  idx = model.perturbation.current;
  model.perturbation.list(idx).name = perts{p};
  setappdata(h.main.f,'model',model);
  updatelist(h);
  updatemodel(h);
end

function updatepertprm_CB(src,event,h)
  updatepertprm(h);
  updatemodel(h);
end

function updatepertprm(h)
  
% Read perturbation values from the fields in the gui, save them in
% the model structure.
  
  model = getappdata(h.main.f,'model');
  idx = model.perturbation.current;
  switch model.perturbation.list(idx).name
    case 'none'
      ;
    case 'sine'
      cpar = [];
      for ii = 1:size(h.main.pert.sine.cpar,1)
        for jj = 1:size(h.main.pert.sine.cpar,2)
          val = str2num(get(h.main.pert.sine.cpar(ii,jj),'String'));
          if isempty(val)
            if jj>1
              cpar(ii,:) = [];
            end
            break
          else
            cpar(ii,jj) = val;
          end
        end
      end

      mpar = [];
      for ii = 1:size(h.main.pert.sine.mpar,1)
        for jj = 1:size(h.main.pert.sine.mpar,2)
          val = str2num(get(h.main.pert.sine.mpar(ii,jj),'String'));
          if isempty(val)
            if jj>1
              mpar(ii,:) = [];
            end
            break
          else
            mpar(ii,jj) = val;
          end            
        end
      end
      
      model.perturbation.list(idx).sine.cpar = cpar;
      model.perturbation.list(idx).sine.mpar = mpar;
      
      val = str2num(get(h.main.pert.sine.tilt(1),'String'));
      model.perturbation.list(idx).sine.tiltaxis = val;
      val = str2num(get(h.main.pert.sine.tilt(2),'String'));
      model.perturbation.list(idx).sine.tiltangle = val;
      
    case 'noise'
      npar = [];
      for ii = 1:size(h.main.pert.noise.npar,1)
        for jj = 1:size(h.main.pert.noise.npar,2)
          val = str2num(get(h.main.pert.noise.npar(ii,jj),'String'));
          if isempty(val)
            if jj>1
              npar(ii,:) = [];
            end
            break
          else
            npar(ii,jj) = val;
          end
        end
      end

      mpar = [];
      for ii = 1:size(h.main.pert.noise.mpar,1)
        for jj = 1:size(h.main.pert.noise.mpar,2)
          val = str2num(get(h.main.pert.noise.mpar(ii,jj),'String'));
          if isempty(val)
            if jj>1
              mpar(ii,:) = [];
            end
            break
          else
            mpar(ii,jj) = val;
          end            
        end
      end
      
      model.perturbation.list(idx).noise.npar = npar;
      model.perturbation.list(idx).noise.mpar = mpar;
    
    case 'bump'
      par = [];
      for ii = 1:size(h.main.pert.bump.par,1)
        for jj = 1:size(h.main.pert.bump.par,2)
          val = str2num(get(h.main.pert.bump.par(ii,jj),'String'));
          if isempty(val)
            if jj>1
              par(ii,:) = [];
            end
            break
          else
            par(ii,jj) = val;
          end
        end
      end
      
      model.perturbation.list(idx).bump.par = par;
    
    case 'custom'
      par = {{},{},{},{}};
      for ii = 1:size(h.main.pert.custom.par,2)
        val = get(h.main.pert.custom.par(1,ii),'String');
        if isempty(val)
          continue
        else
          par{ii}{1} = val;
          val = str2num(get(h.main.pert.custom.par(2,ii),'String'));
          par{ii}{2} = val;
        end
      end
      
      model.perturbation.list(idx).custom.par = par;
      
  end
  setappdata(h.main.f,'model',model);
end

function resetpertprm_CB(src,event,h,field)
  model = getappdata(h.main.f,'model');
  idx = model.perturbation.current;
  update = resetpertprm(h,model.perturbation.list(idx).name,field);
  if update
    updatemodel(h);
  end
end  

function addtolist_CB(src,event,h)
  updatepertprm(h);
  model = getappdata(h.main.f,'model');
  default = getappdata(h.main.f,'default');
  idx = model.perturbation.current;
  
  n = length(model.perturbation.list) + 1;

  fns = fieldnames(default.perturbation);
  for ii = 1:length(fns)
    model.perturbation.list(n).(fns{ii}) = default.perturbation.(fns{ii});
  end
  
  model.perturbation.current = n;
 
  set(h.list.pert.use(n),'value',1);
  
  % set(h.menu.win.list,'Checked','on');
  % set(h.list.f,'Visible','On');  
  
  setappdata(h.main.f,'model',model);
  updatelist(h);
  updatemodel(h);
  
end

function selectpert_CB(src,event,h)

  model = getappdata(h.main.f,'model');
  idx = str2num(get(src,'tag'));
  
  model.perturbation.current = idx;
  setappdata(h.main.f,'model',model);
  updatelist(h);  
  updatemodel(h);
end

function deletepert_CB(src,event,h)

  model = getappdata(h.main.f,'model');
  idx = model.perturbation.current;
  if idx~=length(model.perturbation.list)
    model.perturbation.list(idx) = [];
  end
  setappdata(h.main.f,'model',model);
  updatelist(h);  
  updatemodel(h);
end

function select_mfile_CB(src,event,h)
  [filename,filepath] = uigetfile(...
      {'*.m','m-files (*.m)';... % 
       '*.*','All Files (*.*)'},...
      'Select function file');
  set(h,'String',fullfile(filepath,filename));
end

function select_figfile_CB(src,event,h)
  [filename,filepath] = uigetfile(...
      {'*.tiff;*.jpg;*.jpeg;*.png','Image files (*.tiff;*.jpg;*.jpeg;*.png)';... % 
       '*.*','All Files (*.*)'},...
      'Select image to use as height map');
  set(h,'String',fullfile(filepath,filename));
end

function updatelist(h) 
  model = getappdata(h.main.f,'model');
  idx = model.perturbation.current;
  npert = length(model.perturbation.list);
  for ii = 1:length(h.list.pert.select)
    if ii<=npert
      
      str = sprintf('%2d. %s',ii,model.perturbation.list(ii).name);
      
      if ii==npert
        str = sprintf('%s (new)',str);
      end
      
      set(h.list.pert.select(ii),...
          'enable','on',...
          'String', str);
      
      set(h.list.pert.use(ii),'enable','on');
      
      % set(h.list.pert.select(ii),'foregroundcolor',col);

      if ii == idx
        set(h.list.pert.select(ii),'Value',1,'fontweight','bold');
      else
        set(h.list.pert.select(ii),'Value',0,'fontweight','normal');
      end
    else
      set(h.list.pert.use(ii),'enable','off','Value',0);
      set(h.list.pert.select(ii),'enable','off','Value',0,'fontweight','normal','String','');
    end
  end
end

function update = resetpertprm(h,pert,field)
% Reset perturbation parameters to default values.
  
  update = true;
  model = getappdata(h.main.f,'model');
  idx = model.perturbation.current;
  default = getappdata(h.main.f,'default');
  if nargin>2 && ~isempty(field)
    v1 = model.perturbation.list(idx).(pert).(field);
    v2 = default.perturbation.(pert).(field);
    if isequal(v1,v2)
      update = false;
      clear v1 v2
      return
    end
    clear v1 v2
    model.perturbation.list(idx).(pert).(field) = default.perturbation.(pert).(field);
  else
    v1 = model.perturbation.list(idx).(pert);
    v2 = default.perturbation.(pert);
    if isequal(v1,v2)
      update = false;
      clear v1 v2
      return
    end
    clear v1 v2    
    model.perturbation.list(idx).(pert) = default.perturbation.(pert);
  end
  setappdata(h.main.f,'model',model);
end

%------------------------------------------------------------
% Other functions:

function updatemodel(h)
  
% Update the model structure. Fetch the correct parameters for
% shape and perturbation, put them into the 'current' field, and
% also write them into the fields of the gui.
  
  model = getappdata(h.main.f,'model');
  ipert = model.perturbation.current;
  fontsize = getappdata(h.main.f,'fontsize');
  margin = getappdata(h.main.f,'margin');
  col = getappdata(h.main.f,'col');    
  
  % Fetch model shape and perturbation, and set them in the
  % pulldown menus so that them menus show correct setting also
  % when loading a saved project
  shapes = get(h.main.shape.shape,'String');
  idx = find(cellfun(@(x) isequal(x,model.shape.shape), shapes));
  set(h.main.shape.shape,'Value',idx);

  perts = get(h.main.pert.pert,'String');
  idx = find(cellfun(@(x) isequal(x,model.perturbation.list(ipert).name), perts));
  set(h.main.pert.pert,'Value',idx);
  
  set(h.main.shape.height_lab,'foregroundcolor',col.txt.inact);
  set(h.main.shape.height,'enable','off');
  set(h.main.shape.width_lab,'foregroundcolor',col.txt.inact);
  set(h.main.shape.width,'enable','off');
  set(h.main.shape.radius_lab,'foregroundcolor',col.txt.inact);
  set(h.main.shape.radius,'enable','off');
  set(h.main.shape.minor_radius_lab,'foregroundcolor',col.txt.inact);
  set(h.main.shape.minor_radius,'enable','off');
  set(h.main.shape.super_lab,'foregroundcolor',col.txt.inact);
  set(h.main.shape.super,'enable','off');
  set(h.main.shape.rpar_lab,'foregroundcolor',col.txt.inact);
  set(h.main.shape.rpar,'enable','off');
  set(h.main.shape.caps,'enable','off');
  set(h.main.shape.reso.npoints(1),'String',num2str(model.shape.(model.shape.shape).npoints(1)));
  set(h.main.shape.reso.npoints(2),'String',num2str(model.shape.(model.shape.shape).npoints(2)));    
  
  set(h.curve.reset,'enable','off');
  
  model.shape.current = struct();
  model.shape.current.npoints = model.shape.(model.shape.shape).npoints;    
  
  switch model.shape.shape
    case 'sphere'
      % TODO Check and fix radius vector length
      % TODO The thing below could be automated instead of
      % explicitly using switch
      set(h.main.shape.radius_lab,'String','Radius (r)','foregroundcolor',col.txt.act);
      set(h.main.shape.radius,'String',model.shape.sphere.radius,'enable','on');
      model.shape.current.radius = str2num(model.shape.sphere.radius);
    case {'cylinder','revolution','extrusion','worm'}
      set(h.main.shape.caps,'enable','on');
      model.shape.current.caps = model.shape.(model.shape.shape).caps;

      set(h.main.shape.height_lab,'foregroundcolor',col.txt.act);
      set(h.main.shape.height,'String',model.shape.(model.shape.shape).height,'enable','on');
      model.shape.current.height = str2num(model.shape.(model.shape.shape).height);

      set(h.main.shape.radius_lab,'String','Radius (r)','foregroundcolor',col.txt.act);
      set(h.main.shape.radius,'String',model.shape.(model.shape.shape).radius,'enable','on');
      model.shape.current.radius = str2num(model.shape.(model.shape.shape).radius);
      
      if ~strcmp(model.shape.shape,'cylinder')
        model.shape.current.rcurve = model.shape.(model.shape.shape).curve(1).rcurve;
        model.shape.current.ecurve = model.shape.(model.shape.shape).curve(2).ecurve;
        set(h.curve.reset,'enable','on');
      end
      
    case 'ellipsoid'
      set(h.main.shape.super_lab,'String','Superellipsoid prm','foregroundcolor',col.txt.act);
      set(h.main.shape.super,'String',model.shape.ellipsoid.super,'enable','on');
      model.shape.current.super = str2num(model.shape.ellipsoid.super);

      tooltip = 'Radius of ellipsoid, either one (r) or three values (rx, ry, rz)';
      set(h.main.shape.radius_lab,'String','Radius (rx, ry, rz)','foregroundcolor',col.txt.act,'TooltipString',tooltip);
      set(h.main.shape.radius,'String',model.shape.ellipsoid.radius,'enable','on','TooltipString',tooltip);
      model.shape.current.radius = str2num(model.shape.ellipsoid.radius);
    case 'torus'
      set(h.main.shape.super_lab,'String','Supertorus prm','foregroundcolor',col.txt.act);
      set(h.main.shape.super,'String',model.shape.torus.super,'enable','on');
      model.shape.current.super = str2num(model.shape.torus.super);

      tooltip = 'Radius of torus, either one or two values';
      set(h.main.shape.radius_lab,'String','Radius (rx, rz)','foregroundcolor',col.txt.act,'TooltipString',tooltip);
      set(h.main.shape.radius,'String',model.shape.torus.radius,'enable','on','TooltipString',tooltip);
      model.shape.current.radius = str2num(model.shape.torus.radius);
      
      set(h.main.shape.minor_radius_lab,'foregroundcolor',col.txt.act);
      set(h.main.shape.minor_radius,'String',model.shape.torus.minor_radius,'enable','on');
      model.shape.current.minor_radius = str2num(model.shape.torus.minor_radius);
      
      set(h.main.shape.rpar_lab,'foregroundcolor',col.txt.act);
      set(h.main.shape.rpar,'String',model.shape.torus.rpar,'enable','on');
      if ~isempty(model.shape.torus.rpar)
        model.shape.current.rpar = str2num(model.shape.torus.rpar);
      end
    case 'plane'
      set(h.main.shape.height_lab,'foregroundcolor',col.txt.act);
      set(h.main.shape.height,'String',model.shape.plane.height,'enable','on');
      model.shape.current.height = str2num(model.shape.plane.height);
      
      set(h.main.shape.width_lab,'foregroundcolor',col.txt.act);
      set(h.main.shape.width,'String',model.shape.plane.width,'enable','on');
      model.shape.current.width = str2num(model.shape.plane.width);
    case 'disk'
      set(h.main.shape.radius_lab,'String','Radius (r)','foregroundcolor',col.txt.act);
      set(h.main.shape.radius,'String',model.shape.disk.radius,'enable','on');
      model.shape.current.radius = str2num(model.shape.disk.radius);
  end
  
  fn = fieldnames(model.shape.current);
  prm = {};
  for ii = 1:length(fn)
    prm{2*ii-1} = fn{ii};
    prm{2*ii}   = model.shape.current.(fn{ii});
  end
  clear fn
  
  model.m = objMakePlain(model.shape.shape,prm{:});
  
  % Perturbations
  
  % Add perturbations in the list
  usepert = [1];
  if length(model.perturbation.list)
    for ii = 1:length(model.perturbation.list)
      switch model.perturbation.list(ii).name
        case 'sine'
          cpar = model.perturbation.list(ii).sine.cpar;
          mpar = model.perturbation.list(ii).sine.mpar;
          tiltaxis = model.perturbation.list(ii).sine.tiltaxis;
          tiltangle = model.perturbation.list(ii).sine.tiltangle;
          if ~isempty(tiltaxis) && ~isempty(tiltangle)
            model.m = objMakeSine(model.m,cpar,mpar,'axis',tiltaxis,'angle',tiltangle);
          else
            model.m = objMakeSine(model.m,cpar,mpar);
          end
          usepert = [usepert get(h.list.pert.use(ii),'value')];
        case 'noise'
          npar = model.perturbation.list(ii).noise.npar;
          mpar = model.perturbation.list(ii).noise.mpar;
          model.m = objMakeNoise(model.m,npar,mpar);
          usepert = [usepert get(h.list.pert.use(ii),'value')];
        case 'bump'
          par = model.perturbation.list(ii).bump.par;
          model.m = objMakeBump(model.m,par);          
          usepert = [usepert get(h.list.pert.use(ii),'value')];
        case 'custom'
          for jj = 1:4
            par = model.perturbation.list(ii).custom.par{jj};
            if isempty(par)
              % fprintf('%d: Empty custom par.\n',jj);
              continue
            end
            if jj==1
              keyboard
              model.m = objMakeCustom(model.m,eval(par{1}),par{2});
            elseif jj==2
              if par{1}(1)~='@', par{1} = sprintf('@%s',par{1}); end
              model.m = objMakeCustom(model.m,eval(par{1}),par{2});
            elseif jj==3
              model.m = objMakeCustom(model.m,evalin('base',par{1}),par{2});
            else
              model.m = objMakeCustom(model.m,par{1},par{2});
            end
            usepert = [usepert get(h.list.pert.use(ii),'value')];
          end
      end
    end
  end

  % model.perturbation.use = usepert;

  % This is just for saving and loading the model, to keep the
  % checkbox values in the perturbation list. The vector usepert
  % created above will actually be passed to the objSet-function,
  % as it skips 'none'-perturbations (except the first one).
  model.perturbation.use = [];
  for ii = 1:length(h.list.pert.use) 
    model.perturbation.use(ii) = get(h.list.pert.use(ii),'value');
  end
  
  % Show params only for current perturbation, hide
  % others. Initially I just set everything invisible, then set the
  % current one visible, but that caused a visible hide/show in
  % Octave when the model was updated but perturbation types was
  % the same. So now we loop through perturbations to avoid that.

  fn = model.perturbation.list(ipert).types;
  for ii = 1:length(fn)
    if strcmp(fn{ii},model.perturbation.list(ipert).name)
      set(h.main.pert.(fn{ii}).pn,'visible','on');
    else
      set(h.main.pert.(fn{ii}).pn,'visible','off');
    end
  end
  clear fn
  
  % Hide buttons for reset, addtolist for 'none'
  if strcmp(model.perturbation.list(ipert).name,'none')
    set(h.main.pert.update,'visible','on');
    set(h.main.pert.reset,'visible','off');
    set(h.main.pert.addtolist,'visible','off');
  else
    set(h.main.pert.update,'visible','on');
    set(h.main.pert.reset,'visible','on');
    set(h.main.pert.addtolist,'visible','on');
  end  
  
  switch model.perturbation.list(ipert).name
    case 'none'
      ;
    case 'sine'
      writesineprm(h,model);
    case 'noise'
      writenoiseprm(h,model); 
    case 'bump'
      writebumpprm(h,model); 
    case 'custom'
      writecustomprm(h,model); 
  end
  
  % update rev/ext curves to match the current model (in case model
  % was changed from pull down menu)
  switch model.shape.shape
    case {'revolution','extrusion','worm'}
      updatecurves(model,h)
  end
  
  % % The first one is always the plain model with no perturbation
  % usepert = [1];  
  % % Include / exclude the perturbations in the list
  % for ii = 1:length(model.perturbation.list)
  %   usepert(ii+1) = get(h.list.pert.use(ii),'value');
  % end
  % numel(usepert)
  % numel(model.m.flags.use_perturbation)
  
  model.m = objSet(model.m,'use_perturbation',usepert);

  setappdata(h.main.f,'model',model);
  
  showmodel(h);

  % set(h.main.cmd.cmd,'String','m = objMakePlain() TODO TODO TODO');
  
end

function showmodel(h)
  
% Show model preview in the preview axis
  
  model = getappdata(h.main.f,'model');
  axes(h.main.prev.ax);
  visible = get(h.main.prev.showax,'value');
  try
    objView(model.m,[],get(gca,'CameraPosition'),visible);
  catch
    objView(model.m,[],[],visible);
  end
end

function resetview(h)
  
% Set default view of the model
  
  model = getappdata(h.main.f,'model');
  axes(h.main.prev.ax);
  visible = get(h.main.prev.showax,'value');
  objView(model.m,[],[],visible);
end

% function v = fixlength(u,n)
% % TODO

%   v = [];

% end

function setnormalized(h)
  
% setnormalized
%
% Set all parts of the gui to use normalized units (they are
% initialized in pixels) to enable resizing of the window. Recurse
% into every field of the handle structure.
  
  if isstruct(h)
    f = fieldnames(h);
    for ii = 1:length(f)
      setnormalized(h.(f{ii}));
    end
  elseif any(ishandle(h))
    for ii = 1:numel(h)
      if ishandle(h(ii))
        try
          set(h(ii),'units','normalized');
        end
      end
    end
  end
end


function writesineprm(h,model)
  
% writesineprm
% 
% Write sine parameters from the model structure to the fields in
% the gui.
  
  idx = model.perturbation.current;
  
  cpar = model.perturbation.list(idx).sine.cpar;
  mpar = model.perturbation.list(idx).sine.mpar;  
  
  for ii = 1:size(h.main.pert.sine.cpar,1)
    for jj = 1:size(h.main.pert.sine.cpar,2)
      if size(cpar,1)>=ii
        val = num2str(cpar(ii,jj));
      else
        val = '';
      end
      set(h.main.pert.sine.cpar(ii,jj),'String',val);
    end
  end
  
  for ii = 1:size(h.main.pert.sine.mpar,1)
    for jj = 1:size(h.main.pert.sine.mpar,2)
      if size(mpar,1)>=ii
        val = num2str(mpar(ii,jj));
      else
        val = '';
      end
      set(h.main.pert.sine.mpar(ii,jj),'String',val);
    end
  end
  
  tiltaxis = model.perturbation.list(idx).sine.tiltaxis;
  val = num2str(tiltaxis);
  set(h.main.pert.sine.tilt(1),'String',val);
  
  tiltangle = model.perturbation.list(idx).sine.tiltangle;
  val = num2str(tiltangle);
  set(h.main.pert.sine.tilt(2),'String',val);


end

function writenoiseprm(h,model)

% writenoiseprm
% 
% Write noise parameters from the model structure to the fields in
% the gui.

  idx = model.perturbation.current;
  
  npar = model.perturbation.list(idx).noise.npar;
  mpar = model.perturbation.list(idx).noise.mpar;  
  
  for ii = 1:size(h.main.pert.noise.npar,1)
    for jj = 1:size(h.main.pert.noise.npar,2)
      if size(npar,1)>=ii
        val = num2str(npar(ii,jj));
      else
        val = '';
      end
      set(h.main.pert.noise.npar(ii,jj),'String',val);
    end
  end
  
  for ii = 1:size(h.main.pert.noise.mpar,1)
    for jj = 1:size(h.main.pert.noise.mpar,2)
      if size(mpar,1)>=ii
        val = num2str(mpar(ii,jj));
      else
        val = '';
      end
      set(h.main.pert.noise.mpar(ii,jj),'String',val);
    end
  end

end

function writebumpprm(h,model)

% writebumpprm
% 
% Write bump parameters from the model structure to the fields in
% the gui.
  
  idx = model.perturbation.current;
  
  par = model.perturbation.list(idx).bump.par;
  
  for ii = 1:size(h.main.pert.bump.par,1)
    for jj = 1:size(h.main.pert.bump.par,2)
      if size(par,1)>=ii
        val = num2str(par(ii,jj));
      else
        val = '';
      end
      set(h.main.pert.bump.par(ii,jj),'String',val);
    end
  end
  
end

function writecustomprm(h,model)
  
  idx = model.perturbation.current;
  par = model.perturbation.list(idx).custom.par;
  
  for jj = 1:size(par,2)
    if isempty(par{jj})
      val1 = '';
      val2 = '';
    else
      if isempty(par{jj}{1})
        val1 = '';
      else
        val1 = par{jj}{1};
      end
      if isempty(par{jj}{2})
        val2 = '';
      else
        val2 = num2str(par{jj}{2});
      end
    end
    set(h.main.pert.custom.par(1,jj),'String',val1);
    set(h.main.pert.custom.par(2,jj),'String',val2);    
  end

end

function ok = checkinput(model)

  ok = true;
  if ~isfield(model,'model'), ok = false; return; end
  if ~isfield(model.model,'shape'), ok = false; return; end
  if ~isfield(model.model,'perturbation'), ok = false; return; end
  if ~isfield(model.model,'m'), ok = false; return; end
    
end

%------------------------------------------------------------
% App window close funcs

function closeapp_CB(src,event,h,win)

  if strcmp(win,'main')
    delete(h.curve.f);
    delete(h.list.f);
    delete(h.main.f);
  else
    idx = strmatch(win,{'list','curve','spine'});
    set(h.menu.win.(win),'Checked','off');
    set(h.(win).f,'Visible','Off');
    fprintf('Close the main window to exit.\n');
  end
end

function togglewin_CB(src,event,h,win)
  
  checked = strcmp(lower(get(src,'Checked')),'on');
  
  if checked
    set(src,'Checked','off');
    set(h.(win).f,'Visible','Off');
  else
    set(src,'Checked','on');    
    set(h.(win).f,'Visible','On');
  end

end

function openwin(h,win)
  set(h.menu.win.(win),'Checked','on');    
  set(h.(win).f,'Visible','On');  
end

%------------------------------------------------------------
% Profile curves

function keyfunc_CB(src,data,h)
  switch data.Key
    case 'return'
      %   set(gcf,'windowbuttondownfcn','');
      %   set(gcf,'windowbuttonupfcn','');
      %   set(0,'userdata',true);
      updatemodel(h);
    case 'plus'
      xlim = get(gca,'XLim');
      xlim(2) = xlim(2) + .5;
      set(gca,'XLim',xlim);
      drawnow
    case 'minus'
      xlim = get(gca,'XLim');
      xlim(2) = xlim(2) - .5;
      set(gca,'XLim',xlim);
      drawnow
    case 'r'
      drawnow
  end
end


function starttrackmouse_CB(src,data,h)
  
  model = getappdata(h.main.f,'model');

  switch model.shape.shape
    case {'revolution','extrusion','worm'}
      ;
    otherwise
      set(src,'windowbuttonupfcn','');
      return
  end
  
  figure(src);

  profiletype = getappdata(gca,'profiletype');
  pidx = strmatch(profiletype,{'linear','polar'});
  
  % Get handle to plotted points
  hdat = h.curve.dat;
  % Get x and y coords
  x = get(hdat(pidx,1),'xdata');
  y = get(hdat(pidx,1),'ydata');
  % Get point where mouse down
  pos = get(gca,'currentpoint');
  % If distance to closest data point is smaller than some arb
  % cutoff, assume observer chose that point and is moving /
  % deleting it. Otherwise, create new point.
  dist = sqrt((x-pos(1,1)).^2+(y-pos(1,2)).^2);
  
  
  if min(dist)<.2
    idx = find(dist==min(dist));
    xtmp = x(idx);
    ytmp = y(idx);
    hmove = h.curve.move; 
    set(hmove(pidx),'xdata',xtmp,'ydata',ytmp);
    setappdata(src,'newpoint',false);
    setappdata(src,'idx',idx);
  else
    setappdata(src,'newpoint',true);
  end
  switch profiletype
    case 'linear'
      set(src,'windowbuttonupfcn',{@endtrackmouse_CB,h});
    case 'polar'
      set(src,'windowbuttonupfcn',{@endtrackmousepolar_CB,h});
  end      
  set(src,'windowbuttonmotionfcn',{@plotpoint_CB,h});
end


function endtrackmouse_CB(src,data,h)
  set(src,'windowbuttonmotionfcn','');

  set(h.curve.move(1),'xdata',[],'ydata',[]);
  set(h.curve.late(1),'xdata',[],'ydata',[]);

  con = getappdata(src,'connect');

  hdat = h.curve.dat;
  xdat = get(hdat(1,1),'xdata');
  ydat = get(hdat(1,1),'ydata');
  xlim = get(gca,'XLim');
  ylim = get(gca,'YLim');
  pos = get(gca,'currentpoint');
  x = pos(1,1);
  y = pos(1,2);
  offlimits = false;
  if (x<xlim(1) || x>xlim(2)) || (y<ylim(1) || y>ylim(2))
    offlimits = true;
  end
  if getappdata(src,'newpoint') && ~offlimits
    [ydat,idx] = sort([ydat y]);
    xdat = [xdat x];
    xdat = xdat(idx);
  else
    idx = getappdata(src,'idx');
    if offlimits
      if idx>1 && idx<length(xdat)
        xdat(idx) = [];
        ydat(idx) = [];
      end
    else
      if idx>1 && idx<length(ydat)
        ydat(idx) = y;
      end
      xdat(idx) = x;
      if con && idx==1
        xdat(end) = xdat(1); 
      elseif con && idx==length(xdat)
        xdat(1) = xdat(end);
      end
    end
  end
  set(hdat(1,1),'xdata',xdat,'ydata',ydat);
  set(hdat(1,2),'xdata',-xdat,'ydata',ydat);
  
  hsmooth = h.curve.smooth;
  npts = getappdata(src,'npoints');
  interp = getappdata(src,'interp');
  x1 = get(hsmooth(1,1),'xdata');
  y1 = get(hsmooth(1,1),'ydata');

  
  if con
    xdat = [xdat(1:(end-1)) xdat xdat(2:end)];
    ydat = [ydat(1:(end-1))-ydat(end) ydat ydat(2:end)+ydat(end)];
    y1 = [y1(1:(end-1))-y1(end) y1 y1(2:end)+y1(end)];
    x1 = interp1(ydat,xdat,y1,interp);
    x1 = x1(npts(1):(2*npts(1)-1));
  else
    x1 = interp1(ydat,xdat,y1,interp);
  end
  
  set(hsmooth(1,1),'xdata',x1);
  set(hsmooth(1,2),'xdata',-x1);

  drawnow; drawnow
  
  model = getappdata(h.main.f,'model');
  
  switch model.shape.shape
    case {'revolution','extrusion','worm'}
      model.shape.(model.shape.shape).curve(1).rcurve = x1;
      
      model.shape.(model.shape.shape).curve(1).xdata = xdat;
      model.shape.(model.shape.shape).curve(1).ydata = ydat;
      model.shape.(model.shape.shape).curve(1).xsmooth = x1;
      model.shape.(model.shape.shape).curve(1).ysmooth = y1;
      
  end

  setappdata(h.main.f,'model',model);
  
end


function endtrackmousepolar_CB(src,data,h)
  set(src,'windowbuttonmotionfcn','');

  set(h.curve.move(2),'xdata',[],'ydata',[]);
  set(h.curve.late(2),'xdata',[],'ydata',[]);

  con = getappdata(src,'connect');

  hdat = h.curve.dat;
  xdat = get(hdat(2,1),'xdata');
  ydat = get(hdat(2,1),'ydata');
  xlim = get(gca,'XLim');
  ylim = get(gca,'YLim');
  pos = get(gca,'currentpoint');
  x = pos(1,1);
  y = pos(1,2);
  offlimits = false;
  if (x<xlim(1) || x>xlim(2)) || (y<ylim(1) || y>ylim(2))
    offlimits = true;
  end
  if getappdata(src,'newpoint') && ~offlimits
    ydat = [ydat y];
    xdat = [xdat x];
    thdat = atan2(ydat,xdat);
    thdat(thdat<0) = thdat(thdat<0) + 2*pi;
    rdat = sqrt(xdat.^2+ydat.^2);
    [thdat,idx] = sort([thdat]);
    rdat = rdat(idx);
    [xdat,ydat] = pol2cart(thdat,rdat);
  else
    idx = getappdata(src,'idx');
    if offlimits
      if idx>1 && idx<length(xdat)
        xdat(idx) = [];
        ydat(idx) = [];
      end
    else
      if idx~=1
        ydat(idx) = y;
      end
      xdat(idx) = x;
      if con && idx==1
        xdat(end) = xdat(1); 
      elseif con && idx==length(xdat)
        xdat(1) = xdat(end);
      end
    end
  end
  set(hdat(2,1),'xdata',xdat,'ydata',ydat);

  hsmooth = h.curve.smooth;
  npts = getappdata(src,'npoints');
  interp = getappdata(src,'interp');  

  th1 = linspace(0,2*pi,npts(2)+1);
  
  thdat = atan2(ydat,xdat);
  thdat(thdat<0) = thdat(thdat<0) + 2*pi;
  rdat = sqrt(xdat.^2+ydat.^2);

  % Works:
  % r1 = interp1([thdat 2*pi],[rdat rdat(1)],th1,'spline');
  % [x1,y1] = pol2cart(th1,r1);
  
  % Works now also:
  th1 = [th1(1:end-1) 2*pi+th1(1:end-1) 4*pi+th1];
  % r1 = interp1([thdat 2*pi+thdat 4*pi+thdat],...
  %              [rdat rdat rdat],...
  %              th1,...
  %              'spline');  
  r1 = interp1([thdat 2*pi+thdat 4*pi+thdat],...
               1./([rdat rdat rdat]).^2,...
               th1,...
               'spline');  
  r1 = real(1 ./ r1.^.5);
  th1 = th1(npts(2):(2*npts(2)));
  r1 = r1(npts(2):(2*npts(2)));
  
  [x1,y1] = pol2cart(th1,r1);
  
  
  
  set(hsmooth(2,1),'xdata',x1);
  set(hsmooth(2,1),'ydata',y1);
  % setappdata(src,'rdata',r1);
  
  drawnow; drawnow

  model = getappdata(h.main.f,'model');
  
  switch model.shape.shape
    case {'revolution','extrusion','worm'}
      model.shape.(model.shape.shape).curve(2).ecurve = r1;
  
      model.shape.(model.shape.shape).curve(2).xdata = xdat;
      model.shape.(model.shape.shape).curve(2).ydata = ydat;
      % model.shape.(model.shape.shape).curve(2).rdata = rdat;
      model.shape.(model.shape.shape).curve(2).xsmooth = x1;
      model.shape.(model.shape.shape).curve(2).ysmooth = y1;
      
  end
  
  setappdata(h.main.f,'model',model);
  
end


function plotpoint_CB(src,event,h)
  profiletype = getappdata(gca,'profiletype');
  idx = strmatch(profiletype,{'linear','polar'});
  
  hlate = h.curve.late;
  pos = get(gca,'currentpoint');
  set(hlate(idx),'xdata',pos(1,1),'ydata',pos(1,2));
  drawnow
end


function updatecurves(model,h)
  hdat = h.curve.dat;
  hsmooth = h.curve.smooth;
  
  
  xdat = model.shape.(model.shape.shape).curve(1).xdata;
  ydat = model.shape.(model.shape.shape).curve(1).ydata;

  xsmooth = model.shape.(model.shape.shape).curve(1).xsmooth;
  ysmooth = model.shape.(model.shape.shape).curve(1).ysmooth;
  
  
  set(hdat(1,1),'xdata',xdat,'ydata',ydat);
  set(hdat(1,2),'xdata',-xdat,'ydata',ydat);
  
  set(hsmooth(1,1),'xdata',xsmooth);
  set(hsmooth(1,2),'xdata',-xsmooth);
  
  
  xdat = model.shape.(model.shape.shape).curve(2).xdata;
  ydat = model.shape.(model.shape.shape).curve(2).ydata;

  xsmooth = model.shape.(model.shape.shape).curve(2).xsmooth;
  ysmooth = model.shape.(model.shape.shape).curve(2).ysmooth;
  
  set(hdat(2,1),'xdata',xdat,'ydata',ydat);

  set(hsmooth(2,1),'xdata',xsmooth);
  set(hsmooth(2,1),'ydata',ysmooth);
  
end
  
function resetcurve_CB(src,event,h,idx)

% TODO: reset only rev/ext curve
  
  % get model
  model = getappdata(h.main.f,'model');
  default = getappdata(h.main.f,'default');
  
  % get handles
  hdat = h.curve.dat;
  hsmooth = h.curve.smooth;
  
  % replace with default values
  switch model.shape.shape
    case {'revolution','extrusion','worm'}  
      model.shape.(model.shape.shape).curve(idx) = default.shape.(model.shape.shape).curve(idx);
  end
  setappdata(h.main.f,'model',model);  
  
  % update
  updatecurves(model,h);
  updatemodel(h);
end

