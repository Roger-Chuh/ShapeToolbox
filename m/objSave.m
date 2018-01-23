function s = objSave(s)

% OBJSAVE
%
% Usage: model = objSave(model)
%
% A function called by the objMake*-functions to compute
% texture coordinates, faces, and so forth; and to write the model
% to a file.
%
% All the objMake*-functions can save models (just define a file
% name when calling the function, or set the save-option to true;
% see `help objMakePlain`). Sometimes you might need several function
% calls on the same model (such as when adding several different
% kinds of perturbation), and then only save the model once you're
% done. In that case objSave() is useful.
%
% To set a file name for the model, give it when calling one of the
% objMake*-functions, while also setting the save-option to false:
% 
% > m = objMakeSine('sphere',...,'mysphere.obj','save',false);
% > % more work on the model
% > objSave(m)
%
% Alternatively, as the model is just Matlab structure, you can
% change the 'filename'-field to whatever string you want to use as
% a filename:
%
% > m = objMakeSine(...)
% > m.filename = 'mymodel.obj'
% > objSave(m)
%
% If you don't set a file name and call objSave(), the default file
% name for the model will be used (depends on the base shape,
% 'sphere.obj', 'cylinder.obj' etc).

% I'd love to start the names of these helper functions with an
% underscore (_) to make it clear they're helper functions not to
% be directly called by the user, but Matlab doesn't allow it
% (Octave allows it.  Use Octave.)

% Copyright (C) 2015,2016 Toni Saarela
% 2015-04-06 - ts - first version, based on the model-type-specific
%                    functions
% 2015-05-04 - ts - uses option comp_uv for uv-coords instead of
%                    checking whether mtl filename is empty
% 2015-05-07 - ts - bettered the writing of vertices etc to file.
%                    it's better now.
% 2015-05-12 - ts - plane width and height are now 2, changed freq conversion
% 2015-05-18 - ts - added new model shape, 'extrusion'
% 2015-05-30 - ts - updated to work with new object structure format
% 2015-06-01 - ts - fixed a comment string to work with matlab (# to %)
% 2015-06-06 - ts - explicitly open file in text mode (for windows)
% 2015-06-10 - ts - changed freq conversion for plane
% 2015-06-10 - ts - added mesh reso to obj comments
% 2015-10-07 - ts - checks for material library and material name
%                    separately; fixed a bug in setting texture
%                    coordinate faces for planes
% 2015-10-10 - ts - added support for worm shape
% 2015-10-12 - ts - computation of faces, uv-coordinates, and normals
%                    separated into their own functions
% 2016-01-28 - ts - reformatted the "created with"-string
% 2016-02-19 - ts - writes perturbation type into comments
% 2016-03-26 - ts - renamed objSave (was objSaveModel)
% 2016-05-27 - ts - added groups 
% 2016-05-28 - ts - info about (face) groups written to comments
% 2016-06-12 - ts - don't return anything if no output argumets set
% 2016-10-23 - ts - rewrote documenting the function call stack info
% 2016-12-18 - ts - new order or perturbation parameters 
% 2018-01-17 - ts - updated help
% 2018-01-23 - ts - updated writing of material file and material name
  
m = s.m;
n = s.n;

%--------------------------------------------
% Faces, vertex indices
s = objCompFaces(s);

% Texture coordinates if material is defined
if s.flags.comp_uv
  s = objCompUV(s);
end

% Vertex normals
if s.flags.comp_normals
  s = objCompNormals(s);
end

%--------------------------------------------
% Write to file

fid = fopen(s.filename,'wt');
fprintf(fid,'# %s\n',datestr(now,31));
for ii = 1:length(s.prm)
  if ii==1 verb = 'Created'; else verb = 'Modified'; end 
  fprintf(fid,'# %d. %s with function %s from ShapeToolbox.\n',ii,verb,s.prm(ii).mfilestack{end});
  if length(s.prm(ii).mfilestack)>1
    fprintf(fid,'#    Function call stack: %s',s.prm(ii).mfilestack{end});
    for jj = (length(s.prm(ii).mfilestack)-1):-1:1
      fprintf(fid,' -> %s',s.prm(ii).mfilestack{jj});
    end
    fprintf(fid,'.\n');
  end
end
fprintf(fid,'#\n# Base shape: %s.\n',s.shape);
fprintf(fid,'#\n# Number of vertices: %d.\n',size(s.vertices,1));
fprintf(fid,'# Mesh resolution: %dx%d.\n',s.m,s.n);
fprintf(fid,'# Number of faces: %d.\n',size(s.faces,1));

if s.flags.comp_uv
  fprintf(fid,'# Texture (uv) coordinates defined: Yes.\n');
else
  fprintf(fid,'# Texture (uv) coordinates defined: No.\n');
end

if s.flags.comp_normals
  fprintf(fid,'# Vertex normals included: Yes.\n');
else
  fprintf(fid,'# Vertex normals included: No.\n');
end

if s.flags.write_groups
  fprintf(fid,'# Number of groups (for faces): %d.\n',length(s.group.idx));
else
  fprintf(fid,'# No groups defined.\n');
end

for ii = 1:length(s.prm)
  if length(s.prm)==1
    fprintf(fid,'#\n# %s\n# %s ',repmat('-',1,50),s.prm(ii).mfilestack{end});
  else
    fprintf(fid,'#\n# %s\n# %d. %s ',repmat('-',1,50),ii,s.prm(ii).mfilestack{end});
  end
  if length(s.prm(ii).mfilestack)>1
    fprintf(fid,'(');
    for jj = (length(s.prm(ii).mfilestack)-1):-1:1
      fprintf(fid,'->%s',s.prm(ii).mfilestack{jj});
    end
  fprintf(fid,') ');
  end
  fprintf(fid,'parameters:\n');
  
  fprintf(fid,'#\n# Perturbation type: %s\n',s.prm(ii).perturbation);
  switch s.prm(ii).perturbation
    %---------------------------------------------------
    case 'sine'
      if strcmp(s.shape,'plane')
        %- Convert frequencies back to cycles/plane
        s.prm(ii).cprm(:,1) = s.prm(ii).cprm(:,1)/(2*pi);
        if ~isempty(s.prm(ii).mprm)
          s.prm(ii).mprm(:,1) = s.prm(ii).mprm(:,1)/(2*pi);
        end         
      end
      writeSpecs(fid,s.prm(ii).cprm,s.prm(ii).mprm);
    %---------------------------------------------------
    case 'bump'
      writeSpecsBumpy(fid,s.prm(ii).prm);
    %---------------------------------------------------
    case 'noise'
      if strcmp(s.shape,'plane')
        %- Convert frequencies back to cycles/plane
        if ~isempty(s.prm(ii).mprm)
          s.prm(ii).mprm(:,1) = s.prm(ii).mprm(:,1)/(2*pi);
        end
      end
      writeSpecsNoisy(fid,s.prm(ii).nprm,s.prm(ii).mprm);
      if s.prm(ii).use_rms
        fprintf(fid,'# Use RMS contrast: Yes.\n');
      else
        fprintf(fid,'# Use RMS contrast: No.\n');
      end
    %---------------------------------------------------
    case 'custom'
      writeSpecsCustom(fid,s.prm(ii));
    %---------------------------------------------------
 end
end

fprintf(fid,'#\n# Phase and angle (if present) are in radians above.\n');

if ~isempty(s.mtl.file) || ~isempty(s.mtl.name)
  fprintf(fid,'\n# Materials:\n');
  if ~isempty(s.mtl.file)
    fprintf(fid,'mtllib %s\n',s.mtl.file);
  end
  if ~isempty(s.mtl.name)
    fprintf(fid,'usemtl %s\n',s.mtl.name);
  end
end

fprintf(fid,'\n# Vertices:\n');
fprintf(fid,'v %8.6f %8.6f %8.6f\n',s.vertices');
fprintf(fid,'# End vertices\n');

if s.flags.comp_uv
  fprintf(fid,'\n# Texture coordinates:\n');
  fprintf(fid,'vt %8.6f %8.6f\n',s.uvcoords');
  fprintf(fid,'# End texture coordinates\n');
end

if s.flags.comp_normals
  fprintf(fid,'\n# Normals:\n');
  fprintf(fid,'vn %8.6f %8.6f %8.6f\n',s.normals');
  fprintf(fid,'# End normals\n');
end

% Write face defitions to file.  These are written differently
% depending on whether uvcoordinates and/or normals are included.
fprintf(fid,'\n# Faces:\n');

for ii = 1:length(s.group.idx)

  if s.flags.write_groups
    fprintf(fid,'g %s\n',s.group.names{ii});
    if ~isempty(s.group.materials)
      fprintf(fid,'usemtl %s\n',s.group.materials{ii});
    end
    idx = s.group.groups==s.group.idx(ii);
  else
    idx = 1:size(s.faces,1);
  end

  if ~s.flags.comp_uv
    if s.flags.comp_normals
      fprintf(fid,'f %d//%d %d//%d %d//%d\n',...
              [s.faces(idx,1) s.faces(idx,1) ...
               s.faces(idx,2) s.faces(idx,2) ...
               s.faces(idx,3) s.faces(idx,3)]');
    else
      fprintf(fid,'f %d %d %d\n',s.faces(idx,:)');    
    end
  else
    if s.flags.comp_normals
      fprintf(fid,'f %d/%d/%d %d/%d/%d %d/%d/%d\n',...
              [s.faces(idx,1) s.facestxt(idx,1) s.faces(idx,1)...
               s.faces(idx,2) s.facestxt(idx,2) s.faces(idx,2)...
               s.faces(idx,3) s.facestxt(idx,3) s.faces(idx,3)]');
    else
      fprintf(fid,'f %d/%d %d/%d %d/%d\n',...
              [s.faces(idx,1) s.facestxt(idx,1) ...
               s.faces(idx,2) s.facestxt(idx,2) ...
               s.faces(idx,3) s.facestxt(idx,3)]');
    end
  end
end

% if ~s.flags.comp_uv
%   if s.flags.comp_normals
%     fprintf(fid,'f %d//%d %d//%d %d//%d\n',...
%             [s.faces(:,1) s.faces(:,1) ...
%                     s.faces(:,2) s.faces(:,2) ...
%                     s.faces(:,3) s.faces(:,3)]');
%   else
%     fprintf(fid,'f %d %d %d\n',s.faces');    
%   end
% else
%   if s.flags.comp_normals
%     fprintf(fid,'f %d/%d/%d %d/%d/%d %d/%d/%d\n',...
%             [s.faces(:,1) s.facestxt(:,1) s.faces(:,1)...
%                     s.faces(:,2) s.facestxt(:,2) s.faces(:,2)...
%                     s.faces(:,3) s.facestxt(:,3) s.faces(:,3)]');
%   else
%     fprintf(fid,'f %d/%d %d/%d %d/%d\n',...
%             [s.faces(:,1) s.facestxt(:,1) ...
%                     s.faces(:,2) s.facestxt(:,2) ...
%                     s.faces(:,3) s.facestxt(:,3)]');
%   end
% end

fprintf(fid,'# End faces\n');
fclose(fid);

if ~nargout
  clear s
end

%--------------------------------------------
% Functions to write the modulation specs; these are called above

function writeSpecs(fid,cprm,mprm)

nccomp = size(cprm,1);
nmcomp = size(mprm,1);

fprintf(fid,'#\n# Modulation carrier parameters (each row is one component):\n');
fprintf(fid,'#  Frequency | Phase | Angle | Amplitude | Group\n');
for ii = 1:nccomp
  fprintf(fid,'#  %9.2f   %5.2f   %5.2f   %9.2f   %5d\n',cprm(ii,:));
end

if ~isempty(mprm)
  fprintf(fid,'#\n# Modulator parameters (each row is one component):\n');
  fprintf(fid,'#  Frequency | Phase | Angle | Amplitude | Group\n');
  for ii = 1:nmcomp
    fprintf(fid,'#  %9.2f   %5.2f   %5.2f   %9.2f   %5d\n',mprm(ii,:));
  end
end

function writeSpecsBumpy(fid,prm)

nbumptypes = size(prm,1);

fprintf(fid,'#\n# Gaussian bump parameters (each row is bump type):\n');
fprintf(fid,'#  # of bumps | Sigma | Amplitude\n');
for ii = 1:nbumptypes
  fprintf(fid,'#  %10d   %5.2f   %9.2f\n',prm(ii,:));
end

function writeSpecsNoisy(fid,nprm,mprm)

nncomp = size(nprm,1);
nmcomp = size(mprm,1);

fprintf(fid,'#\n# Noise carrier parameters (each row is one component):\n');
fprintf(fid,'#  Frequency | FWHH | Angle | FWHH | Amplitude | Group\n');
for ii = 1:nncomp
  fprintf(fid,'#  %9.2f   %4.2f   %5.2f   %4.2f   %9.2f   %5d\n',nprm(ii,:));
end

if ~isempty(mprm)
  fprintf(fid,'#\n# Modulator parameters (each row is one component):\n');
  fprintf(fid,'#  Frequency | Phase | Angle | Amplitude | Group\n');
  for ii = 1:nmcomp
    fprintf(fid,'#  %9.2f   %5.2f   %5.2f   %9.2f   %5d\n',mprm(ii,:));
  end
end

function writeSpecsCustom(fid,prm)

if prm.use_map
  if isfield(prm,'imgname')
     fprintf(fid,'#\n# Modulation values defined by the (average) intensity\n');
     fprintf(fid,'# of the image %s.\n',prm.imgname);
  else
     fprintf(fid,'#\n# Modulation values defined by a custom matrix.\n');
  end
else    
  fprintf(fid,'#\n#  Modulation defined by a custom user-defined function.\n');
  fprintf(fid,'#  Modulation parameters:\n');
  fprintf(fid,'#  # of locations | Cut-off dist. | Custom function arguments\n');
  for ii = 1:prm.nbumptypes
    fprintf(fid,'#  %14d   %13.2f   ',prm.prm(ii,1:2));
    fprintf(fid,'%5.2f  ',prm.prm(ii,3:end));
    fprintf(fid,'\n');
  end
end
