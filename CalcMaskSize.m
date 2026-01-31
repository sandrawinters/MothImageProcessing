function [maskSizes] = CalcMaskSize(maskDir,resDir)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% check args & set defaults
if nargin<1
    maskDir = uigetdir('','Select folder of masks'); 
end
if isfolder(maskDir)==0
    error('Mask directory does not exist')
end

if nargin<2
    resDir = uigetdir('','Select folder for results');
end
if isfolder(resDir)==0
    mkdir(resDir)
end    

maskExt = '.tiff';

%% get mask list
masks = dir(fullfile(maskDir,['*' maskExt]));

%% calculate mask sizes
for i = 1:length(masks)
    %get mask
    maskData.image = masks(i).name;
    maskData.mask = imread(fullfile(maskDir,masks(i).name));

    %calculate size (in pixels)
    maskData.nPx = sum(double(maskData.mask(:)));

    %save
    save(fullfile(resDir,strrep(masks(i).name,maskExt,'_maskData.mat')), 'maskData');
end

%% export as table
maskSizes = CompileFilesStruct(resDir,'maskData','nPx');

end %function