function [] = MarkROIs(imDir,maskDir,type,crop,nonlin,imExt)
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
%   is added for visualization when nonlin = 1 (default). Saves a binary 
%   mask of image marking ROI region to maskDir using original filename.
%   (Note: to take color measurements from ROI region, see MeasureROIs.m.)
%
%   INPUT
%   imdir (string): folder containing images to be measured (asks if not provided)
%   resDir (string): folder where .mat result files will be saved (asks if not provided)
%   type (string): type of ROI to use
%       options: 'assisted', 'freehand', 'polygon', 'rectangle' 'spline' (see doc drawassisted, drawfreehand, drawpolygon, drawrectangle; MarkSplineROI.m)
%       default: 'assisted'
%   crop (boolean): crop image before marking ROI? (default = 1)
%   nonlin (boolean): add gamma correction for visualization? (default = 1) 
%       note: *only* for visualization, does not influence recorded data
%   imExt (string): image extension (default = '.tiff')
%
%   OUTPUT
%   n/a
%
%   CREATES
%   binary masks of ROIs saved in maskDir using original filenames
%
%   RELIES ON
%   PRG folder & contents (when type = 'spline')
%   AddNonlin.m (when nonlin = 1)
%
%   Sandra Winters <sandra.winters@colorado.edu>
%   updated 30 Jan 2026

%% check args & set defaults
if nargin<1 || isempty(imDir)
    imDir = uigetdir('','Select folder of images');
end
if isfolder(imDir)==0
    error([imDir ' is not a folder'])
end

if nargin<2 || isempty(maskDir)
    maskDir = uigetdir('','Select folder of results');
end
if isfolder(maskDir)==0
    mkdir(maskDir)
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

if nargin<6 || isempty(imExt)
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
    if exist(fullfile(maskDir,images{i}),'file')==0
        %get image
        im = imread(fullfile(imDir,images{i}));

        %mark ROI & generate binary mask
        [~,~,~,mask] = MeasureROI(im,type,crop,nonlin,0);
        
        %save mask
        imwrite(mask,fullfile(maskDir,images{i}));

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
% 30 Jan 2026
% created as a simplified version of MeasureROIs that only marks the ROI
% and creates a binary mask (no additional data saved in a structure)
% note that this is NOT linked with MarkROI.m (which I think was a working
% file that wasn't completed/used...)