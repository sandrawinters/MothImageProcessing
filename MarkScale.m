function [scale] = MarkScale(im,nonlinVis,zoomFirst,realScaleLength)
%Mark scale bar in an image
%   Displays image im and asks user to zoom in (if zoomFirst is true, 
%   default = false; zoom until satisfied, then press any key), then draw a
%   line across the scale bar (reposition until satisfied, then press any 
%   key). Adds a square root transformation for visualization when 
%   nonlinVis = true (default). Displays the real length of the scale bar 
%   above the image when provided (scaleLength param). Returns the scale 
%   bar location, length (in pixels), real length (in realScaleLength
%   units) in a structure. 
%
%   INPUT
%   im (image matrix): image to process
%   nonlinVis (boolean): generate nonlinear image for visualization? (default = true)
%   zoomFirst (boolean): zoom in before marking scale bar (default = false); set to true when scale bar is small
%   realScaleLength (double): real length of scale bar (e.g., in mm)
%       note: only used to display above image (to prevent measurement-coding mismatches)
%       default = NaN
%   
%   OUTPUT
%   n/a
%
%   CREATES
%   .mat file for each image (named <image_name>_scaleBar.mat, saved in resDir); each contain structure called scale:
%       scale.image (string): image filename
%       scale.coords (matrix): coordinates of scale bar endpoints
%       scale.length (double): length of scale bar (in pixels)
%       scale.realLength (double): real length of scale bar (realScaleLength param)
%       scale.resolution (double): resolution of image (in pixels per unit of realLength)
%   
%   RELIES ON
%   AddNonlin.m (if nonlinVis is true)
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 21 Jul 2025

%% check args & set defaults
if nargin<1
    error('no image provided')
end

if nargin<2 || isempty(nonlinVis)
    nonlinVis = 1;
end

if nargin<3
    zoomFirst = 0;
end

if nargin<4
    realScaleLength = NaN;
end

%% measure scale bar
%add square root transformation
if nonlinVis==1
    im = AddNonlin(im);
end

%display image
figure('units','normalized','outerposition',[0 0 1 1]); 
imshow(im); set(gcf,'WindowState','maximized')

%zoom
if zoomFirst
    title('zoom as needed, then press a key')
    zoom on
    pause
    zoom off
end

%mark scale bar
if isnan(realScaleLength) 
    title('draw line across the scale bar, then press a key')
else
    title(['draw line across the ' num2str(realScaleLength) ' unit scale bar, then press a key'])
end

line = drawline(gca); pause
scale.coords = line.Position;
% scale.length = sqrt( (scale.coords(1,1)-scale.coords(1,2))^2 + (scale.coords(2,1)-scale.coords(2,2))^2 ); %length in pixels
scale.length = sqrt( (scale.coords(1,1)-scale.coords(2,1))^2 + (scale.coords(1,2)-scale.coords(2,2))^2 ); %length in pixels
scale.realLength = realScaleLength;
scale.resolution = scale.length / scale.realLength; %in pixels per unit of realLength

%close figure
close(gcf)

end

%% changelog
% 22 Jan 2026
% added code to maximize figure display

% 21 July 2025
% added resolution field to output

% 3 Jun 2025
% updated to add scale length as title if provided (to prevent mismatches);
% also saves as realLength field; defaults to NaN (backwards compatible)

% 16 Jan 2025
% created by chunking code from MarkScales.m
% added zoomFirst param to give zoom option (this will replace MarkScale2,
% which has built-in zoom)
% corrected error in distance formula (!) !!! RE-RUN ANYTHING FROM BEFORE THIS DATE !!!
