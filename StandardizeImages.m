function [] = StandardizeImages(imDir,resDir,newImDir,type,stdReflectance,imResMatch,overwrite)
%Standardized a folder of images based on color standard measurements
%   Standardizes all images in a folder by rescaling each color channel
%   based on [actual standard reflectance] / [measured standard
%   reflectance] when n standards = 1, or a 2nd degree polynomial fit when
%   n standards > 1. Works when the standard is in the same image (i.e.
%   'adjacent method'; set imResMatch to 'adjacent') or in a different
%   image (i.e. 'sequential method'; imResMatch should specify image
%   matches). Works for X-Rite (Macbeth) Passport standards (set type to
%   'macbeth'), Avian Tech 4x2 grid (MNA-FSS08-C) standard (type = 
%   'aviantech'), 'Jolyon' standards with 93% and 7% reflectance patches 
%   (type = 'jolyon'), or custom standards. Actual reflectance of standard 
%   is specified as either the patch name (a string containing the patch 
%   name  for X-rite standards, see  GetMacbethColor.m; numbers 1:8 for 
%   white to  black patches for Avian Tech standards; numbers 1:2 for light 
%   and dark patches for Jolyon standards), or provided directly (0-1 
%   scale). Skips images that have already been processed (those that 
%   already exist in newImDir) unless overwrite is set to true. Displays 
%   warning if Rsq of transformation <0.998 or proportion of 
%   saturated/negative pixels >0.01. Standardized images saved as doubles. 
%   Also saves files with standardization data (Rsq, saturated/negative 
%   pixels) in newImDir/standardization_data.
%
%   NOTE X-rite patch order in scripts changed Sept 2020; function includes
%   a check & prints warning if results don't include
%   macbeth.order = 'brown>cyan>white>black'
%
%   INPUT
%   imDir (string): directory of .tiff images to convert
%   resDir (string): directory of .mat result files (e.g. from MeasureMacbeths.m, MeasureStandardBalls.m, ...)
%       files should be named <image_filename>*.mat
%       files should contain a structure with field 'meanRGB' (currently only works when each file contains exactly one structure)
%       meanRGB should be n patches x 3 (order r,g,b)
%           for macbeth standards n patches = 24 (ordered as in GetMacbethColor.m: brown --> cyan --> white --> black)
%           for macbeth_grey standards n patches = 6 (ordered white --> black)
%           for all others n patches = 1 (will use first row)
%   newImDir (string): directory where standardized .tiff images will be saved
%   type (string): type of standard; options: 'macbeth', 'macbeth_grey','patch' (default = 'macbeth')
%       'macbeth' and 'macbeth_grey' have special options for extracting the relevant patches (see below)
%       'aviantech' uses the 8 reflectance values for the Avian Technologies MNA-FSS08-C standard (see below)
%       'jolyon' uses 93% and 7% reflectance, like the standards Jolyon Troscianko makes
%       'standard' (or any other string...) simply uses the measurements & actual reflectance value provided
%   stdReflectance (numberic or string): actual reflectance value of standard
%       macbeth standards: name (string) of patch(s) to use (default 'greyscale')
%           options: white (91%), grey1 (59%), grey2 (36%), grey3 (19%), grey4 (9%), black (3%)
%               'greyscale' - all of the above
%           reflectance from macbeth standards based on measurements provided in MICA toolbox
%       aviantech standards: patch numbers to use (default 1:8, i.e. all patches)
%           patches are numbered in order from highest to lowest reflectance (1 = white ... 8 = black)
%           reflectance (patches 1:8) = 99%, 80%, 60%, 40%, 20%, 10%, 5%, 2% (https://aviantechnologies.com/product/reflectance-mini-array-micro-array-standards)
%       jolyon standards: patch numbers to use (default 1:2, i.e. both patches)
%           patch order: 93%, 7% 
%       all other standards should be numeric value(s) between 0 and 1
%           multiple standard patches should be in separate columns (e.g. standard with 20% & 90% patches: [0.2; 0.9])
%           can be either single (row) values for all color channels (e.g. [0.2; 0.9] for two lambertian patches), or RGB triplets (e.g. [0.19 0.2 0.21; 0.85 0.9 0.95])
%   imResMatch (string/cell array): 'adjacent' OR file match for image pairs (default: 'adjacent')
%       for sequential method, imMatch is a cell of strings:
%           1st column - target image name
%           2nd column - standard image name
%   overwrite (boolean): overwrite existing images? (0 = no, skip images that already exist; 1 = yes, re-process all images & overwrite; default = 0;
%
%   OUTPUT
%   n/a
%
%   CREATES
%   standardized images saved to newImDir
%   .mat file with relevant metrics saved for each image in newImDir/standardization_data
%
%   RELIES ON
%   uint2double.m
%   GetMacbethColor.m (if type == macbeth or macbeth_grey)
%   StandardizeImage.m
%
%   Sandra Winters <sandra.winters@colorado.edu>
%   updated 16 May 2025

%% check args & set defaults
if nargin<1
    imDir = uigetdir(cd,'Select folder of images to standardize');
end
if exist(imDir,'dir')==0
    error('Image directory does not exist')
end

if nargin<2
    resDir = uigetdir(cd,'Select folder of standard measurements');
end
if exist(resDir,'dir')==0
    error('Folder of standard measurements does not exist')
end

if nargin<3
    newImDir = uigetdir(cd,'Select location to save standardized images');
end
if exist(newImDir,'dir')==0
    mkdir(newImDir)
end

if nargin<4
    type = 'macbeth';
    disp('Setting standard type to ''macbeth''')
end
type = lower(type);

if nargin<5
    if ismember(type,{'macbeth','macbeth_grey'})
        stdReflectance = 'greyscale';
        disp('Setting standard patch to ''greyscale''')
    elseif strcmp(type,'aviantech')
        stdReflectance = 1:8; %used here as the patch numbers (white-black) of the standard to use (1:8 will use all of them)
    elseif strcmp(type,'jolyon')
        stdReflectance = 1:2; %light and dark patches
    else
        stdReflectance = 0.2;
        disp('Setting standard reflectance to 0.2')
    end
end

if nargin<6
    imResMatch = 'adjacent';
end

if nargin<7
    overwrite = 0;
end

imExt = '.tiff';

if exist(fullfile(newImDir,'standardization_data'),'dir')==0
    mkdir(fullfile(newImDir,'standardization_data'))
end

%% get standard reflectance value
if ismember(type,{'macbeth','macbeth_grey'}) %for macbeth standards, reflectance is based on patch name
%     if strcmp(stdReflectance,'all')
%         error('Choose a single Macbeth color patch')
%     else
        [stdReflectance,resultsRow] = GetMacbethColor('mean_spec',stdReflectance); %from Jolyon's spec measurements in MICA toolbox
        stdReflectance = repmat(stdReflectance,[1 3]);
%     end

    if strcmp(type,'macbeth_grey')
        resultsRow = resultsRow-18; %since only grey row will be included in results
        if resultsRow<1
            error('Type ''macbeth_grey'' only works with greyscale patch measurements')
        end
    end
elseif strcmp(type,'aviantech')
    resultsRow = stdReflectance; %specifies the patch numbers to use (white = 1 ... black = 8)

    stdReflectance = [0.99; 0.8; 0.6; 0.4; 0.2; 0.1; 0.05; 0.02]; %https://aviantechnologies.com/product/reflectance-mini-array-micro-array-standards/
    stdReflectance = repmat(stdReflectance,[1 3]);
    stdReflectance = stdReflectance(resultsRow,:); %use only specified patches
elseif strcmp(type,'jolyon') 
    resultsRow = stdReflectance; %specifies the patch numbers to use (93% = 1 ... 7% = 2)

    stdReflectance = [0.93; 0.07]; 
    stdReflectance = repmat(stdReflectance,[1 3]);
    stdReflectance = stdReflectance(resultsRow,:); %use only specified patches
else %for others, reflectance (0-1) should be provided directly
    if isnumeric(stdReflectance)==0
        error('Standard reflectance is not a number')
    end
    if size(stdReflectance,2)==1
        stdReflectance = repmat(stdReflectance,[1 3]);
    end
    if size(stdReflectance,2)~=3
        error('Incorrect standard reflectance format. Each patch should be in a different column (e.g. [0.2; 0.5].')
    end
    if sum(stdReflectance>1,'all') || sum(stdReflectance<0,'all')
        error('Incorrect standard reflectance. Should be value(s) between 0 and 1.')
    end
    resultsRow = 1:size(stdReflectance,1); %assume the specified patches are the only measurements
end

%% get images
ims = dir(fullfile(imDir,['*' imExt]));
ims = {ims.name}';
ims = ims(~startsWith(ims,'.')); %exclude hidden mac files

%% set up/check image-results matches
if ischar(imResMatch) && strcmp(imResMatch,'adjacent')
    imResMatch = [ims,ims];
else
    % TODO check matches
end

%% standardize images
for i = 1:length(ims)
    if overwrite || exist(fullfile(newImDir,ims{i}),'file')==0
        %import image
        im = imread(fullfile(imDir,ims{i}));

        %get matching standard results file
        stdImMatch = char(imResMatch(strcmp(imResMatch(:,1),ims{i}),2)); %get matching image in imResMatch
        if isempty(stdImMatch)
            disp([ims{i} ' not standardized: no standard match'])
        else
            resFile = dir(fullfile(resDir,strrep(stdImMatch,imExt,'*.mat')));
    
            %standardize image
            if isempty(resFile)==0
                stdDat = load(fullfile(resDir,resFile.name));
                stdDat = stdDat.(string(fieldnames(stdDat))); %TODO make this work when there's more than one field in .mat file
    
                if strcmp(type,'macbeth') && ...
                       ( isfield(stdDat,'order')==0 || ...
                           strcmp(stdDat.order,'brown>cyan>white>black')==0 )
                    disp('WARNING: CHECK PATCH ORDER IN MACBETH RESULTS')
                end
    
                if isfield(stdDat,'flag') && stdDat.flag==1
                    disp([ims{i} ' not standardized: standard flagged'])
                else
                    stdMapData.image = ims{i};
                    [imStd,stdMapData.rsq,stdMapData.satPx,stdMapData.negPx] = StandardizeImage(im,stdDat.meanRGB(resultsRow,:),stdReflectance,0);
    
                    if stdMapData.rsq<0.99
                        disp(['WARNING: ' ims{i} ' Rsq = ' num2str(stdMapData.rsq)])
                    end
    
                    stdMapData.propSatPx = size(stdMapData.satPx,1)/(size(im,1)*size(im,2));
                    if stdMapData.propSatPx>0.01
                        disp(['WARNING: ' ims{i} ' prop saturated pixels = ' num2str(stdMapData.propSatPx)])
                    end
    
                    stdMapData.propNegPx = size(stdMapData.negPx,1)/(size(im,1)*size(im,2));
                    if stdMapData.propNegPx>0.01
                        disp(['WARNING: ' ims{i} ' prop negative pixels = ' num2str(stdMapData.propNegPx)])
                    end
    
                    imwrite(imStd,fullfile(newImDir,ims{i}))
                    save(fullfile(newImDir,'standardization_data',strrep(ims{i},imExt,'.mat')),'stdMapData')
                end
            else
                disp([ims{i} ' not standardized: no standard data' ])
            end
        end
    end
end

%% changelog
% 16 May 2025
% changed warnings to print if prop saturated/negative pixels is >0,01
% (from 0,001) to avoid excessive warnings

% 14 Feb 2025
% updated to exclude .tiff files that start with . (so are actually hidden
% mac files, not tiffs SIGH)

% 6 Feb 2023
% changed resFile to match any output (changed "_standardResults.mat" to "*.mat')

% 13 Oct 2022
% added jolyon standard option
