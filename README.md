# ShapeToolbox

3D stimuli for vision science experiments. Octave/Matlab functions for generating 3D models of various shapes and saving the meshes in Wavefront .obj file format.

This is a work in progress. Things might change quickly making old things not work. More often though, things don't change at all for long periods of time.

## Purpose

ShapeToolbox is a set of tools for creating polygon meshes of 3D objects mainly intended for vision science experiments. The toolbox provides a handful of very simple 'base shapes' that can then be perturbed in different ways---such as by adding sinusoidal or noisy modulations to the surfaces, adding bumps or using custom matrices, functions, or images to perturb the shape.

The toolbox is very limited in the kinds of shapes it can produce. The main purpose is to provide a tool for producing stimuli for vision science and give the user fine, parametric control over the shape and surface parameters. 

## Download and install

The toolbox should work with resonably recent versions of both GNU Octave and Matlab (not all features might work on one or the other), on GNU/Linux, Mac OS X, and Windows (not really tested on Windows). No guarantees.

If you have `git` installed, grab the code using it:

```
git clone https://github.com/saarela/ShapeToolbox.git
```

Do `git pull` often to get the latest version. 

Alternatively, download and extract the zip archive https://github.com/saarela/ShapeToolbox/archive/master.zip

All you need to do is add the toolbox directory that has the m-files to Octave or Matlab path:

```matlab
addpath('path_to_shapetoolbox/m','-begin')
```

That might be something like:

```matlab
addpath('~/Documents/MATLAB/ShapeToolbox/m')
```

on Unixy systems or

```matlab
addpath('C:\MATLAB\ShapeToolbox\m')
```

on Windozy ones.

## Base shapes

The base shapes are sphere, ellipsoid, plane, disk, torus, and cylinder. In addition, you can create a surface of revolution, and extrusion, and a wiggly "worm" shape. That's it, no more complex shapes. (But you can add some complexity with a "superellipsoid" and "supertorus"/"supertoroid"; see further below.)

## Perturbations

You can perturb the above shapes by adding a sinusoid, a filtered noise pattern, or Gaussian bumps or dents to it. Additionally, you can use your own function to define the perturbation profile, or provide a matrix or an image that gives the perturbation values.

## Functions

All function names in the toolbox have an obj-prefix. This does not really make any sense, but that's how it is now.

All the functions include a description of its usage. Use Matlab's `help` function to view it. To see a list of all functions and a general description of the toolbox in Matlab's command window, type `help shapetoolbox`.

### Create models

The following are the main functions for creating and perturbing shapes.

```matlab
objMakePlain   % plain shape, no modulation
objMakeSine    % add sinusoidal perturbations
objMakeNoise   % add filtered noise to the shape
objMakeBump    % add gaussian bumps
objMakeCustom  % add perturbations defined by your own
               % function, matrix, or image
```

The help text for `objMakePlain` includes the options that are available for all `objMake*`-functions. So start by reading `help objMakePlain`, then see the perturbation-specific helps as needed.

The output of these functions is a Matlab structure that holds the model information. You can add further perturbations to the model using another `objMake*`-function, or view it using `objView`.

### Blending

```matlab
objBlend       % blend two models in arbitrary proportions
```

### Helper functions

The use and usefulness of some of the helper functions is illustrated in the examples below. For the rest, see their help in Matlab.

```matlab
objBatch
objFindAngles
objFindFreqs
objRead
objSave
objSet
objView
objGroup
```

### GUI type things

There are a couple of graphical tools to aid in the design of models, although they offer limited functionality. The first, `objDesigner` can be used to create and perturb models and see the result in real time. The second, `objBlendGui` gives a graphical tool to blend two models in whatever proportions you choose. (These might work properly only on Matlab. With Octave expect trouble, but with 4.0.0 they should mostly work OK.)

```
objDesigner
objBlendGui
```

## Usage

### Basic usage

To make a shape, choose the `objMake*`-function based on the type of surface perturbation you want (sine, noise, bump, custom), and give the base shape name as input (`'sphere'`, `'plane'`, `'disk'`, `'cylinder'` for now, `'ellipsoid'`, `'revolution'`, `'extrusion'`, and `'worm'` a little later). To make a sphere with the default sinusoidal radial modulation, use:

```matlab
% Make a shape:
m = objMakeSine('sphere')
% View it (use mouse to rotate):
objView(m)
```

To change the parameters of the sinusoid (see `help objMakeSine` for explanation of the parameters):

```matlab
m1 = objMakeSine('sphere',[8 90 90 .1])
m2 = objMakeSine('sphere',[8 60 0 .05])
figure
subplot(1,2,1); objView(m1)
subplot(1,2,2); objView(m2)
```

There are a bunch of options you can set for a model, see full list in the help strings in the `objMake*`-functions. Most of these are given as name-value pairs (with the exception of a file name, which can be given just as a single string, see below). With `objMakePlain`, just list the options after the first argument that gives the shape:

```matlab
model = objMakePlain('plane','option_name_1',option_value_1,...)
```

With the other `objMake*`-functions, the perturbation parameters come right after the shape, and other options after them. For default parameters, pass and empty parameter vector.

```matlab
model = objMakeSine('plane',[8 90 90 .1],'option_name_1',option_value_1,...)
model = objMakeSine('plane',[],'option_name_1',option_value_1,...)
```

To save a model to a file (Wavefront obj format), you have a few options. First, set the option `save` to `true` and the model will be save with the default file name (`'sphere.obj'`, `'plane.obj'`, `'cylinder.obj'` etc.). Second, simply give a file name as a string when calling an `objMake*`-function:

```matlab
m = objMakeSine('sphere',[8 60 0 .05],'save',true); % first way
m = objMakeSine('sphere',[8 60 0 .05],'my_model'); % second way
```

Or you can save later, using `objSave`. In between, you can set the file name using `objSet` (you can set other things with it, too). Otherwise, the default file name will be used:

```matlab
m = objMakeSine('sphere',[8 60 0 .05]);
m = objSet(m,'filename','my_model');
objSave(m);
```

In most of the examples below, the save option is not used.

### Shapes and perturbations

The possible shapes are: `sphere`, `ellipsoid`, `plane`, `torus`, `disk`, `cylinder`, `revolution`, `extrusion`, `worm`.

Perturbations are defined in different coordinate systems depending on the shape. Here's a list, but there shouldn't be anything surprising there:

| Shape          | Coordinate system  |
|----------------|--------------------|
| sphere         | spherical          |
| ellipsoid      | spherical          | 
| plane          | cartesian          |
| torus          | toroidal           |
| disk           | cartesian/polar(?) |
| cylinder-like* | cylindrical        |

\* cylinders, revolutions, extrusions, worms.

y-direction is up.

When adding bumps to a sphere, they are not added in spherical coordinates. The bumps are the same shape everywhere. Other funny inconsistencies are possible.

You can add any type of perturbation (using `objMakeSine`, `objMakeNoise`, `objMakeBump`, `objMakeCustom`) to any of the base shapes, just give the shape name as input.

You met the sphere and sine waves above. To make a torus with sine-wavy surface, with default parameters (use `objview` to view it, as usual):

```matlab
m = objMakeSine('torus');
```

In the torus, you can also modulate the major radius (instead of the radius of the "tube" as above). Here's an example (you can use the `rpar`-option in all `objMake*`-functions):

```matlab
m = objMakePlain('torus','rpar',[4 0 .1]);
```

Make a plane with fine noisy surface corrugation. Increase the model size (number of vertices) to more faithfully represent the finer structure. Setting the orientation bandwidth to `Inf` results in isotropic noise:

```matlab
m = objMakeNoise('plane',[32 1 0 Inf .02],'npoints',[256 256]);
```

Make a cylinder with bumps, bump locations are random:

```matlab
m = objMakeBump('cylinder',[50 pi/8 .1]);
```

You get the idea.

### Adding components

You can add more than one sine wave component, more than one type of filtered noise, more than one set of bumps/dents, and so forth. Instead of a vector of parameters for the perturbation, define each perturbation as a row in a matrix. For example, add two sines in different orientations:

```matlab
m = objMakeSine('sphere',[12 -60 0 .05; 12 60 0 .05]);
objView(m)
```

Low-frequency oriented noise component plus high-frequency noise:

```matlab
m = objMakeNoise('plane',[2 2 45 30 .1; 32 1 0 Inf .01],'npoints',[256 256]);
```

A cylinder with both bumps and dents (dents have negative amplitude):

```matlab
m = objMakeBump('cylinder',[50 pi/8 .1; 50 pi/16 -.2]);
```

There's no limit to the number of components you can add.

### Parametric series of shapes

Easy enough then to make a series of stimuli parametrically varying along some dimension or dimensions:

```matlab
a = 0:.025:.1;
figure
for ii = 1:length(a)
  m = objMakeSine('sphere',[12 -60 0 a(ii); 12 60 0 .1-a(ii)],[2 90 90 1]);
  subplot(1,length(a),ii);
  objView(m);
end
```

The above example also uses and "envelope" to modulate the amplitude of the sine wave to get rid of the sharp ridges near the poles.

### User-defined perturbations

#### User-defined function

The function `objMakeBump`, as seen above, adds to a shape bumps with a Gaussian profile. To adds things with a different profile, you can define a function that returns the profile as a function of distance (one-dimensional, the perturbation will be symmetric) and give the function handle as an input to `objMakeCustom`.

Let's first define an anonymous function. This function returns values of a "dome" shape. The function takes two input arguments: the distance from the center, and the radius of the dome (when you define your own functions for this purpose, the first input argument always has to be the distance).

```matlab
% A function that makes a "dome" shape, a hemisphere, that is used to
% give the appearance of bubbles.  The first input argument is
% distance, the second is the radius of the half-sphere.
f = @(d,r) (d<=r).*sqrt(r^2 - d.^2);
```

Next, use that function as input to `objMakeCustom`. We add perturbations at three different scales. This gives the impression of bubbles on the surface of a liquid (at least when rendered with appropriate material definitions). The option `max` is set to true, which leads to overlapping perturbations not to be added---the perturbation value at any point is the maximum of any overlapping perturbations. The use of some other options is also demonstrated (set `'normals'` to `false` to make it run faster).

```matlab
% First, the three rows of the parameter matrix define three sets of
% parameters to our function. The three sets differ in scale to make
% bubbles of different size.  In each row, the first parameter is the
% number of bubbles, the second is a cut-off value, and the third is
% the radius.  The cut-off and radius are the same in this case.
prm = [24 .15 .15;         % 24 large bubbles
       120 .1 .1;          % 120 medium ones
       1200 .03 .03];      % and 1200 small bubbles

% Now give the function handle and the parameters as input to objMakeCustom:
objMakeCustom('plane',...
              f,...                     % a handle to our function
              prm,...                   % see above
              'width',2,'height',2,...  % larger than the default plane
              'npoints',[512 512],...   % finer mesh
              'max',true,...            % don't add overlapping bubbles
              'normals',true,...        % normals for improved rendering
              'bubbles.obj');           % save in bubbles.obj
```

See `help objMakeCustom` for details on the input argument to the function etc.

#### User-defined matrix

If you have a matrix the values of which you would like to use to perturb the surface, give the matrix and maximum perturbation value as input to `objMakeCustom`:

```matlab
% Here, the variable M is for the input matrix:
m = objMakeCustom('plane',M,.1);
```

#### User-defined image

To use intensity values from an image to perturb a surface, give an image and the maximum perturbation value as input to `objMakeCustom`:

```matlab
m = objMakeCustom('cylinder','my_image_file.png',.05);
```

Note: Many renderers and other graphics programs will do bump mapping based on an image for you. You should probably use them if that's what you need. This is not bump mapping---the actual surface is perturbed, not only the surface normals.

### Combining perturbation types

You can freely combine different kinds of perturbation in a model. Let's say you first make a cylinder with a sinusoidal modulation thing:

```matlab
m = objMakeSine('cylinder',[8 60 0 .1]);
```

You can then add, say, some bumps and dents to it by giving the model structure as input to `objMakeBump`:

```matlab
m = objMakeBump(m,[50 pi/8 .1; 50 pi/16 -.2]);
```

And finally, add some noisy corrugation and view it:

```matlab
m = objMakeNoise(m,[16 1 0 Inf .1]);
objView(m)
```

### Silencing perturbations

When you have a model with several types of perturbation such as the one made above, you can "silence" some of the perturbations. This might be useful if you want to use the same stimulus in an experiment with and without certain perturbation components. To set perturbations on and off, use the `'use_perturbation'`-option in the function `objSet`. Give a vector of boolean values telling which perturbations should be on and which ones off. Here's an example using the model created above:

```matlab
figure
m = objSet(m,'use_perturbation',[1 0 1]); % bumps off
subplot(1,3,1); objView(m)
m = objSet(m,'use_perturbation',[0 0 1]); % sine and bumps off
subplot(1,3,2); objView(m)
m = objSet(m,'use_perturbation',[1 1 1]); % all on again
subplot(1,3,3); objView(m)
```

### Tilt

When adding a perturbation to a sphere or an ellipsoid, it's possible to tilt the axes and thus the orientation of the perturbation. Just define the axis around which to tilt and the tilt magnitude:

```matlab
m = objMakeSine('sphere',[8 90 90 .1],'axis',[0 0 1],'angle',20)
objView(m,[],[],1)
```

This enables to add, for example, identical perturbation patterns at different orientations to the same model. Continuing the example above:

```matlab
m = objMakeSine(m,[8 90 90 .1],'axis',[0 1 1],'angle',-20)
objView(m,[],[],1)
```

### Change the size/shape of a model

To change the size, you can set the option `'radius'`, `'height'`, `'width'`, or `'minor_radius'` as appropriate. To change the radius of a sphere or a cylinder, do:

```matlab
sphere = objMakeSine('sphere',[8 90 90 .1],'radius',2);
cyl = objMakeBump(cylinder',[],'radius',2);
```

The option `'height'` is for planes and cylinders, the option `'width'` for planes. For tori, you can set both the majos and minor radius (minor radius is the 'tube' radius):

```matlab
m = objMakePlain('torus','radius',.5,'minor_radius',.5)
```

To create an elliptical torus, give two radius values (the two semi-axes):

```matlab
m = objMakePlain('torus','radius',[2 1])
```

For an ellipsoid, give three radius values (x-, y-, and z-directions). The default values for the radii are `[1 1 1]`, that is, by default the ellipsoid is a sphere.

```matlab
m = objMakeNoise('ellipsoid',[8 1 60 30 .1],'radius',[1 1.5 2])
```

### Super-ellipsoid and super-torus

The super-ellipsoid and tuper-toroid are generalizations of the ellipse and torus. There are two extra parameters needed for these (mathematically, exponents for sines and cosines in their parametric representations). Use the option `'super'` to define these. The best way to get an idea of their effect is through examples:

```matlab
% Exponent values
s = 0:.5:2.5;
n = length(s);

% Make a grid of super-tori:
figure
for ii = 1:n
  for jj = 1:n
    m = objMakePlain('torus','super',[s(ii) s(jj)]);
    subplot(n,n,(ii-1)*n+jj);
    objView(m)
  end
end

% A grid of super-ellipsoids:
figure
for ii = 1:n
  for jj = 1:n
    m = objMakePlain('ellipsoid','super',[s(ii) s(jj)]);
    subplot(n,n,(ii-1)*n+jj);
    objView(m)
  end
end
```

### Revolutions, extrusions, worms

In addition to the base shapes seen above, you can use surfaces-of-revolution, extrusions, and "worms". These are all "cylinder-like", or tube-like things, just more wiggly. These shapes can then be perturbed in the same way as the others, by adding sinusoids, noise, bumps, and so forth.

To create a surface of revolution, create a curve (a vector of values) and give that as the value to the option `'rcurve'`:

```matlab
y = linspace(0,1,256);
profile = y.^.5;
% For illustration of the shape itself, don't add any perturbation:
rev = objMakePlain('revolution','rcurve',profile);
objView(rev);
```

These shapes also have the option to give the midline of the shape as input (options `'spinex'`, `'spinez'`). Building on the example above:

```matlab
% The x- and z-coordinates of the midline (spine) of the object.
% This produces a spiral narrowing towards the end
x = 2*sin(8*pi*y).*y;
z = 2*cos(8*pi*y).*y;
% Call the noise function to add slight corrugation to the surface:
rev = objMakeNoise('revolution',...          % base shape
                   [8 1 0 30 .03], ...       % noise parameters
                   'rcurve',profile,...      % curve to produce the surface of revolution
                   'spinex',x,'spinez',z,... % midline/spine coordinates of the object
                   'caps',true,...           % add caps to the ends
                   'corkscrew.obj');         % save the model in this file
objView(rev)
```

For the extrusion shape, use the option `'ecurve'` to provide the profile of the extrusion as a function of the polar angle:

```matlab
theta = linspace(0,2*pi,256);
r = 1 + .25 * sin(4*theta).^3;
ext = objMakeBump('extrusion',[100 pi/16 -0.1],'ecurve',r,'caps',true);
objView(ext);
```

You can also combine the `'rcurve'` and `'ecurve'` options. That is, a surface of revolution can also have an extrusion profile and vice versa.

The worm-shape works pretty much the same way (use the spine-options to define its trajectory in 3D space), and it can also have a revolution and extrusion profiles. Below is a short example, which also illustrates using the `scaley` and `radius` -options and displays the axes when viewing the model.

```matlab
y = linspace(0,2*pi,256);
x = sin(y);

% Make two models. In the first, the model's 'height' is the size in the y-direction, from
% the top to the bottom of the model. In the second one, use the 'scaley'-option so that 
% the model "height" is the length along the midline of the model. For both models, use a 
% smaller radius (default radius is 1).
w1 = objMakePlain('worm','spinex',x,'radius',.5,'model_unscaled');
w2 = objMakePlain('worm','spinex',x,'scaley',true,'radius',.5,'model_scaled');

% Display the models and show the axes
figure
subplot(1,2,1)
objView(w1,[],[],true)
subplot(1,2,2)
objView(w2,[],[],true)
```

For now, that's it. For further guidance, see `help objMakePlain`, and there the sections for `RCURVE, ECURVE` and `SPINEX, SPINEZ, SPINEY`. Also, you might want to play with `objDesigner`, which is a graphical tool for designing shapes, and let's you see the effects of various parameters immediately.

### Blending

For making a series of stimulus shapes varying on some dimension of interest, a loop over some set of perturbation parameters is often a good choice (illustrated above). Sometimes, however, if the shapes contain noisy components or are otherwise funky, it might be more convenient to select two shapes and make a series of blends between them, that is, to "average" the models in different proportions. For this, use `objBlend`. To make a new model that is a blend between the models `rev` and `ext` above, so that the weights are 40% `rev` and 60% `ext`, do:

```matlab
blend = objBlend(rev,ext,0.4);
objView(blend);
```
You can also use the graphical tool `objBlendGui` to test the effect of blending. It usually works pretty OK.

### Graphical user interface tools

There are two graphical interfaces, `objDesigner` and `objBlendGui`. These are not covered here in more detail yet. Just try them out and, well, good luck. If nothing happens in `objDesigner` when you change things, try hitting the `Update` button. If things crash, don't be surprised. Not all options are available through this interface. At the moment, ellipsoid and the "superparameters" are also not available. Hope to change this soon.

Good luck.

### Prepare models for 3D printing

There are a few functions that might be useful when prepping models for printing on a 3D printer. The models as they are spat out by the `objMake*`-functions are just "shells", that is, define only the outer boundary of the model shape. For 3D printing, the model walls need to have a thickness (of course you could print a solid sphere, as well as some other shapes, but that would be wasteful, and to a plane you would need to add some thickness to print anyway). For this, use `objAddThickness`. Also, you might want to scale the model. The models have default sizes that are (close to) unity in arbitrary units. For example, the default sphere and cylinder base radius is one, and default plane width is one. A 3D printing software might interpret this as one inch or one millimeter, but in any case, it is unlikely to be what you want. Use `objScale` to scale it. Finally, with some printing techniques (SLA at least) it might not be a good idea to try to print a hollow sphere because of a possible "suction effect" between the model and the bottom of the resin tank. You can use `objCutSphere` to cut out a piece of a sphere (or an ellipsoid) to make it more printable in this case.

```matlab
% Make a sphere with bumps and dents
m = objMakeBump('sphere',[50 pi/16 .1; 50 pi/16 -.1]);
% Scale to a bigger size
m = objScale(m,20);
% Cut a piece out
m = objCutSphere(m,16);
% Add thickness to the wall
m = objAddThickness(m,5);
% Set a new file name
m = objSet(m,'filename','sphere_for_print');
% Save and view
objSave(m);
objView(m);
```

NOTE: These functions are really meant to be the last thing you do to a model (in ShapeToolbox) before you print it or import it to some other software to fix/inspect/modify and then print. Prepare your model using the `objMake*`-functions, `objSet`, and whatever else you might need. Then do whatever prepping is needed using these functions. After that, you can use `objSet` to change the filename, for example, but don't try to do anything too fancy. As a general rule, make the model first, then modify for printing, then keep modifications (using ShapeToolbox) at a minimum.

NOTE: The models will probably have some defects that need to be repaired before they can be printed (some models might not be properly closed, there might be zero-area faces etc.). A 3D printing software that comes with a printer will probably be able to repair these automatically. Otherwise, you might need to use a separate program to repair the models.

### Materials, vertex groups, texture mapping

TODO. For now, see `help objMakePlain` and there the sections for `mtl` and `mtlfile`, as well as `uvcoords`. Also see `help objGroup`.

### Other options and considerations

TODO.

### More help

There is a very outdated manual at http://saarela.github.io/ShapeToolbox. It's advisable to stay away from it for now, except maybe for the "Gallery" which shows some examples of things you can do.


## Questions, comments, and answers

#### Octave does not find functions in private directory

The functions meant to be called by the user are in the m-directory of the toolbox. There are additional functions located in `m/private`, called by the main toolbox functions. Sometimes, when a toolbox function calls a private function that calls another private function, Octave gives an error message that the function is not found, something like:

```matlab
error: no such file, 'some_path/private/objSomething.m'
```

This happens randomly, most of the time it does not happen. It if does, just try again, or restart Octave, or something. It usually starts working again.

(In both Matlab and Octave documentation it is said that functions in a private directory are visible only to the fuctions in their parent directory. I have not found a mention of what the specification is for private functions calling each other.)

#### I didn't read the documentation and I don't know how to do X. What should I do?

Read the documentation.

#### I doesn't do what I want. It's probably a bug.

Please read the docs one more time, just in case.

#### Seriously, it doesn't work

Please send an email to `shapetoolbox at gmail dot com`.

#### You should have used object-oriented programming

Oh, please.

#### No, really

Not with this language. Maybe using another language later.

#### Can I design my new house with this?

You can, but you probably shouldn't. It would end up looking funny, and would probably not be very safe to live in.

#### Why is y up? z should be up.

No, y is up.
