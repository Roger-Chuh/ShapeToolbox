% SHAPETOOLBOX
%
% ShapeToolbox is a set of tools for creating meshes for 3D objects
% mainly intended for vision science experiments. The basic idea of
% the toolbox is to provide a handful of very simple 'base shapes'
% that can then be perturbed in different ways---such as by adding
% sinusoidal or noisy modulations to the surfaces, adding bumps of
% using custom matrices, functions, or images to perturb the shape.
%
% The following is a list of functions in the toolbox split by
% topics.
% 
% Functions for making 3D-models:
% ===============================
% 
%  objMakePlain
%  objMakeSine
%  objMakeNoise
%  objMakeBump
%  objMakeCustom
%  (objMake)
%
% Blending / morphing
% ===================
% 
%  objBlend
% 
% Helper functions
% ================
% 
%  objBatch
%  objFindAngles
%  objFindFreqs
%  objRead
%  objSave
%  objSet
%  objView
%  objGroup
%
% GUIs
% ====
%
%  objDesigner
%  objBlendGui
%
% TO BE ADDED
% ===========
%
%  objScale
%  objAddThickness
%  objCutSphere
%
% The objMake*-functions are used to make the models and add
% modulations to them. For help on how to use them, start with
% 'help objMakePlain', which gives you an overview on the options
% available. All the options in objMakePlain are available in other
% objMake*-functions as well. The help strings for the other
% objMake*-functions only list the additional options that are
% available for that specific function (the options listed in the
% help for objMakePlain are not repeated).
%
%