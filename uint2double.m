function [dblIm,type] = uint2double(uintIm)
%Converts uint values to 0-1 doubles
%   Determines format of input based on max value, then converts from
%   uint32, uint16, or uint8 to double level precision. Also works for
%   double input (just returns without processing). 
%
%   INPUT
%   uintIm (matrix; required): image (likely uint-something, but will work for double -- will just return same image)
%   
%   OUTPUT
%   dblIm (matrix): image convered to double level precision
%   type (double): detected image type (integer representing max pixel value)
%
%   CREATES
%   n/a
%
%   RELIES ON
%   n/a
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 09 Jun 2020

%% check args & set defaults
if nargin<1
    error('No RGB values provided')
end

if isnumeric(uintIm)==0
    error('RGB values must be numeric');
end

%% transform image from uintX to double
maxVal = max(max(max(uintIm)));
if isa(uintIm,'uint32') || maxVal >= 2^16
    type = 2^32-1;
elseif isa(uintIm,'uint16') || maxVal >= 2^8
    type = 2^16-1;
elseif isa(uintIm,'uint8') || maxVal > 1
    type = 2^8-1;
else
    type = 1;
end

%% convert image to double
dblIm = double(uintIm)./type;

