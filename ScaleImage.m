function [scaledIm] = ScaleImage(im,scaleMeasured,scaleLength,ppUnit,sizeUp)
%Scales to a given pixels per unit based on scale bar
%   Scales image by converting to given pixels per unit (whatever
%   measurement unit is provided; should be consistent across arguments)
%   based on desired PPU / ( n pixels in scale bar / scale bar length ).
%   Does not change images below the target resolution unless sizeUp is
%   true. 
%
%   INPUT
%   im (matrix): image to process
%   scaleMeasured (double): length of measured scale bar (in pixels) (required)
%   scaleLength (double): length of actual scale bar; units should be the same across all variables (e.g. all in mm) (required)
%   ppUnit (double): desired pixels per unit; units should be consistent across variables (required)
%   sizeUp (boolean): increase image resolution where necessary? (default = 0)
%   
%   OUTPUT
%   scaled image
%
%   CREATES
%   n/a
%
%   RELIES ON
%   n/a
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 27 Jan 2021

%% check args & set defaults
if nargin<1
    error('no image provided')
end
if nargin<2
    error('no scale bar measurement provided')
end
if nargin<3
    error('no scalebar real length provided')
end
if nargin<4
    error('no pixels per unit provided')
end
if nargin<5
    sizeUp = 0;
end

%% rescale images to ppUnit (pixels per whatever unit is used in variables)
imPpUnit = scaleMeasured/scaleLength;
if sizeUp || imPpUnit>ppUnit
    scaledIm = imresize(im,ppUnit/imPpUnit); 
else
    scaledIm = im;
end
if imPpUnit<ppUnit
    disp('WARNING: image below target resolution (no rescaling performed)')
end

%% changelog
% 6 Feb 2023 
% created by simplifying ScaleImages for use with one image
