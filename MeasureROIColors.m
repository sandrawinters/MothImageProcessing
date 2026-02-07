function [] = MeasureROIColors(imDir,maskDir,resDir,overwrite,imExt)
%Calculates color metrics for folders of images & binary masks
%   For each image in imDir, imports the associated mask in maskDir
%   (displays warning & skips image if no matching mask is found), extracts
%   pixels denoted by the mask, and calculates the mean, median, and
%   standard deviation of the RGB values and the number of pixels in the
%   mask. Image filename, color/size metrics, and the mask are saved to a
%   structure in resDir (see specifics below).
%
%   INPUT 
%   imDir (string): folder containing images to be measured (asks if not provided)
%   maskDir (string): folder containing binary masks associated with images (asks if not provided)
%       each mask must start with the same filename as the associated image (i.e. image1.tiff --> mask1.tiff or mask1*.tiff) 
%   resDir (string): folder where .mat result files will be saved (asks if not provided)
%   overwrite (logical): overwrite existing results files? (default = 0)
%   imExt (string): file etension for images and masks (default = '.tiff')
%
%   OUTPUT
%   n/a
%
%   CREATES
%   .mat files containing results for each image (named *image_name*_roiData.mat, saved in resDir)
%       roiData.RGB (n pixels x 3 matrix): RGB measurements from ROI
%       roiData.meanRGB (1 x 3 matrix): mean RGB from ROI
%       roiData.medianRGB (1 x 3 matrix): median RGB from ROI
%       roiData.stdRGB (1 x 3 matrix): standard deviation of RGB from ROI
%       roiData.nPx (double): number of pixels in ROI
%       roiData.mask (logical matrix): binary image denoting ROI location in full image
%
%   RELIES ON 
%   MeasureROIColors.m
%   ExtractPx.m
%
%   EXAMPLE
%   MeasureROIColors('folder/of/images', ... 
%                    'folder/of/masks', ... 
%                    'folder/for/results', ... 
%                    1, ... %overwrite existing results files (default = 0)
%                    '.png') %images & masks are .png files (default = '.tiff')
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

if nargin<2 || isempty(maskDir)
    maskDir = uigetdir('','Select folder of binary masks');
end
if isfolder(maskDir)==0
    error([maskDir ' is not a folder'])
end

if nargin<3 || isempty(resDir)
    resDir = uigetdir('','Select folder of results');
end
if isfolder(resDir)==0
    mkdir(resDir)
end

if nargin<4 || isempty(overwrite)
    overwrite = 0;
end

if nargin<5 || isempty(imExt)
    imExt = '.tiff';
end

%% get list of images in image directory
ims = dir(fullfile(imDir,['*' imExt]));

if isempty(ims)
    error(['No ' imExt ' images in ' imDir])
end

%% measure images
%run through images, skipping those that are already done
for i = 1:length(ims)
    if overwrite || exist(fullfile(resDir,strrep(ims(i).name,imExt,'_roiData.mat')),'file')==0
        %get image
        im = imread(fullfile(imDir,ims(i).name));

        %get mask (skip image & display warning if mask not found)
        maskFile = dir(fullfile(maskDir, ...
                                strrep(ims(i).name,imExt,['*' imExt])));
        if length(maskFile)<1
            disp(['WARNING: skipping image ' ims(i).name ' - no binary mask found'])
        elseif length(maskFile)>1
            disp(['WARNING: skipping image ' ims(i).name ' - multiple matching binary masks found'])
        else
            mask = imread(fullfile(maskDir,maskFile(1).name));

            %calculate color metrics for ROI & add results to structure
            roiData.image = ims(i).name;
            [roiData.RGB, ...
             roiData.meanRGB, ...
             roiData.medianRGB, ... 
             roiData.stdRGB, ... 
             roiData.nPx] = MeasureROIColor(im,mask);
    
            roiData.mask = mask; %include mask in structure (for consistency with other functions)
            
            %save
            save (fullfile(resDir,strrep(ims(i).name,imExt,'_roiData.mat')), 'roiData');
        end
    end
end

end %function


%% changelog
% 6 Feb 2026
% created
