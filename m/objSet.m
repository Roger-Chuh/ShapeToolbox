function model = objSet(model,varargin)

% OBJSET
%
% m = objSet(m,options)
%
% Set various options in an existing model. The options you can set
% is a subset of those you can set when calling one of the
% objMake*-functions. These are options that do not pertain to the
% model size or parameters of a particular perturbation.
%
% The following is a list of names of options you can set with this
% function:
%
% 'material'
% 'uvcoords'
% 'normals'
% 'save'
% 'caps'
% 'spinex', 'spinez', spiney'
% 'scaley, 'y'
% 'use_perturbation'
% 'filename'
%
% The above are all set by giving name-value pairs (see help
% objMakePlain for explanations of these options). The exception to
% the name-value pair input is the file name: to set a new file name,
% you can simply give a string with no name for the option (that is,
% you can omit the 'filename' key). See `help objMakePlain`.
%
% The one option you can set only using this function is
% 'use_perturbation'. This option can be used to 'silence' some of the
% perturbations in a given model. If you have model to which you have
% added, through repeated calls to the objMake*-functions, several
% types of perturbation, you can use the 'use_perturbation' options
% to set these on or off. The value of for the 'use_perturbation'
% option is a vector of logical (true/false) values (if the input
% vector is not logical, it will be converted to a logical
% vector). This number of elements in this vector must equal the
% number of perturbations added to the model.
%
% Example of using 'use_perturbation':
%
% > m = objMakeSine('sphere');
% > m = objMakeNoise(m);
% > m = objMakeBump(m);
% > objShow(m)   % all three perturbations included
%
% > m = objSet(m,'use_perturbation',[0 1 1]);
% > objShow(m)   % noise and bumps included
%
% > m = objSet(m,'use_perturbation',[0 0 0]);
% > objShow(m)   % no perturbations, a plain sphere
%
% > m = objSet(m,'use_perturbation',[1 1 1]);
% > objShow(m)   % all three included again
  
% Copyright (C) 2018 Toni Saarela
% 2018-01-17 - ts - first version
% 2018-01-19 - ts - added option to set filename using name-value syntax
% 2018-01-23 - ts - removed rcurve, ecurve from the options
%                    (currently can't change them in an existing model)
%                   only call other functions (updateperturbs,
%                    makevertices...) if required by the modification
  
  uv_explicit_false = false;
  save_explicit_false = false;

  redo = [0 0 0]; % [coords perturb vertices]
  
  par = varargin;
  
  if ~isempty(par)
    ii = 1;
    while ii<=length(par)
      if ischar(par{ii})
        switch lower(par{ii})
          case 'material'
            if ii<length(par) && ischar(par{ii+1})
              ii = ii + 1;
              model.mtlname = par{ii};
              model.flags.comp_uv = true;
            elseif ii<length(par) && iscell(par{ii+1}) && length(par{ii+1})==2
              ii = ii + 1;
              model.mtlname = par{ii}{1};
              model.mtlfilename = par{ii}{2};
              model.flags.comp_uv = true;
            else
              error('No value or a bad value given for option ''material''.');
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
          % case 'rcurve'
          %   if ~model.flags.new_model
          %     error('You cannot change the option ''rcurve'' in an existing model.');
          %   end
          %   if ii<length(par) && isnumeric(par{ii+1})
          %     ii = ii+1;
          %     model.rcurve = par{ii};
          %     model.rcurve = model.rcurve(:)';
          %   else
          %     error('No value or a bad value given for option ''rcurve''.');
          %   end
          % case 'ecurve'
          %   if ~model.flags.new_model
          %     error('You cannot change the option ''ecurve'' in an existing model.');
          %   end
          %   if ii<length(par) && isnumeric(par{ii+1})
          %     ii = ii+1;
          %     model.ecurve = par{ii};
          %     model.ecurve = model.ecurve(:)';
          %   else
          %     error('No value or a bad value given for option ''ecurve''.');
          %   end
          case 'caps'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii + 1;
              model.flags.caps = par{ii};
            else
              error('No value or a bad value given for option ''caps''.');
            end
          case 'spinex'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.spine.x = par{ii};
              model.spine.x = model.spine.x(:)';
              redo([1 3]) = 1;
            else
              error('No value or a bad value given for option ''spinex''.');
            end
          case 'spinez'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.spine.z = par{ii};
              model.spine.z = model.spine.z(:)';
              redo([1 3]) = 1;
            else
              error('No value or a bad value given for option ''spinez''.');
            end
          case 'spiney'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.spine.y = par{ii};
              model.spine.y = model.spine.y(:)';
              model.flags.scaley = false;
              redo([1 3]) = 1;
            else
              error('No value or a bad value given for option ''spiney''.');
            end
          case 'scaley'
            if ii<length(par) && isscalar(par{ii+1})
              ii = ii+1;
              model.flags.scaley = par{ii};
              redo([1 3]) = 1;
            else
              error('No value or a bad value given for option ''scaley''.');
            end
          case 'y'
            if ii<length(par) && isnumeric(par{ii+1})
              ii = ii+1;
              model.y = par{ii};
              model.y = model.y(:)';
              redo([1 3]) = 1;
            else
              error('No value or a bad value given for option ''y''.');
            end
          case 'use_perturbation'
            if ii<length(par) && isnumeric(par{ii+1}) && numel(par{ii+1})==length(model.flags.use_perturbation)
              ii = ii+1;
              tmp = par{ii};
              model.flags.use_perturbation = logical(tmp(:)');
              redo([2 3]) = 1;
            else
              error('No value or a bad value given for option ''use_perturbation''.');
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
  
  % model = objParseArgs(model,par);
  
  if redo(1)
    model = objSetCoords(model);
  end
  if redo(2)
    model = objUpdatePerturbations(model);
  end
  if redo(3)
    model = objMakeVertices(model);
  end
  
end

