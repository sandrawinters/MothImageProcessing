function [RGB,avRGB,stdRGB,mask,maskedIm,croprect,cropMask,maskedCropIm,flag] = MeasureROI(im,type,crop,nonlin,askFlag)
%Measures ROI from user-selected region of an image
%   Displays an image, asks user to crop (if crop = 1, default), then asks
%   user to mark ROI. ROI marking options (type parameter) are mostly based
%   on matlab draw functions: 'assisted' attempts to trace a boundary
%   between user-selected points; 'freehand' draws boundary directly from
%   user mouse movements (click down to start, release to finish),
%   'polygon' connects user-selected points with straight lines, and
%   'rectangle' draws a rectangle. Double-click in the ROI to finish. The
%   'spline' option (not a matlab draw function) uses spline interpolation
%   of user-selected points in a custom GUI to generate the ROI (click
%   'Start', click once to initiate, mark points with double-click
%   indicating final point, adjust points as necessary, click 'Save &
%   Exit'). A nonlinearization (square root transformation) is added for
%   visualization when nonlin = 1 (default). When askFlag is true
%   (default = 0), a popup asks whether the image should be flagged for
%   further inspection (NOTE: when type = spline and askFlag = 1, the flag
%   button in the ROI-marking GUI is overwritten by the flag popup).
%   Returns color (RGB, mean RGB, std RGB) data, binary mask of image
%   marking ROI region, masked image with ROI on a black background,
%   cropping information (crop rectangle, crop mask, masked crop image),
%   and whether the image was flagged.
%
%   INPUT
%   im (matrix): image to be measured (required)
%   type (string): type of ROI to use
%       options: 'assisted', 'freehand', 'polygon', 'rectangle' 'spline' (see doc drawassisted, drawfreehand, drawpolygon, drawrectangle; MarkSplineROI.m)
%       default: 'assisted'
%   crop (boolean): crop image before marking ROI? (default = 1)
%   nonlin (boolean): add nonlinearization for visualization? (default = 1) 
%       note: *only* for visualization, does not influence recorded data
%   askFlag (boolean): ask user (via popup) whether to flag image? (default = 0)
%
%   OUTPUT
%   RGB (n pixels x 3 matrix): RGB measurements from ROI
%   meanRGB(1 x 3 matrix): mean RGB from ROI
%   stdRGB (1 x 3 matrix): standard deviation of RGB from ROI
%   mask (logical matrix): binary image denoting ROI location in full image
%   maskedIm (matrix): image with ROI on black background
%   croprect (1 x 4 matrix): area of cropped region (see doc imcrop, argument rect; if no cropping is done, returns NaN)
%   cropMask (logical matrix): binary image denoting ROI location in the cropped image (if no cropping is done, returns NaN)
%   maskedCropIm (matrix): cropped image with ROI on black background
%   flag: flag (0, 1, or NAN)
%
%   CREATES
%   n/a
%
%   RELIES ON
%   n/a
%
%   Sandra Winters <sandra.winters@colorado.edu>
%   updated Jan 27 2026

%% check args & set defaults
if nargin<1
    error('no image provided')
end
im = im2double(im);

if nargin<2
    type = 'assisted'; 
end
type = lower(type);

if nargin<3
    crop = 1;
end

if nargin<4
    nonlin = 1;
end

if nargin<5
    askFlag = 0;
end

warning('off', 'Images:initSize:adjustingMag');

%% add sqrt nonlinearization (for visualization)
if nonlin==1
    imVis = AddNonlin(im,'sqrt'); 
else
    imVis = im;
end

%% crop
if crop==1
    [imVis,croprect] = imcrop(imVis); 
    close gcf
    imC = imcrop(im,croprect); 
else
    imC = im;
    croprect = NaN;
end

%% select ROI 
if strcmp(type,'spline')
    %run custom spline ROI marking function
    [cropMask,flag] = MarkSplineROI(imVis);
    % TODO deal with when this flag conflicts with one below (currently this would be overwritten)
else %matlab ROI function
    %display image
    figure('units','normalized','outerposition',[0 0 1 1]); 
    imshow(imVis); set(gcf,'WindowState','maximized')
        
    %draw ROI
    if strcmp(type,'assisted')
        title({'draw assisted setting:','click along edge; click on first point to connect; tweak markers; double-click in ROI'})
        roi = drawassisted;
    elseif strcmp(type,'freehand')
        title({'freehand setting:','click down; trace boundary; release click; tweak markers; double-click in ROI'})
        roi = drawfreehand;
    elseif strcmp(type,'polygon')
        title({'polygon setting:','click to connect polygon lines; click on first point to connect; tweak markers; double-click in ROI'})
        roi = drawpolygon;
    elseif strcmp(type,'rectangle')
        title({'rectangle setting:','drag cursor to draw rectangle; tweak markers; double-click in ROI'})
        roi = drawrectangle;
    else 
        error('unknown ROI type')
    end
    customWait(roi); %wait for user to interact with roi; double click to continue
    
    %create mask
    cropMask = createMask(roi);
    close gcf
end

%% update binary mask for cropped images
if crop
    figure('visible','off'); imshow(im);
    rect = drawrectangle('Position',croprect);
    mask = createMask(rect);
    mask(mask) = cropMask;
    close gcf
else
    mask = cropMask;
    cropMask = NaN;
end

%% generate masked (cropped) image
maskedIm = zeros(size(im));
maskedIm(repmat(mask,1,1,3)) = im(repmat(mask,1,1,3));

if crop
    maskedCropIm = zeros(size(imC));
    maskedCropIm(repmat(cropMask,1,1,3)) = imC(repmat(cropMask,1,1,3));
else
    maskedCropIm = NaN;
end

%% calculate color stats
RGB = ExtractPx(im,mask);
avRGB = mean(RGB);
stdRGB = std(RGB);

%% image screening -- option to flag images
if askFlag
    flag = questdlg('Flag image?','Flag','Yes','No','No');
else
    flag = NaN;
end

end %function

function [] = customWait(hROI)

% Listen for mouse clicks on the ROI
l = addlistener(hROI,'ROIClicked',@clickCallback);

% Block program execution
uiwait;

% Remove listener
delete(l);

end

% Reset warning
% TODO

function clickCallback(~,evt)

if strcmp(evt.SelectionType,'double')
    uiresume;
end

end

%% changelog
% 30 Jan 2026
% minor changes associated with --> 

% 27 Jan 2026
% added askFlag param
% added spline option for type
% maximized figure display for ROIs based on matlab draw functions 
% (backwards compatible)

% 18 Apr 2024
% fixed error in calculating color stats when crop = 1

% 16 Nov 2023
% fixed error in calculating color stats when crop = 0

% 8 May 2023
% added description

% 5 May 2023
% created (loosely) based on MarkROI.m, but updated to use matlab's built-in ROI functions

