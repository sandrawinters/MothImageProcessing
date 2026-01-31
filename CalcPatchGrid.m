function [patchCircles,xyCoords,radius] = CalcPatchGrid(clicks,gridSz,patchLen,plotRes)
%Calculates all patch locations of a color standard grid, based on 4 corner clicks 
%   Calculates the location of each color patch in a grid based on the
%   locations of the four corner patches (clicks param, probably from
%   MeasureStandard.m). Calculates the center of each patch (output in
%   xyCoords) and the circular outline of the patch (outlines in
%   patchCircles), based on a radius of patchLen proportion of the size of
%   each grid square. All locations are based on the x,y image coordinate
%   system, i.e. x = cols, y = rows, both calculated from bottom left
%   corner of image; see documentation for ginput). When plotRes is true
%   (default), the centers and outlines of the patches are plotted on the
%   current axes (i.e., on an already displayed image).
%
%   INPUT
%   clicks (4x2 double): click locations of corner squares, using x-y coordinate system 
%       rows: white, black, brown, cyan
%       cols: x, y coordinates (from bottom left corner, see doc ginput)
%   gridSz (1 x 2 double): size of grid
%       default = [6 4] (x-rite passport standard)
%   patchLen (double): proportion of the size of each grid square to use as the radius for selecting the patch region
%       e.g., if patchLen = 0.25, will use 1/4 of the size of each grid square as the radius to determine the patch region 
%       default = 0.25
%   plotRes (boolean): plot patches on current figure? (will be added to current axes)
%       default = 1
%
%   OUTPUT
%   patchCircles (201 x 2 x n patches double): outline of patch locations for each square 
%       dim 1: 201 evenly spaced points (x,y in dim 2) denoting the circular patch region 
%       dim 2: x,y coordinate of each point
%       dim 3: color patches (same order as macxy above)
%   xyCoords (n patches x 2 double): center location of each patch, using x-y coordinate system
%       rows: patches, order is based on xrite patch numbers (brown >> cyan; white >> black; see GetMacbethColor)
%       cols: x,y coordinates (from bottom left corner, see doc ginput)
%   radius (double): radius length 
%
%   CREATES
%   n/a
%
%   RELIES ON
%   divideLine.m
%
%   Sandra Winters <sandra.winters@colorado.edu>
%   updated 30 Jan 2026

%% check args & set defaults
if nargin<1
    error('no clicks provided')
end

if nargin<2 || isempty(gridSz)
    gridSz = [6 4]; %macbeth
end

if nargin<3 || isempty(patchLen)
    patchLen = 0.25;
end

if nargin<3
    plotRes = 1;
end

%% calculate patch locations
if prod(gridSz)==2
    xyCoords = clicks;
else
    %add clicks to corner patches
    xyCoords= zeros(prod(gridSz),2); %coordinates of each patch
    corners = [1 gridSz(1) prod(gridSz)-gridSz(1)+1 prod(gridSz)]; %rows of corners in ^
    xyCoords(corners,:) = clicks; %clicks are on 4 corners 
    
    %calculate center of each non-corner patch
    xyCoords(corners(1):corners(2),:) = divideLine([xyCoords(corners(1),:); xyCoords(corners(2),:)], gridSz(1)); %first col
    
    if gridSz(2)>1 
        xyCoords(corners(3):corners(4),:) = divideLine([xyCoords(corners(3),:); xyCoords(corners(4),:)], gridSz(1)); %last col
    end
    
    if gridSz(2)>3
        for i = 2:gridSz(2)-1
            coords = (i-1)*gridSz(1)+1;
            coords = coords:coords+gridSz(1)-1;
            xyCoords(coords,:) = divideLine([xyCoords(coords(1),:); xyCoords(coords(end),:)], gridSz(1)); %intermediate cols
        end
    end
end

%% calculate patches
radius = sqrt((xyCoords(1,1)-xyCoords(2,1))^2 + (xyCoords(1,2)-xyCoords(2,2))^2).*patchLen; %draw a circle around each center, with a radius equal to patchLen * distance between patches
[x,y] = cylinder(radius,200); %create a circle of n radius with 200 equally spaced points

patchCircles = zeros(201,2,prod(gridSz));
for i = 1:length(xyCoords)
    patchCircles(:,1,i) = x(1,:)+xyCoords(i,1);
    patchCircles(:,2,i) = y(1,:)+xyCoords(i,2);
end

%% plot patches
if plotRes
    %plot patch centers
    hold on
    plot(xyCoords(:,1),xyCoords(:,2),'x','Color','green') %mark center locations

    %plot patch radius
    for i = 1:length(xyCoords)
        plot(patchCircles(:,1,i),patchCircles(:,2,i),'Color','cyan');
    end
end

end %function

%TODO update to use circle objects (check if faster...)

%% changelog
% 30 Jan 2026
% minor edits to documentation

% 21 Jul 2025
% updated to deal with error when only 2 patches (sets xyCoords to clicks);
% changed 3rd dimension size of patchCircles to be prod(gridSz), had been
% hard-coded as 24; updated documentation; minor cleaning for clarity

% 16 Nov 2024
% created based on CalcMacbethSquares (as more general version, should ultimately replace it)

