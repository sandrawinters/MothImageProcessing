function [RGB,meanRGB,medianRGB,stdRGB,nPx] = MeasureROIColor(im,mask)
%Calculates color metrics of image ROI
%   Extracts all pixels in an image (im arg) that are contained in the ROI
%   denoted by a binary mask (mask arg). Returns the pixel values (in RGB:
%   n pixels x 3 matrix, cols are R, G, B), the mean, median, and standard
%   deviation of the RGB values, and the number of pixels in the mask.
%   
%   INPUT
%   im (image matrix): image to be measured (required)
%   mask (logical matrix): binary image denoting ROI location in image
%       dimensions 1 & 2 must match image (i.e. same num of rows, cols)
%   OUTPUT
%   RGB (n pixels x 3 matrix): RGB measurements from ROI, cols are R, G, B
%   meanRGB (1 x 3 matrix): mean RGB from ROI
%   medianRGB (1 x 3 matrix): median RGB from ROI
%   stdRGB (1 x 3 matrix): standard deviation of RGB from ROI
%   nPx (double): number of pixels in mask
%
%   CREATES
%   n/a
%
%   RELIES ON
%   ExtractPx.m
%
%   Sandra Winters <sandra.winters@colorado.edu>
%   updated 6 Feb 2026

%% check args & set defaults
if nargin<1
    error('no image provided')
end
im = im2double(im);

if nargin<2
    error('no binary mask provided'); 
end
mask = logical(mask);

%% extract pixels & calculate color stats
RGB = ExtractPx(im,mask);
meanRGB = mean(RGB);
medianRGB = median(RGB);
stdRGB = std(RGB);

mask = mask(:,:,1); %make sure mask is 2D for calculating nPx
nPx = sum(double(mask(:))); %ROI size (in pixels)

end %function


%% changelog
% 6 Feb 2026
% created

