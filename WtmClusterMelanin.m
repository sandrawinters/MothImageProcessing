function [] = WtmClusterMelanin(imDir,wingMaskDir,melMaskDir,nonMelMaskDir,recolDir,overlayDir,k,erodeR,morphFun,morphStrel,overwrite)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

%% check args & set defaults
if nargin<1 || isempty(imDir)
    imDir = uigetdir('','Select folder of images'); 
end

if nargin<2 || isempty(wingMaskDir)
    wingMaskDir = uigetdir('','Select folder of wing masks'); 
end

if nargin<3 || isempty(melMaskDir)
    melMaskDir = uigetdir('','Select folder of images'); 
end
if isfolder(melMaskDir)==0
    mkdir(melMaskDir)
end

if nargin<4 || isempty(nonMelMaskDir)
    nonMelMaskDir = uigetdir('','Select folder of images'); 
end
if isfolder(nonMelMaskDir)==0
    mkdir(nonMelMaskDir)
end

if nargin<5 || isempty(recolDir)
    recolDir = uigetdir('','Select folder of images'); 
end
if isfolder(recolDir)==0
    mkdir(recolDir)
end

if nargin<6 || isempty(overlayDir)
    overlayDir = uigetdir('','Select folder of images'); 
end
if isfolder(overlayDir)==0
    mkdir(overlayDir)
end

if nargin<7 || isempty(k)
    k = 2;
end

if nargin<8 || isempty(erodeR)
    erodeR = 1;
end

if nargin<9 || isempty(morphFun)
    morphFun = {};
end

if nargin<10 || isempty(morphStrel)
    morphStrel = {};
end

if nargin<11 || isempty(overwrite)
    overwrite = 0;
end

imExt = '.tiff';

%% get image list 
ims = dir(fullfile(imDir,['*' imExt]));
ims = ims(~startsWith({ims.name},'.')); %exclude hidden mac files

%% cluster wing pixels using k-means clustering
for i = 1:length(ims)
    %skip image with existing masks, unless overwrite is true
    if exist(fullfile(melMaskDir,ims(i).name),'file')==0 || overwrite
        %get image
        im = imread(fullfile(imDir,ims(i).name));
        
        %get associated wing mask (skip images where it's missing)
        if exist(fullfile(wingMaskDir,ims(i).name),'file')
            wingMask = imread(fullfile(wingMaskDir,ims(i).name));
        else
            disp(['WARNING: skipping image ' ims(i).name ', no mask file found'])
        end
        
        %erode wing mask (to remove boundary pixels from image)
        if erodeR>0
            wingMask = imerode(wingMask,strel('disk',erodeR)); %using disk-shaped structuring element with radius = 1
        end

        %k-means clustering of wing
        [~,~,~,kMasks] = KMClusterROI(im,wingMask,k,'lab');
        % [~,imRecol,imOverlay,kMasks] = KMClusterROI(im,wingMask,k);
        
        %image morphology to improve segmentation
        melMask = kMasks(:,:,1);
        
        % melMask = imopen(melMask,strel('disk',2));
        % melMask = imclose(melMask,strel('disk',1));
        % figure; imshow(melMask)
        
        if ~isempty(morphFun)
            for m = 1:length(morphFun)
                %create structuring element based on specified params
                s = strel(morphStrel{m,1},morphStrel{m,2});
                melMask = feval(morphFun{m},melMask,s);
            end
        end

        nonmelMask = logical(~melMask .* wingMask);

        %(re-) recolor ROI
        imVec = reshape(im,[],3);
        medianMel = median(imVec(melMask(:),:));
        medianNonmel = median(imVec(nonmelMask(:),:));
        
        imRecol = repmat(uint8(sqrt(0.2)*255),size(im));
        imRecol(repmat(melMask,1,1,3)) = repmat(medianMel,sum(melMask(:)),1);
        imRecol(repmat(nonmelMask,1,1,3)) = repmat(medianNonmel,sum(nonmelMask(:)),1);

        %(re-) generate image overlay
        imEroded = repmat(uint8(sqrt(0.2)*255),size(im));
        imEroded(repmat(wingMask,1,1,3)) = im(repmat(wingMask,1,1,3));

        imClust = zeros(size(melMask));
        imClust(melMask) = 1;
        imClust(nonmelMask) = 2;
        imOverlay = labeloverlay(imEroded,imClust,'Colormap',double([medianMel; medianNonmel])./255);
        
        %save 
        imwrite(melMask,fullfile(melMaskDir,ims(i).name))
        imwrite(nonmelMask,fullfile(nonMelMaskDir,ims(i).name))
        % imwrite(kMasks(:,:,1),fullfile(melMaskDir,ims(i).name))
        % imwrite(kMasks(:,:,2),fullfile(nonMelMaskDir,ims(i).name))
        imwrite(imRecol,fullfile(recolDir,ims(i).name))
        imwrite(imOverlay,fullfile(overlayDir,ims(i).name))
    end
end

end %function
