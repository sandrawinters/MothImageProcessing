function [] = ScaleImages(imDir,scaleDir,newImDir,scaleLength,ppUnit,sizeUp,exclText)
%Scales to a given pixels per unit based on scale bar
%   Scales image by converting to given pixels per unit (whatever
%   measurement unit is provided; should be consistent across arguments)
%   based on desired PPU / ( n pixels in scale bar / scale bar length ).
%   scaleLength can be specified as an argument, or set to 'NA' to use the
%   realLength field saved in the scale bar results file (default = 'NA'). 
%   Does not change images below the target resolution unless sizeUp is
%   true. Excludes text in exclText from image filename when matching with 
%   scale bar file.
%
%   INPUT
%   imDir (string): directory of images to convert (asks if not provided)
%   scaleDir (string): directory of .mat data files (e.g. from MarkScales.m, MarkBalls.m, ...) (asks if not provided)
%       files should be named <image_filename>*.mat
%       files should contain a structure with field 'length' (currently only works when each file contains exactly one structure)
%   newImDir (string): directory to save scaled (asks if not provided)
%   scaleLength (double): length of actual scale bar; units should be the same across all variables (e.g. all in mm)
%       when set to 'NA' (defult), will use the realLength field from the structure loaded from scaleDir (see above)
%   ppUnit (double): desired pixels per unit; units should be consistent across variables (asks if not provided)
%   sizeUp (boolean): increase image resolution where necessary? (default = 0)
%   exclText (string or string array): text to eclude from image filename when matching to scale bar file
%       e.g. if exclText = '_cropped', IMG_1234_cropped would match with a scale bar file starting with IMG_1234
%   
%   OUTPUT
%   n/a
%
%   CREATES
%   scaled images in newImDir
%
%   RELIES ON
%   ScaleImage.m
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 21 Jul 2025

%% check args & set defaults
if nargin<1
    imDir = uigetdir(cd,'Select folder of images to standardize');
end
if exist(imDir,'dir')==0
    error('Image directory does not exist')
end

if nargin<2
    scaleDir = uigetdir(cd,'Select folder of scalebar measurements');
end
if exist(scaleDir,'dir')==0
    error('Folder of scalebar measurements does not exist')
end

if nargin<3
    newImDir = uigetdir(cd,'Select location to save scaled images');
end
if exist(newImDir,'dir')==0
    mkdir(newImDir)
end

if nargin<4
    % scaleLength = inputdlg('Enter the real length of the scale bar');
    % scaleLength = str2double(scaleLength{1});
    scaleLength = 'NA';
end

if nargin<5
    ppUnit = inputdlg('Enter the resolution to use for scaled images (pixels per scale bar unit)');
    ppUnit = str2double(ppUnit{1});
end

if nargin<6 || isempty(sizeUp)
    sizeUp = 0;
end

if nargin<7
    exclText = '';
end

imExt = '.tiff';

%% get list of images and scalebar files
ims = dir(fullfile(imDir,['*' imExt]));
ims = ims(~startsWith({ims.name},'.')); %exclude hidden mac files

scalebarFiles = dir(fullfile(scaleDir,'*.mat'));
scalebarFiles = {scalebarFiles.name}';
scalebarFiles = scalebarFiles(~startsWith(scalebarFiles,'.')); %exclude hidden mac files

%% rescale images to ppUnit (pixels per whatever unit is used in variables)
for i = 1:length(ims)
    if exist(fullfile(newImDir,ims(i).name),'file')==0
        %get matching scalebar file
        imName = strrep(ims(i).name,imExt,'');
        if ~isempty(exclText)
            for e = 1:length(exclText)
                imName = strrep(imName,exclText{e},'');
            end
        end

        scalebarFile = startsWith(scalebarFiles,imName);
        
        %scale image
        if sum(scalebarFile)>0
            %load scalebar file
            scalebarFile = scalebarFiles{scalebarFile};
            scalebar = load(fullfile(scaleDir,scalebarFile)); %TODO check for multiple matches
            scalebar = scalebar.(string(fieldnames(scalebar))); %TODO make this work when there's more than one variable in the .mat file

            %load image
            im = imread(fullfile(imDir,ims(i).name));

            %scale image
            if strcmpi(scaleLength,'NA') %use stored real scale length
                scaledIm = ScaleImage(im,scalebar.length,scalebar.realLength,ppUnit,sizeUp);
            else
                scaledIm = ScaleImage(im,scalebar.length,scaleLength,ppUnit,sizeUp);
            end
            % imPpUnit = scalebar.length/scaleLength;
            % if sizeUp || imPpUnit>ppUnit
            %     scaledIm = imresize(im,ppUnit/imPpUnit); 
            % else
            %     scaledIm = im;
            % end
            % if imPpUnit<ppUnit
            %     disp(['WARNING ' ims(i).name ' below target resolution'])
            % end

            %save scaled image
            imwrite(scaledIm,fullfile(newImDir,ims(i).name))
        else
            %report missing image
            disp([ims(i).name ' not processed: scalebar data missing'])
        end
    end
end

%% changelog
% 21 Jul 2025
% updated to use stored real scale bar length (from scalebar structure)
% when scaleLength = NA; set default scaleLength = NA; should be backwards
% compatible because previous default was inputdlg

% 14 Feb 2025
% updated to exclude .tiff files that start with . (so are actually hidden
% mac files, not tiffs SIGH)

% 5 Feb 2025
% minor bug fix to prevent errors when scalebar file not found

% 21 Jan 2025
% added exclText param and associated code
