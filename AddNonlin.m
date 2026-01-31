function [imNonlin] = AddNonlin(im,type,param,plotFig)
%Adds the specified nonlinearization to an image
%   Transforms each pixel in the image based on the specified
%   type of nonlinearization function. When type = 'sqrt' (default), adds 
%   a square root transformation. When type = 'power', adds a power
%   transformation  with the exponent set to the value of param (default = 
%   0.5). When type = 'gamma', adds a gamma transformation with gamma set
%   to the value of param (default = 2.2). Plots the image when plotFig is
%   true (default false). Returns the image as a double. 
%
%   INPUT
%   im (matrix): image to transform
%   type (string): type of nonlinearization to add
%       'sqrt' - adds square root transformation (same as 'power' with param = 0.5)
%       'power' - adds a power transformation with the exponent set to the param value, e.g. if param = 0.6, returns image.^0.6
%       'gamma' - adds a gamma transformation with gamma set to the param value
%   param (double): parameter to use for transformation; specifies the exponent to use for power transformations or gamma to use for gamma transformations
%       defaults: type 'power' param = 0.5; type 'gamma' param = 2.2
%       ignored when type = 'sqrt'
%   plot (boolean): plot the resulting image? (default = 0)
%
%   OUTPUT
%   imNonlin (matrix): image with nonlinearization applied (returned as double)
%
%   CREATES/SAVES
%   n/a
%
%   RELIES ON
%   n/a
%
%   EXAMPLES
%   imNonlin = AddNonlin(im,'sqrt') --> square root transformation
%   imNonlin = AddNonlin(im,'gamma') --> gamma transformation with default gamma = 2.2
%   imNonlin = AddNonlin(im,'power',0.8) --> power transformation with exponent = 0.8
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 5 May 2023

%% check args & set defaults
if nargin<1
    error('no image provided')
end
im = im2double(im);

if nargin<2
    type = 'sqrt';
end
type = lower(type);
if ismember(type,{'sqrt','power','gamma'})==0
    error('unknown transformation type')
end

if nargin<3
    if ismember(type,{'sqrt','power'})
        param = 0.5; %square root transformation
    elseif strcmp(type,'gamma')
        param = 2.2; %default gamma
    end
end

if nargin<4
    plotFig = 0; 
end

%% add nonlinearization
if strcmp(type,'sqrt')
    imNonlin = realsqrt(im);
elseif strcmp(type,'power')
    imNonlin = real(im.^param);
elseif strcmp(type,'gamma')
    H = vision.GammaCorrector('Gamma',param);
    imNonlin = step(H,im);
end

%% plot
if plotFig
    figure; imshow(imNonlin)
end

