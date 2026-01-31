function [px,rowcol] = ExtractPx(im,mask)
%Extracts pixels in binary mask from an image
%   Extracts pixel values from an image based on an associated binary mask 
%   (pixels where mask = 1). Returns vectorized pixel values separated by 
%   color channel, i.e. greyscale image: n_px x 1, color image: n_px x 3 
%   (red, green, blue color channels). Also returns the pixel location 
%   (row, column) for each pixel. 
%
%   INPUT
%   im (matrix): image to process
%   mask (logical matrix): binary mask denoting pixels to extract 
%
%   OUTPUT
%   px (matrix): matrix of pixel values (n pixels x n color channels)
%   rowcol (matrix): location (row, column) for each pixel in px (n pixels x 2)
%   
%   CREATES
%   n/a
%
%   RELIES ON
%   n/a
%   
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 19 Apr 2021

%% check args & set defaults
if nargin<1
    error('no image provided')
end

if nargin<2
    error('no image mask provided')
end
if size(mask,1)~=size(im,1) || size(mask,2)~=size(im,2) || size(mask,3)~=1
    error(['mask should be a binary mask (m x n x 1) of the same dimensions as image; size mask = ' num2str(size(mask)) ' , size image = ' num2str(size(im))])
end
if islogical(mask)==0
    mask = logical(mask);
end

%% extract pixels
[r,c] = find(mask);
rowcol = [r,c];

if size(im,3)>1
    mask = repmat(mask,1,1,size(im,3));
end

imVec = im(:);

px = imVec(mask(:));
px = reshape(px,[],size(im,3));

end

