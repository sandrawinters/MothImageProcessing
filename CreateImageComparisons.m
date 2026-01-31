function [] = CreateImageComparisons(imDirs,saveDir,dim)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% check args & set defaults
if nargin<1 || isempty(imDirs)
    error('no image directory list provided'); 
end

if nargin<2 || isempty(saveDir)
    saveDir = uigetdir('','Select folder for image comparisons'); 
end
if isfolder(saveDir)==0
    mkdir(saveDir)
end

if nargin<3 || isempty(dim)
    dim = 2; %horizontal concatenation
end

imExt = '.tiff';

%% get image list
ims = dir(fullfile(imDirs{1},['*' imExt]));

%% generate images
for i = 1:length(ims)
    %get first image
    imComp = im2double(imread(fullfile(imDirs{1},ims(i).name)));
    
    %add each additional image horizontally
    for d = 2:length(imDirs)
        if exist(fullfile(imDirs{d},ims(i).name),'file')
            newIm = im2double(imread(fullfile(imDirs{d},ims(i).name)));
            
            if size(newIm,3)==1 %duplicate masks on dimension 3
                newIm = repmat(newIm,1,1,3);
            end
    
            imComp = cat(dim,imComp,newIm);
        else
            disp(['WARNING: ' fullfile(imDirs{d},ims(i).name) ' not found (excluded from composite image)'])
        end
    end

    %save
    imwrite(imComp,fullfile(saveDir,ims(i).name))
end

end %function