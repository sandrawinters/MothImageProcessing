function [] = MaskImages(imDir,maskDir,newDir,bgCol,outSize,overwrite)
%Segments image based on ROI and replaces background 
%   Generates images in which the image regions denoted by ROIs (1s in
%   binary image masks) are retained and the background is replaced based 
%   on bgCol (could be either a color or an image). Each image in imDir
%   should have a corresponding binary image mask in maskDir (either a 
%   a mask file with the same extension as the image, or a .mat file that 
%   contains a structure with a .mask field). Masked images are saved in 
%   newDir using original filenames. Skips images that already exist in 
%   newDir unless overwrite==1. 
%
%   INPUT
%   imDir (string): directory of images to mask (asks if not provided)
%   maskDir (string): directory of binary image masks denoting ROI(s) (asks if not provided)
%       files should begin with image filename (i.e. match <image_filename>*)
%       can contain either: 
%           image files (with the same extension as the image, i.e. match <image_filename>*<image_extension>)
%           .mat files that contain a (single) structure with a .mask field that contains the mask image (i.e. match <image_filename>*.mat)
%   newDir (string): directory to save masked images (asks if not provided)
%   bgCol (string): background color (or image if #3); default = 0 (black); options: 
%       (1) single value for greyscale reflectance (e.g. 0.2 for 20% reflectance grey)
%       (2) color triplet (e.g. [1 0 0] for red)
%       (3) matrix denoting color for each pixel; must be same size as image
%       note: values over 1 are assumed to be uintX and are converted to 0-1 range using uint2double.m
%   outSize (double or string): size of output images; default = 'same'; options: 
%       (1) 'same': output image is the same size as input
%       (2) 'tight': output image is cropped to the smallest rectangle around the ROI
%       (3) numeric: output image is of the specified size, with the ROI in the center
%   overwrite (boolean): overwrite images that already exist in newDir? (default = 0)
%
%   OUTPUT
%   n/a
%
%   CREATES
%   masked images saved to newDir using original filenames
%
%   RELIES ON
%   uint2double.m
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 14 Feb 2025

%% check args & set defaults
if nargin<1
    imDir = uigetdir(cd,'Select folder of images');
end
if isfolder(imDir)==0
    error('Image directory does not exist')
end

if nargin<2
    maskDir = uigetdir(imDir,'Select folder of image masks');
end
if isfolder(maskDir)==0
    error('Mask directory does not exist')
end

if nargin<3
    newDir = uigetdir(imDir,'Select new image folder');
end
if isfolder(newDir)==0
    mkdir(newDir)
end

if nargin<4
    bgCol = 0;
end
if any(bgCol>1)
    bgCol = uint2double(bgCol);
end

if nargin<5
    outSize = 'same';
end
%TODO check contents

if nargin<6
    overwrite = 0;
end

imExt = '.tiff';

if isempty(dir(fullfile(maskDir,'*.mat')))==0
    maskExt = '.mat';
else
    maskExt = imExt;
end
if isempty(dir(fullfile(maskDir,['*' maskExt])))
    error(['no ' maskExt ' files found in ' maskDir])
end

%% get images
ims = dir(fullfile(imDir,['*' imExt]));
ims = ims(~startsWith({ims.name},'.')); %exclude hidden mac files

%% mask images & save
for i = 1:length(ims)
    %check for previous results
    if overwrite || exist(fullfile(newDir,ims(i).name),'file')==0
        %get mask file
        maskFile = dir(fullfile(maskDir,[strrep(ims(i).name,imExt,'') '*' maskExt]));
        if length(maskFile)~=1
            disp(['mask file mismatch: ' ims(i).name])
        else
            %get image
            im = im2double(imread(fullfile(imDir,ims(i).name)));
            
            %get mask
            if strcmp(maskExt,'.mat')
                results = load(fullfile(maskDir,maskFile(1).name));
                tmp = fieldnames(results);
                results = results.(tmp{1}); %TODO make work when .mat file contains more than one structure

                mask = results.mask;
            else
                mask = imread(fullfile(maskDir,maskFile(1).name));
            end
            
            mask = double(mask);

            if size(mask,3)~=size(im,3)
                mask = repmat(mask,1,1,size(im,3));
            end

            %mask image
            if isequal(size(im),size(mask))
                %resize
                if ~strcmp(outSize,'same')
                    [r,c] = find(mask(:,:,1));
%                     r_range = [min(r) max(r)];
%                     c_range = [min(c) max(c)];
                    
                    im = im(min(r):max(r),min(c):max(c),:);
                    mask = mask(min(r):max(r),min(c):max(c));
                    
                    if ~strcmp(outSize,'tight') %assume numeric... TODO update to check
                        if size(im,1)<outSize(1)
                            pad = outSize(1) - size(im,1);
                            
                            im = padarray(im,floor(pad/2),0,'pre');
                            im = padarray(im,ceil(pad/2),0,'post');
                            
                            mask = padarray(mask,floor(pad/2),0,'pre');
                            mask = padarray(mask,ceil(pad/2),0,'post');
                        end
                        if size(im,2)<outSize(2)
                            pad = outSize(2) - size(im,2);
                            
                            im = imrotate(im,90);
                            im = padarray(im,floor(pad/2),0,'pre');
                            im = padarray(im,ceil(pad/2),0,'post');
                            im = imrotate(im,-90);
                            
                            mask = imrotate(mask,90);
                            mask = padarray(mask,floor(pad/2),0,'pre');
                            mask = padarray(mask,ceil(pad/2),0,'post');
                            mask = imrotate(mask,-90);
                        end
                        if size(im,1)>outSize(1) || size(im,2)>outSize(2)
                            disp(['warning: ' ims(i).name ' above target size'])
                        end
                    end
                end
                
                %set background color
                if isequal(size(bgCol),size(im))
                    bgMat = bgCol;
                elseif isequal(size(bgCol),[1 1])
                    bgMat = repmat(bgCol,size(im));
                elseif isequal(size(bgCol),[1 3]) && size(im,3)==3
                    bgMat = cat(3,repmat(bgCol(1),size(im,1),size(im,2)), ... 
                                  repmat(bgCol(2),size(im,1),size(im,2)), ... 
                                  repmat(bgCol(3),size(im,1),size(im,2)));
                else
                    error('background color must be a single greyscale value, a color triplet, or a matrix the same size as the image')
                end
                
                %generate mask
                imMasked = im.*mask;
                imMasked(~mask) = bgMat(~mask);
                
                %save image
                imwrite(imMasked,fullfile(newDir,ims(i).name))
            else
                disp(['mask file is not the same size: ' ims(i).name])
            end
        end
    end
end

end

%% changelog
% 14 Feb 2025
% updated to exclude .tiff files that start with . (so are actually hidden
% mac files, not tiffs SIGH)
% updated to use fullfile instead of manually determining folder delimiter