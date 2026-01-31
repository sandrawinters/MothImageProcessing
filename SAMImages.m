function [] = SAMImages(imDir,saveDir,resize,pointGridSize,objNum,invert)
%Generates binary mask(s) using SAM for a folder of images
%   Detailed explanation goes here
%
%   INPUT
%   imDir (string): directory of images to process (asks if not provided) 
%   saveDir (string): directory to save binary mask(s) of detected object(s) (asks if not provided)
%   resize (double): resize factor, passed to imresize (default = 1, no resizing)
%       process smaller images (resize < 1) to save processing time
%       note: any resizing is not saved (mask is resized to original image size before saving)
%   pointGridSize (1x2 int): grid points sampled for the SAM, see doc imsegsam (default [32 32])
%   objNum (double or string): objects to extract from image, options: 
%       a number will extract that object from the SAM output (e.g. 1 will always take the first object)
%       'largest' will extract the largest (most pixels) object 
%       'all' will extract all objects, and return a mask stack (with each object mask in the 3rd dimension)
%       default = 'largest'
%   invert (logical or string): invert the mask(s)? 
%       'edge' option inverts based on the edge pixels -- if the majority are 1, then the mask is inverted
%       default = 'edge'
%
%   OUTPUT
%   n/a
%
%   CREATES
%   binary mask(s) saved in saveDir using original filenames
%       note: inf objNum = 'all', this will be a mask stack (each mask in 3rd dimension)
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

if nargin<2 || isempty(saveDir)
    saveDir = uigetdir('','Select folder for wing masks'); 
end
if isfolder(saveDir)==0
    mkdir(saveDir)
end

if nargin<3 || isempty(resize)
    resize = 1;
end

if nargin<4 || isempty(pointGridSize)
    pointGridSize = [32 32];
end

if nargin<5 || isempty(objNum)
    objNum = 'largest';
end
if isnumeric(objNum)
    maskNum = objNum;
    objNum = 'fixed';
end

if nargin<6
    invert = 'edge';
end
if invert==1
    invert = 'yes';
end

imExt = '.tiff';

%% get image list
ims = dir(fullfile(imDir,['*' imExt]));
ims = ims(~startsWith({ims.name},'.')); %exclude hidden mac files

%% segment each image
for i = 1:length(ims)
    %skip previously segmented images
    if exist(fullfile(saveDir,ims(i).name),'file')==0
        %get image
        im = imread(fullfile(imDir,ims(i).name)); %note SAM works better with uint8 images
    
        %resize
        imRsz = imresize(im,resize);
        
        %run SAM
        samObjs = imsegsam(imRsz, ... 
                           'PointGridSize',pointGridSize, ... 
                           'Verbose',false); 
        
        %extract object mask & save
        if samObjs.NumObjects>0
            %determine which mask to extract 
            if strcmpi(objNum,'largest')
                objSizes = cellfun(@length,samObjs.PixelIdxList);
                [~,maskNum] = max(objSizes());
            elseif strcmpi(objNum,'all')
                maskNum = 1:samObjs.NumObjects;
            end

            %generate requested mask(s) 
            masks = false(samObjs.ImageSize(1),samObjs.ImageSize(2),length(maskNum));
            for m = 1:length(maskNum)
                %extract mask from SAM output
                mask = false(prod(samObjs.ImageSize),1);
                mask(samObjs.PixelIdxList{m}) = true;
                mask = reshape(mask,samObjs.ImageSize);
                
                %invert as necessary
                if strcmpi(invert,'yes')
                    mask = imcomplement(mask); %invert mask
                elseif strcmpi(invert,'edge')
                    %get most common edge pixel
                    edgePx = [mask(1:end,1); ... 
                              mask(1:end,end); ...
                              mask(1,2:end-1)'; ... 
                              mask(end,2:end-1)'];
                    edgeMode = mode(double(edgePx));
                    
                    %invert if mode is 1 (i.e., object is background)
                    if edgeMode==1
                        mask = imcomplement(mask); %invert mask
                    end
                end
                
                %basic morphology
                mask = bwareafilt(mask,1); %keep largest object
                mask = imfill(mask,'holes'); %fill holes
                
                %undo resize
                mask = imresize(mask,[size(im,1) size(im,2)]);

                %add to mask stack (note: "stack" will only be 1 mask unless maskNum = 'all')
                masks(:,:,m) = mask;
            end
    
            %save
            imwrite(masks,fullfile(saveDir,ims(i).name))
        else
            disp(['WARNING: no objects found in ' ims(i).name ' (no mask generated)'])
        end
    end 
end %image loop

end %function

%% changelog
% 14 Feb 2025
% updated to exclude .tiff files that start with . (so are actually hidden
% mac files, not tiffs SIGH)

% 10 Feb 2025
% added 'largest' and 'all' maskNum options and associated code

% 22 Jan 2025
% added 'edge' option to invert