function [imStd,rsq,satPx,negPx] = StandardizeImage(im,stdMeasured,stdActual,checkFit)
%Standardizes an image based on measurement from color standard
%   Standardizes image by rescaling each color channel based on 
%   [actual standard reflectance] / [measured standard reflectance] when n
%   standards = 1, or a 2nd degree polynomial fit when n standards > 1.
%   Fixes saturated/negative pixels by setting valuse >1 to 1 & <0 to 0. 
%   Standardized image returned as double (0-1 scale). Also returns the 
%   R^2 of the transformation, the location of saturated pixels (>1), & the 
%   location of negative (<0) pixels. 
%
%   INPUT
%   im (matrix): image to standardize
%   stdMeasured (double): mean RGB values measured from image
%       format [R G B]
%   stdActual (double): RGB reflectance of color standard
%       format either [R G B] or single value to be used for all color channels
%       should be on 0-1 scale (e.g. 20% reflectance = 0.2)
%       default = 0.2
%   checkFit (boolean): calculate R^2 for model fit? (default = 1)
%       turning this off will increase speed
%   
%   OUTPUT
%   imStd (matrix): standardized image
%   rsq (double): r squared of transformation
%   satPx (matrix): indices of saturated pixels (corrected to 1); format [m1 n1; m2 n2; ... ]
%   negPx (matrix): indices of negative pixels (corrected to 0); format [m1 n1; m2 n2; ... ]
%
%   CREATES
%   n/a
%
%   RELIES ON
%   uint2double.m
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 19 Nov 2020

%% check args & set defaults
if nargin<1
    error('No image provided')
end

if nargin<2
    error('No standard data provided')
end

if nargin<3
    stdActual = 0.2;
    disp('No standard reflectance provided; using 0.2')
end
if size(stdActual,2)==1 
    stdActual = repmat(stdActual,[1 3]);
end
if size(stdActual,2)~=3
    error('Standard reflectance should be 1 or 3 unit vector')
end
if sum(stdActual(:)>1) || sum(stdActual(:)<0)
    error('Standard reflectance should be between 0 and 1')
end

if nargin<4
    checkFit = 1;
end

%% convert to double
im = uint2double(im);
stdMeasured = uint2double(stdMeasured); 

%% standardize image
if size(stdActual,1)==1
    %use linear transformation based on single value
    imStd = zeros(size(im));
    imStd(:,:,1) = im(:,:,1).*(stdActual(1)/stdMeasured(1));
    imStd(:,:,2) = im(:,:,2).*(stdActual(2)/stdMeasured(2));
    imStd(:,:,3) = im(:,:,3).*(stdActual(3)/stdMeasured(3));
else
    %use polynormial transformation

    if size(stdActual,1)==2
        n = 1; %use 1st degree transform for 2 patches
    else
        n = 2; %use 2nd degree transform for >2 patches
    end

    polyR = polyfit(stdMeasured(:,1),stdActual(:,1),n);
    polyG = polyfit(stdMeasured(:,2),stdActual(:,2),n);
    polyB = polyfit(stdMeasured(:,3),stdActual(:,3),n);
    
    imStd = zeros(size(im));
    imStd(:,:,1) = polyval(polyR,im(:,:,1));
    imStd(:,:,2) = polyval(polyG,im(:,:,2));
    imStd(:,:,3) = polyval(polyB,im(:,:,3));
end

%% check transformation fit
if checkFit
    %calculate r squared
    m = fitlm(im(:),imStd(:));
    rsq = m.Rsquared.Ordinary;
else
    rsq = NaN;
end

%% fix saturated & negative pixels
maxPx = max(imStd,[],3);
[r,c] = find(maxPx>=1);
satPx = [r,c];

minPx = min(imStd,[],3);
[r,c] = find(minPx<=0);
negPx = [r,c];
    
imStd(imStd>1) = 1;
imStd(imStd<0) = 0;

end

