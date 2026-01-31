function [] = RawToTiff(origDir,converter,params,deleteRAW,overwrite,newDir)
%Converts all RAW images in a folder to linear 16-bit TIFFs
%   Converts all CR2, CR3,  NEF, SRW, ARW, or DNG images in a folder to 
%   linear 16-bit TIFFs. When converter = 'libraw' (defulat), uses LibRaw 
%   (https://www.libraw.org), implemented using the python wrapper rawpy 
%   (https://pypi.org/project/rawpy/); when converter = 'dcraw', uses 
%   DCraw (https://www.dechifro.org/dcraw). The converter specified must 
%   be accessible from matlab (see relies on below). DCraw does not 
%   currently work for CR3 images (generates black images). Outputs 
%   half-sized images by default (which are still huge). Change params to 
%   specify different conversion parameters (defaults generate linear 
%   16-bit half-size tiffs). Skips files that already exist, unless 
%   overwrite = true.  Spaces in filenames are replaced with _. 
%
%   INPUT
%   origDir (string): path of directory containing CR2, NEF, SRW, ARW, or DNG files; asks if not included
%       path should not include spaces; paths with spaces will be renamed using _
%   converter (string): method to use to convert images; default = 'libraw'
%       options: 'libraw', 'dcraw' (not case sensitive)
%       see system requirements below
%   params: parameters to send to the converter; defaults generate linear 16-bit half-size tiffs
%       libraw default: 'gamma=(1,1), no_auto_bright=True, output_bps=16, output_color=rawpy.ColorSpace.raw, half_size=True'
%           see https://letmaik.github.io/rawpy/api/rawpy.Params.html#rawpy.Params
%       dcraw default: '-4 -T -o 0 -h'
%           see https://www.dechifro.org/dcraw/dcraw.1.html
%   deleteRAW (boolean): delete RAW files after conversion? (0 = no, 1 = yes); default = 0
%   overwrite (boolean): overwrite existing tiff files? (0 = no, 1 = yes); default = 0
%
%   OUTPUT
%   n/a
%
%   CREATES
%   tiff images generated from each RAW file in origDir, saved in newDir
%
%   RELIES ON
%   when converter = 'libraw'
%       python installed on the system and accessible through matlab
%           python: https://www.python.org
%           configure matlab to use python: https://www.mathworks.com/help/matlab/call-python-libraries.html
%       rawpy and imageio python libraries installed
%           rawpy: https://pypi.org/project/rawpy/
%           imageio: https://pypi.org/project/imageio/
%   when converter = 'dcraw'
%       access to dcraw via system command
%       can be installed on system (linux) or available as dcraw.exe in current directory (windows)
%       DCraw can be downloaded here (change name to dcraw.exe): https://dcraw.en.softonic.com/?ex=RAMP-2081.2
%   
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 14 Feb 2025

%% check args & set defaults
if nargin<1 || isempty(origDir)
    origDir = uigetdir('','Select folder of RAW images to convert'); 
end
if isfolder(origDir)==0
    error([origDir ' is not a directory'])
end

if nargin<2
    converter = 'LibRaw';
end

if nargin<3 || isempty(params)
    if strcmpi(converter,'dcraw')
        params = '-4 -T -o 0 -h'; %DCraw params
    elseif strcmpi(converter,'libraw')
        params = 'gamma=(1,1), no_auto_bright=True, output_bps=16, output_color=rawpy.ColorSpace.raw, half_size=True'; %linraw (via rawpy) params
    else
        error('unknown converter')
    end
end

if nargin<4 || isempty(deleteRAW)
    deleteRAW = 0;
end

if nargin<5 || ispempty(overwrite)
    overwrite = 0;
end

if nargin<6 || isempty(newDir)
    newDir = origDir;
end
if isfolder(newDir)==0
    mkdir(newDir)
end

%% set up files
%check for spaces in folder name & correct if necessary
if length(strsplit(origDir,' '))>1
    movefile(origDir,strrep(origDir,' ','_'))
end

%get images in folder
canonIms = dir(fullfile(origDir,'*.CR2'));
canonIms2 = dir(fullfile(origDir,'*.CR3'));
nikonIms = dir(fullfile(origDir,'*.NEF'));
samsungIms = dir(fullfile(origDir,'*.SRW'));
sonyIms = dir(fullfile(origDir,'*.ARW'));
dngIms = dir(fullfile(origDir,'*.DNG'));

ims = [canonIms; canonIms2; nikonIms; samsungIms; sonyIms; dngIms];
rawIms = {ims.name}';
rawIms = rawIms(~cellfun(@(x) startsWith(x,'.'),rawIms)); %exclude hidden mac files

%check for spaces in image names & correct if necessary
for cnt = 1:length(rawIms)
    if length(strsplit(fullfile(origDir,rawIms{cnt})))>1
        newName = strrep(fullfile(origDir,rawIms{cnt}),' ','_');
        disp(['warning: changing filename ' rawIms{cnt} ' to ' newName])
        movefile(fullfile(origDir,rawIms{cnt}), ... 
                 newName)
        rawIms{cnt} = newName;
    end 
end

%% convert images
disp(['Converting ' num2str(length(rawIms)) ' images'])

first = 1;
for cnt = 1:length(rawIms)
%     disp(rawIms(cnt)) %display progress
    
    try
        %filenames
        rawFile = fullfile(origDir,rawIms{cnt});
        tiffFile = fullfile(newDir,regexprep(rawIms{cnt},'CR2|CR3|NEF|SRW|ARW|DNG','tiff'));

        if overwrite || ~exist(tiffFile,'file')
            if first==1
                tic;
            end
            
            if strcmpi(converter,'dcraw')
                % %call dcraw conversion function -- UPDATED TO LIBRAW VIA PYTHON (BELOW)
                if ispc==1
                    dcraw_call = ['dcraw.exe ', params, ([' "',fullfile(origDir,rawIms{cnt}),'"'])];
                elseif isunix==1
                    dcraw_call = ['dcraw ' params ' ' fullfile(origDir,rawIms{cnt})];
                elseif ismac==1
                    %TODO
                    error('this function is not yet implemented for mac computers')
                else
                    error('Error from RawToTiff: Operating system unknown')
                end
                system(dcraw_call);
            else
                %run LibRaw via rawpy in python to generate linear 16 bit tiff
                fid = fopen('tmp.py','w'); %generate temp python script implementing conversion in rawpy
                fprintf(fid,'%s',['import rawpy' newline]);
                fprintf(fid,'%s',['import imageio' newline newline]);
                fprintf(fid,'%s',["path = '" rawFile "'" newline]);
                fprintf(fid,'%s',['with rawpy.imread(path) as raw:' newline]);
                fprintf(fid,'%s',['    rgb = raw.postprocess(' params ')' newline]);
                fprintf(fid,'%s',["imageio.imsave('" tiffFile "', rgb)" newline]);
                fclose(fid);
        
                pyrunfile('tmp.py') %run python script 
    
                %TODO update to something better than this quick hack ^
            end
    
            if first==1
                time = toc;
                currTime = datetime('now');
                disp(['Approx time: ' num2str(ceil(length(rawIms)*time/60)) ' minute(s) (Current time: ' num2str(hour(currTime)) ':' num2str(minute(currTime),'%02.f') ')'])
                first = 0;
            end
        end %if exist

        if deleteRAW
            delete(fullfile(origDir,rawIms{cnt}));
        end

    catch ME
        disp(['WARNING: processing error for image ' rawIms{cnt} ': ' ME.identifier])
    end
    
    % if ~strcmp(newDir,origDir) 
    %     filename = regexprep(rawIms{cnt},'CR2|CR3|NEF|SRW|ARW','tiff');
    %     movefile(fullfile(origDir,filename),fullfile(newDir,filename))
    % end
end %for each image

%% CHANGELOG
% 7 Jul 2025
% added try/catch to skip images with processing errors
% moved filenames out of if exist statement (so only generate tiff name once)
% fixed error in time calculation (doesn't impact performance)

% 14 Feb 2025
% updated to exclude image files that start with . (so are actually hidden
% mac files, SIGH)

% 20 Sept 2024
% added DNG image extension

% 27 Aug 2024
% updated documentation to reflect recent changes, no code changes 

% 04 Apr 2024
% MAJOR UPDATES
% updated to use LibRaw via rawpy python wrapper instead of DCraw through system call (dcraw no longer updated)
% new code creates a temp python script to convert each image, and saves directly to newDir (instead of moving post-conversion)
% changed dcrawparams arg to params, updated default to use rawpy format 
% old dcraw params & conversion left as commented legacy code for future reference
% added CR3 functionality (not implemented in with dcraw)
% should all be backward-compatible, unless DCraw params were specified as argument

% 03 Apr 2024
% updated to use fullfile, minor code clean-up (no change of function)
% added isempty options for params
% updated dcraw.exe file (see dcraw_notes.txt)

% 27 Oct 2023
% added newDir param

% 1 June 2023
% added overwrite param

% 10 Oct 2022
% updated to work for samsung .SRW files

