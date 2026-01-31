function [] = AddNonlins(origDir,newDir,type,param,overwrite)
%Adds the specified nonlinearization to a folder of images
%   For each image in origDir, transforms each pixel in the image based on 
%   the specified type of nonlinearization function. When type = 'sqrt' 
%   (default), adds a square root transformation. When type = 'power', adds 
%   a power transformation  with the exponent set to the value of param 
%   (default =  0.5). When type = 'gamma', adds a gamma transformation with 
%   gamma set to the value of param (default = 2.2). Transformed images are
%   saved to newDir using original file names. Set to work for .tiff images
%   (for other types, change imExt = '.tiff' below to the desired file 
%   type). 
%   
%   INPUT
%   origDir (string): folder containing images to process (asks if not included)
%   newDir (string): folder where processed images will be saved (asks if not included)
%   type (string): type of nonlinearization to add
%       'sqrt' - adds square root transformation (same as 'power' with param = 0.5)
%       'power' - adds a power transformation with the exponent set to the param value, e.g. if param = 0.6, returns image.^0.6
%       'gamma' - adds a gamma transformation with gamma set to the param value
%   param (double): parameter to use for transformation; specifies the exponent to use for power transformations or gamma to use for gamma transformations
%       defaults: type 'power' param = 0.5; type 'gamma' param = 2.2
%       ignored when type = 'sqrt'
%   overwrite (boolean): overwrite existing files? (0=no, 1=yes; default=0)
%
%   OUTPUT
%   n/a
%
%   CREATES/SAVES
%   processed images (saved in newDir)
%
%   RELIES ON
%   AddNonlin.m
%   
%   EXAMPLES
%   AddNonlins('folder_of_images','folder_to_save','sqrt') --> generates square root transformed images
%   AddNonlins('folder_of_images','folder_to_save','gamma') --> generates gamma transformed images with default gamma = 2.2
%   AddNonlins('folder_of_images','folder_to_save','power',0.8) --> generates power transformed images with exponent = 0.8
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 14 Feb 2025

%% check args & set defaults
if nargin<1
    origDir = uigetdir(cd,'Select directory of original images');
end
if exist(origDir,'dir')==0
    error([origDir ' is not a folder'])
end

if nargin<2
    newDir = uigetdir(origDir,'Select directory to save transformed images');
end
if exist(newDir,'dir')==0
    mkdir(newDir)
end

if nargin<3
    type = 'sqrt';
end
type = lower(type);
if ismember(type,{'sqrt','power','gamma'})==0
    error('unknown transformation type')
end

if nargin<4
    if ismember(type,{'sqrt','power'})
        param = 0.5; %square root transformation
    elseif strcmp(type,'gamma')
        param = 2.2; %default gamma
    end
end

if nargin<5
    overwrite=0;
end

imExt = '.tiff';

%% get images
ims = dir(fullfile(origDir,['*' imExt]));
ims = ims(~startsWith({ims.name},'.')); %exclude hidden mac files

if isempty(ims)
    error(['No ' imExt ' images in ' origDir])
end

%% transform & save
for i = 1:length(ims)
    if overwrite || exist(fullfile(newDir,ims(i).name),'file')==0
        im = im2double(imread(fullfile(origDir,ims(i).name)));
        imTrans = AddNonlin(im,type,param);
        imwrite(imTrans,fullfile(newDir,ims(i).name))
    end
end

%% changelog
% 12 Nov 2025
% updated to save images with no compression

% 14 Feb 2025
% updated to exclude .tiff files that start with . (so are actually hidden
% mac files, not tiffs SIGH)