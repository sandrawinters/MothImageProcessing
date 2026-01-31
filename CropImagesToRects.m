function [] = CropImagesToRects(imDir,rectDir,saveDir,rectVar,append)
%Crops all images in a folder to pre-specified rectangle regions
%   For each image in a folder (imDir), crops based on crop rectangles
%   saved in rectDir. The variable containing the crop rectangle is
%   specified by rectVar (see details below). Crops are saved in saveDir
%   as <original_filename>_append (default append is ''). 
%
%   INPUT
%   imdir (string): folder containing .tiff images to be cropped (asks if not provided)
%   rectDir (string): folder containing .mat result files containing crop rectangles (asks if not provided)
%       each image must match a results file that starts with the image filename (i.e. <image_filename>_any_text.mat
%   saveDir(string): folder where cropped images will be saved (asks if not provided)
%   rectVar (string): name of the variable to import from the matching .mat file in rectDir
%       must contain a crop rectangle, format [x y width height], see doc imcrop
%       if the crop rectangle is a field of a structure, send it in the format 'structure.field'
%       default = 'cropRect'
%   append (string): text to add to image filename when saving crop
%
%   OUTPUT
%   n/a
%
%   CREATES
%   cropped images saved in saveDir using original filenames (default) or with _append added
%
%   RELIES ON
%   n/a
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 14 Feb 2025

%% check args & set defaults
if nargin<1 || isempty(imDir)
    imDir = uigetdir('','Select folder of images'); 
end
if exist(imDir,'dir')==0
    error('image directory does not exist')
end

if nargin<2 || isempty(rectDir)
    rectDir = uigetdir('','Select folder of results');
end
if exist(rectDir,'dir')==0
    mkdir(rectDir)
end

if nargin<3 || isempty(saveDir)
    saveDir = uigetdir('','Select folder of results');
end
if exist(saveDir,'dir')==0
    mkdir(saveDir)
end

if nargin<4 || isempty(rectVar)
    rectVar = 'cropRect';
end

if nargin<5
    append = '';
end
if ~isempty(append)
    append = ['_' append];
end

imExt = '.tiff';

%% get image list
ims = dir(fullfile(imDir,['*' imExt]));
ims = ims(~startsWith({ims.name},'.')); %exclude hidden mac files

%% crop each image
for i = 1:length(ims)
    %skip previously cropped images
    if exist(fullfile(saveDir,ims(i).name),'file')==0
        %get image
        im = imread(fullfile(imDir,ims(i).name));
        
        %find matching results file
        resFile = dir(fullfile(rectDir,[strrep(ims(i).name,imExt,'') '*.mat']));
        
        %if there is exactly 1 matching results file, process image; if not, skip and display warning
        if isscalar(resFile) 
            %get crop rectangle
            cropRect = load(fullfile(rectDir,resFile.name),extractBefore(rectVar,'.')); %if rectVar is structure.field, import the structure
            cropRect = cropRect.(extractBefore(rectVar,'.'));
            if contains(rectVar,'.') %if rectVar is structure.field, now get the field
                cropRect = cropRect.(extractAfter(rectVar,'.')); 
            end
            
            %crop image
            imCrop = imcrop(im,cropRect);
    
            %save
            imwrite(imCrop,fullfile(saveDir,strrep(ims(i).name,imExt,[append imExt])))
        else
            if isempty(resFile)
                disp(['WARNING: skipping image ' ims(i).name ', no results file found'])
            else
                disp(['WARNING: skipping image ' ims(i).name ', multiple matching results files found'])
            end
        end
    end
end

end %function

%% changelog
% 14 Feb 2025
% updated to exclude .tiff files that start with . (so are actually hidden
% mac files, not tiffs SIGH)