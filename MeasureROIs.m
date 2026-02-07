function [] = MeasureROIs(imDir,resDir,type,crop,nonlin,askFlag,imExt)
%Measures ROIs from user-selected regions of images
%   Loops through each image in a folder to measure ROIs. Displays the
%   image, asks user to crop (if crop = 1, default), then asks user to mark
%   ROI. ROI marking options (type parameter) are mostly based on matlab
%   draw functions: 'assisted' attempts to trace a boundary between
%   user-selected points; 'freehand' draws boundary directly from user
%   mouse movements (click down to start, release to finish), 'polygon'
%   connects user-selected points with straight lines, and 'rectangle'
%   draws a rectangle. Double-click in the ROI to finish and proceed to the
%   next image. The 'spline' option (not a matlab draw function) uses
%   spline interpolation of user-selected points in a custom GUI to
%   generate the ROI (click 'Start', click once to initiate, mark points
%   with double-click indicating final point, adjust points as necessary,
%   click 'Save & Exit'). A nonlinearization (square root transformation)
%   is added for visualization when nonlin = 1 (default). When askFlag is
%   true (default), a popup after each image asks whether it should be
%   flagged for further inspection (NOTE: when type = spline and
%   askFlag = 1, the flag button in the ROI-marking GUI is overwritten by
%   the flag popup). Returns a structure with fields containing color data
%   (RGB, mean RGB, std RGB), binary mask of image marking ROI region,
%   masked image with ROI on a black background, cropping information (crop
%   rectangle, crop mask, masked crop image), and whether the image was
%   flagged. Note that this format is consistent with other functions that
%   look for particular fields in results structures, e.g.
%   OutlineRegions.m, MaskImages.m, CropToROIs.m (all need .mask field),
%   StandardizeImages.m (needs .meanRGB field), etc.
%
%   INPUT
%   imDir (string): folder containing images to be measured (asks if not provided)
%   resDir (string): folder where .mat result files will be saved (asks if not provided)
%   type (string): type of ROI to use
%       options: 'assisted', 'freehand', 'polygon', 'rectangle' 'spline' (see doc drawassisted, drawfreehand, drawpolygon, drawrectangle; MarkSplineROI.m)
%       default: 'assisted'
%   crop (boolean): crop image before marking ROI? (default = 1)
%   nonlin (boolean): add gamma correction for visualization? (default = 1) 
%       note: *only* for visualization, does not influence recorded data
%   askFlag (boolean): ask user (via popup) whether to flag image? (default = 1)
%   imExt (string): image extension (default = '.tiff')
%
%   OUTPUT
%   n/a
%
%   CREATES
%   .mat files containing results for each image (named *image_name*_roiData.mat, saved in resDir)
%       roiData.RGB (n pixels x 3 matrix): RGB measurements from ROI
%       roiData.meanRGB(1 x 3 matrix): mean RGB from ROI
%       roiData.stdRGB (1 x 3 matrix): standard deviation of RGB from ROI
%       roiData.mask (logical matrix): binary image denoting ROI location in full image
%       roiData.maskedIm (matrix): image with ROI on black background
%       roiData.croprect (1 x 4 matrix): area of cropped region (see doc imcrop, argument rect; if no cropping is done, returns NaN)
%       roiData.cropMask (logical matrix): binary image denoting ROI location in the cropped image (if no cropping is done, returns NaN)
%       roiData.maskedCropIm (matrix): cropped image with ROI on black background
%       roiData.flag: flag (0 or 1)
%
%   RELIES ON
%   MeasureROI.m
%   ExtractPx.m
%   PRG folder & contents (when type = 'spline')
%   AddNonlin.m (when nonlin = 1)
%
%   Sandra Winters <sandra.winters@colorado.edu>
%   updated 6 Feb 2026

%% check args & set defaults
if nargin<1 || isempty(imDir)
    imDir = uigetdir('','Select folder of images');
end
if isfolder(imDir)==0
    error([imDir ' is not a folder'])
end

if nargin<2 || isempty(resDir)
    resDir = uigetdir('','Select folder of results');
end
if isfolder(resDir)==0
    mkdir(resDir)
end

if nargin<3 || isempty(type)
    disp("setting ROI type to 'assisted'")
    type = 'assisted';
end

if nargin<4 || isempty(crop)
    crop = 1;
end

if nargin<5 || isempty(nonlin)
    disp('adding square root transformation for visualization')
    nonlin = 1;
end

if nargin<6 || isempty(askFlag)
    askFlag = 1;
end

if nargin<7 || isempty(imExt)
    imExt = '.tiff';
end

%% get list of images in image directory
images = dir(fullfile(imDir,['*' imExt]));
images = {images.name};

if isempty(images)
    error(['No ' imExt ' images in ' imDir])
end

%% measure images
%run through images, skipping those that are already done
for i = 1:length(images)
    if exist(fullfile(resDir,strrep(images{i},imExt,'_roiData.mat')),'file')==0
        %get image
        im = imread(fullfile(imDir,images{i}));

        %mark ROI & add results to structure
        roiData.image = images{i};
        [roiData.RGB, ...
         roiData.meanRGB, ...
         roiData.stdRGB, ...
         roiData.mask, ...
         roiData.maskedIm, ...
         roiData.croprect, ...
         roiData.cropMask, ...
         roiData.maskedCropIm, ...
         roiData.flag] = MeasureROI(im,type,crop,nonlin,askFlag);
        
        %save the files
        save (fullfile(resDir,strrep(images{i},imExt,'_roiData.mat')), 'roiData');

        %ask if want to continue
        if i == length(images)
            msgbox('Congratulations! You have finished meauring all images.','Done','modal');
        else
            resp = questdlg('Next image?','Continue','Yes','Exit','Yes');

            if strcmp(resp,'Exit')
                return
            end
        end

    end
end

%% changelog 
% 6 Feb 2026
% updated documentation

% 27 Jan 2026
% added imExt param (was variable); added askFlag param; backwards compatible

% 8 May 2023
% added description

% 5 May 2023
% created based on MeasureColor.m, but updated to use MeasureROI (which uses built-in matlab ROIs) instead of PRG spline interpolation
