function model = objParseArgs(model,par)

% OBJPARSEARGS
%
% Parse input arguments to objMake*-functions.

% Copyright 2015 Toni Saarela
% 2015-05-04 - ts - first version
% 2015-05-12 - ts - adds file name extension if needed
% 2015-05-13 - ts - added 'locations' option; other bug fixes
% 2015-05-29 - ts - rms-option now uses the same name-value syntax as
%                    all others
% 2015-05-30 - ts - no separate opts-structure; just update the model
%                    structure given as input
% 2015-05-31 - ts - improved updating of existing model
% 2015-06-03 - ts - added a new flag to indicate custom bump location
%                    are set
% 2015-06-08 - ts - separate arguments for revolution and extrusion
%                    profiles (rcurve and ecurve)
% 2015-06-08 - ts - fixed a bug in objParseArgs in setting file name
% 2015-06-10 - ts - added options to change width, height
% 2015-06-16 - ts - setting a filename sets dosave to true
% 2015-10-07 - ts - possible to define material name without material library
% 2015-10-08 - ts - added the 'spinex' and 'spinez' options
% 2015-10-12 - ts - added the 'y' option
% 2015-10-14 - ts - added the 'max' option
% 2016-01-28 - ts - added option 'coords' for disk shape
%                   added options cpar, mpar, npar
% 2016-02-19 - ts - added option par (for bumps and custom)
% 2016-03-26 - ts - bump parms moved from opts to prm
%                   custom option names now 'custom' and 'custompar'
% 2016-04-12 - ts - minor fixes
% 2017-06-22 - ts - allow only changing the coord system of disk
% 2018-01-19 - ts - added option to set filename using name-value syntax
% 2018-02-03 - ts - flags for spine
% 2018-02-09 - ts - added support for parameters for
%                    superellipsoid, supertoroid
% 2018-02-10 - ts - changed some error messages
% 2018-02-16 - ts - fixed error message for angle
  
% Flag to indicate whether uv-coordinate computation was set to false
% explicitly.  This is used so that the option 'uvcoords' can be used
% to override the effect of option 'material', which sets the
% computation to true.  The user might want to do 
% > objMakeWhatever(...,'material',{'foo','bar'},'uvcoords',false,...)
% in the case that no textures are mapped and only uniform material
% properties are set.  File size will be smaller with no
% uv-coordinates.
  uv_explicit_false = false;

  save_explicit_false = false;

  if ~isempty(par)
    ii = 1;
    while ii<=length(par)
      if ischar(par{ii})
        switch lower(par{ii})
          case 'mindist'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.opts.mindist = par{ii};
            else
              error('No value or a bad value given for option ''mindist''.');
            end
          case 'npoints'
            if ~model.flags.new_model
              error('You cannot change the size of an existing model.');
            end
            if ii<length(par) && isnumeric(par{ii+1}) && length(par{ii+1}(:))==2
              ii = ii + 1;
              model.m = par{ii}(1);
              model.n = par{ii}(2);
            else
              error('No value or a bad value given for option ''npoints''.');
            end
          case {'material','mtl'}
            if ii<length(par) && ischar(par{ii+1})
              ii = ii + 1;
              model.mtl.name = par{ii};
              model.flags.comp_uv = true;
            else
              error('No value or a bad value given for option ''material''.');
            end
          case {'materialfile','mtlfile'}
            if ii<length(par) && ischar(par{ii+1})
              ii = ii + 1;
              model.mtl.file = par{ii};
              model.flags.comp_uv = true;
            else
              error('No value or a bad value given for option ''mtlfile''.');
            end
          case 'uvcoords'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii + 1;
              model.flags.comp_uv = par{ii};
              if ~model.flags.comp_uv
                uv_explicit_false = true;
              end
            else
              error('No value or a bad value given for option ''uvcoords''.');
            end
          case 'rms'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii + 1;
              model.flags.use_rms = par{ii};
            else
              error('No value or a bad value given for option ''rms''.');
            end
            %model.use_rms = true;
          case 'normals'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii + 1;
              model.flags.comp_normals = par{ii};
            else
              error('No value or a bad value given for option ''normals''.');
            end
          case 'save'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii + 1;
              model.flags.dosave = par{ii};
              if ~model.flags.dosave
                save_explicit_false = true;
              end
            else
              error('No value or a bad value given for option ''save''.');
            end
          case {'tube_radius','minor_radius'}
            if ~model.flags.new_model
              error('You cannot change the radius of an existing model.');
            end
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.tube_radius = par{ii};
            else
              error('No value or a bad value given for option ''tube_radius''.');
            end              
          case {'radius','major_radius'}
            if ~model.flags.new_model
              error('You cannot change the radius of an existing model.');
            end
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.radius = par{ii};
            else
              error('No value or a bad value given for option ''radius''.');
            end
          case 'super'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.super = par{ii};
            else
              error('No value or a bad value given for option ''super''.');
            end                        
          case 'rpar'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.opts.rprm = par{ii};
            else
              error('No value or a bad value given for option ''rpar''.');
            end
          case 'cpar'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.prm(model.idx).cprm = par{ii};
            else
              error('No value or a bad value given for perturbation parameters.');
            end
          case 'mpar'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.prm(model.idx).mprm = par{ii};
            else
              error('No value or a bad value given for envelope parameters.');
            end
          case 'npar'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.prm(model.idx).nprm = par{ii};
            else
              error('No value or a bad value given for perturbation parameters.');
            end
          case 'par'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.prm(model.idx).prm = par{ii};
            else
              error('No value or a bad value given for perturbation parameters.');
            end
          case 'custompar'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.opts.prm = par{ii};
            else
              error('No value or a bad value given for perturbation parameters.');
            end
          case 'custom'
            if ii<length(par)
              ii = ii + 1;
              model.opts.f = par{ii};
            else
              error('No value or a bad value given for custom perturbation.');
            end              
          case {'locations','loc'}
            if ii<length(par) && iscell(par{ii+1}) && length(par{ii+1})==2
              ii = ii + 1;
              model.opts.locations = par{ii};
              model.flags.custom_locations = true;
            else
              error('No value or a bad value given for option ''locations''.');
            end
          case 'rotate'
            % Is this even used?  I don't think so.
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii + 1;
              model.rotate = par{ii};
            else
              error('No value or a bad value given for option ''rotate''.');
            end
          case 'rcurve'
            if ~model.flags.new_model
              error('You cannot change the option ''rcurve'' in an existing model.');
            end
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.rcurve = par{ii};
              model.rcurve = model.rcurve(:)';
            else
              error('No value or a bad value given for option ''rcurve''.');
            end
          case 'ecurve'
            if ~model.flags.new_model
              error('You cannot change the option ''ecurve'' in an existing model.');
            end
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.ecurve = par{ii};
              model.ecurve = model.ecurve(:)';
            else
              error('No value or a bad value given for option ''ecurve''.');
            end
          case 'caps'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii + 1;
              model.flags.caps = par{ii};
            else
              error('No value or a bad value given for option ''caps''.');
            end
          case 'width'
            if ~model.flags.new_model
              error('You cannot change the option ''width'' in an existing model.');
            end
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.width = par{ii};
            else
              error('No value or a bad value given for option ''width''.');
            end
          case 'height'
            if ~model.flags.new_model
              error('You cannot change the option ''height'' in an existing model.');
            end
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.height = par{ii};
            else
              error('No value or a bad value given for option ''height''.');
            end
          case 'spinex'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.spine.x = par{ii};
              model.spine.x = model.spine.x(:)';
              model.flags.custom_spine(1) = true;
            else
              error('No value or a bad value given for option ''spinex''.');
            end
          case 'spinez'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.spine.z = par{ii};
              model.spine.z = model.spine.z(:)';
              model.flags.custom_spine(3) = true;
            else
              error('No value or a bad value given for option ''spinez''.');
            end
          case 'spiney'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.spine.y = par{ii};
              model.spine.y = model.spine.y(:)';
              model.flags.custom_spine(2) = true;
              model.flags.scaley = false;
            else
              error('No value or a bad value given for option ''spiney''.');
            end
          case 'scaley'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii+1;
              model.flags.scaley = par{ii};
            else
              error('No value or a bad value given for option ''scaley''.');
            end
          case 'y'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.y = par{ii};
              model.y = model.y(:)';
            else
              error('No value or a bad value given for option ''y''.');
            end
          case 'max'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii+1;
              model.flags.max = par{ii};
            else
              error('No value or a bad value given for option ''max''.');
            end
          case 'axis'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              ax = par{ii};
              ax = ax(:)';
              ax = ax / norm(ax);
              model.opts.tilt_axis = ax;
            else
              error('No value or a bad value given for option ''axis''.');
            end
          case 'angle'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii+1;
              model.opts.tilt_angle = par{ii};
            else
              error('No value or a bad value given for option ''angle''.');
            end
          case 'coords'
            if isempty(strmatch(model.shape,{'disk','disc'},'exact'))
              error(sprintf('Cannot change the coordinate system of %s.',model.shape));
            end
            if ii<length(par) && ischar(par{ii+1})
              ii = ii+1;
              stmp = {'polar','cartesian'}; % ,'spherical','cylindrical','torus'};
              idx = strmatch(par{ii},stmp);
              if isempty(idx)
                error('Bad value given for option ''coords''.');
              else
                model.opts.coords = stmp{idx};
              end
            else
              error('No value or a bad value given for option ''coords''.');
            end
          case 'filename'
            if ii<length(par) && ischar(par{ii+1})
              ii = ii+1;
              model.filename = par{ii};
              model.flags.dosave = true;
            else
              error('No value or a bad value given for option ''filename''.');
            end     
          otherwise
            model.filename = par{ii};
            model.flags.dosave = true;
        end
      else
        ;
      end
      ii = ii + 1;
    end % while over par
  end

  % See comment above for explanation.
  if uv_explicit_false
    model.flags.comp_uv = false;
  end

  if save_explicit_false
    model.flags.dosave = false;
  end

  % Add file name extension if needed
  if isempty(regexp(model.filename,'\.obj$'))
    model.filename = [model.filename,'.obj'];
  end

  % if ~model.flags.new_model
  %   oldmodel.filename = model.filename;
  %   oldmodel.mtlfilename = model.mtlfilename;
  %   oldmodel.mtlname = model.mtlname;
  %   oldmodel.flags = model.flags;
  %   oldmodel.opts = model.opts;
  %   model = oldmodel;
  %   model.new_model = false;
  %   model.normals = [];
  % end

end
