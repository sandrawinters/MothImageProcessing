function [patchRGB,meanRGB,stdRGB,medianRGB,flag,clicks,zoomXY] = MeasureMacbeth(im,nonlinVis,zoomFirst)
% Measures Macbeth color standard patches in an image
%   User marks center of four corner patches in Macbeth (X-Rite) color
%   checker chart; each of the 24 patches are then measured & color metrics
%   calculated. Displays the selected regions of each patch & a plot of of 
%   the RGB values for greyscale patches, and asks user whether or not to 
%   flag the image for removal/inspection. Displays a nonlinear (square 
%   root transformation) version of the image when nonlinVis is true.
%   Allows user to zoom in on standard before marking when zoomFirst is
%   true. 
%   Patch order is based on xrite patch numbers (brown >> cyan; white >> 
%   black; see GetMacbethColor). 

%   INPUT
%   im (m x n x 3 matrix): image to measure
%   nonlinVis (boolean): add nonlinarization for visualization? (default = 1)
%   zoomFirst (boolean): crop to standard before measuring? (default = 0)
%
%   OUTPUT
%   patchRGB (structure): contains pixel values for each patch
%   meanRGB (24x3 matrix): mean RGB values for each patch
%   stdRGB (24x3 matrix): standard deviation of RGB values for each patch
%   flag (boolean): flag standard?
%   clicks (4x2 matrix): x,y click locations (order: brown, cyan, white, black)
%   crop (1x4 vector): structure containing XLim and YLim fields (from axis handle after zoom)
% 
%   CREATES
%   n/a
%
%   RELIES ON
%   divideLine.m
%   CalcMacbethSquares.m
%   CalcMacbethColors.m
%   AddNonlin.m (if nonlinVis==1)
%
%   Sandra Winters <sandra.winters@helsinki.fi> 
%   based partially on code from Will Allen
%   updated 5 Jun 2025

%% check args & set defaults
if nargin<1 || isempty(im)
    error('no image provided')
end

if nargin<2 || isempty(nonlinVis)
    nonlinVis = 1;
end

if nargin<3 || isempty(zoomFirst)
    zoomFirst = 0;
end

%% measure macbeth patches
im = im2double(im);

%add nonlin
if nonlinVis
    imDisp = AddNonlin(im); %apply square root transformation to aid visualisation
else
    imDisp = im;
end

%display image
figure; imshow(imDisp)

%zoom
if zoomFirst
    title('zoom as needed, then press a key')
    zoom on
    pause
    zoom off
end
ax = gca;
zoomXY.XLim = ax.XLim;
zoomXY.YLim = ax.YLim;

%get user input for location of corner color patches
title('Click the center of the squares in the following order: white, black, brown, cyan')
hold on

clicks = zeros(4,2);
clicks(1,:) = ginput(1); %white box
plot(clicks(1,1),clicks(1,2),'x');

clicks(2,:) = ginput(1); %black box
plot(clicks(2,1),clicks(2,2),'x');

clicks(3,:) = ginput(1); %brown box
plot(clicks(3,1),clicks(3,2),'x'); 

clicks(4,:) = ginput(1); %cyan box
plot(clicks(4,1),clicks(4,2),'x');

%calculate patch location
patches = CalcMacbethSquares(clicks);

%calculate patch color
[patchRGB,meanRGB,stdRGB,medianRGB,flag] = CalcMacbethColors(im,patches);

close gcf


%% changelog
% 5 Jun 2025
% changed crop var to zoomXY to prevent future confusion 

% 3 Jun 2025
% updated zoom approach (dynamic zoom + click instead of crop)
% crop output now contains structure with XLim and YLim fields (from axis
% handle after zoom) instead of crop rectangle; otherwise, backwards
% comppatible

% 27 Oct 2023
% created new functions CalcMacbethSquares (calculates patch locations) 
% and CalcMacbethColor (measures color within patch locations), and moved 
% relevant code to those functions
% switched nonlin from vision.gammaCorrector to AddNonlin
