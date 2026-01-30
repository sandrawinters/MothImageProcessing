function [] = CopyEveryXImages(imDir,newDir,setSz,x,imExt)
%Copies every x out of y images to a new folder
%   For the images in imDir, copies every x / setSz images (i.e., if there
%   are 20 images in imDir, setSz = 5, and x = 2, it will copy images 2, 6, 
%   11, 16 to newDir). 
%
%   INPUT
%   imDir (string): folder of images to copy from (asks if not provided)
%   newDir (string): folder to copy images to (asks if not provided)
%   setSz (int): image set size, i.e. number of images within each repeat (asks if not provided)
%   x (int): image within set to copy, i.e. copy every X image from within every setSz images (asks if not provided)
%   imExt (string): image extension, default = '.tiff'
%
%   OUTPUT
%   n/a
%
%   CREATES
%   copies specified images from imDir to newDir
%
%   RELIES ON
%   n/a
%
%   Sandra Winters <sanrda.winters@colorado.edu>
%   updated 14 Feb 2025

%% check args & set defaults
if nargin<1 || isempty(imDir)
    imDir = uigetdir('','Select folder of images'); 
end

if nargin<2 || isempty(newDir)
    newDir = uigetdir('','Select folder to save copies'); 
end
if isfolder(newDir)==0
    mkdir(newDir)
end

if nargin<3 || isempty(setSz)
    setSz = inputdlg('Enter size of image set (number of images within each repeat)');
    setSz = str2double(setSz{1});
end

if nargin<4 || isempty(x)
    x = inputdlg(['Copy every X/' num2str(setSz) ' images']);
    x = str2double(x{1});
end

if nargin<5
    imExt = '.tiff';
end

%% get image list
ims = dir(fullfile(imDir,['*' imExt]));
ims = {ims.name}';
ims = ims(~startsWith(ims,'.')); %exclude hidden mac files

%% copy requested images
imsToCopy = ims(x:setSz:length(ims)); 
for i = 1:length(imsToCopy)
    copyfile(fullfile(imDir,imsToCopy{i}), fullfile(newDir,imsToCopy{i}));
end

end %function

%% changelog 
% 14 Feb 2025
% updated to exclude .tiff files that start with . (so are actually hidden
% mac files, not tiffs SIGH)