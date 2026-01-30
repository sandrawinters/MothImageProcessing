function [] = Folders2Filenames(baseDir,newDir,ext,delim,replace)
%Copies and renames files based on folder structure
%   Copies all files (recursively) with extension ext (can be a list) in
%   baseDir to newDir, renaming files based on their folder structure, with
%   original folders/filenames separated based on delim (default delim =
%   '_'). E.g., base_folder/fold1/file1.mat --> new_folder/fold1_file1.mat.
%   Skips files that already exist in newDir.
%
%   NOTE: directory strings must include correct folder delimiter for the
%   OS (i.e. linux = /, windows = \) or they will not be replaced properly.
%   *TODO* check & replace incorrectly specified paths before using default filesep
%
%   INPUT 
%   baseDir (string): base directory that contains folders of files (asks if not provided)
%   newDir (string): directory to save renamed files (asks if not provided)
%   ext (string or string array): file extensions to copy
%       can be a string (e.g. '.mat') or string array (e.g. {'.tiff','.mat'})
%       default = {'.tiff','.mat'}
%   delim (string): delimiter for new filenames, will be used to separate original folders/filenames
%       e.g. if delim = '_' then folder1/file1 --> folder1_file1
%       default = '_'
%   replace (boolean): replace existing files? (default = no; skip existing files)
%
%   OUTPUT 
%   n/a
%
%   CREATES
%   copies of each file in baseDir, renamed in newDir
%
%   RELIES ON
%   rdir.m
% 
%   EXAMPLE
%   Folders2Filenames('base_folder', 'new_folder', '.tiff', '_')
%       copies all .tiff files in folders in base_folder to new_folder, 
%       renamed to folderInBaseFolder_filename.tiff
%
%   Sandra Winters <sandra.winters@colorado.edu>
%   updated 7 July 2025

%% check args & set defaults
if nargin<1 || isempty(baseDir)
    baseDir = uigetdir(cd, 'Select base folder of files for renaming');
end

if nargin<2 || isempty(newDir)
    newDir = uigetdir(cd, 'Select folder for renamed files');
end
if isfolder(newDir)==0
    mkdir(newDir)
end

if nargin<3 || isempty(ext)
    % ext = inputdlg('Enter file extension (e.g., .tiff) ');
    ext = {'.tiff','.mat'};
end
if ischar(ext)
    ext = {ext};
end

if nargin<4 || isempty(delim)
    delim = '_';
end

if nargin<5 || isempty(replace)
    replace = 0;
end

%% copy files, adding previous folder names as filename prefix
for e = 1:length(ext)
    %get list of matching files
    files = rdir(fullfile(baseDir,'**',['*' ext{e}]));
    
    for f = 1:length(files)
        %generate new filename
        filename = files(f).name;
        filename = strrep(filename,[baseDir filesep],''); 
        filename = strrep(filename,filesep,delim);
        filename = fullfile(newDir,filename);

        %copy & rename
        if replace || exist(filename,'file')==0 
            copyfile(files(f).name,filename);
        end
    end
end

end %function


%% changelog
% 7 July 2025
% added code to skip existing files (so can quickly re-run within a
% pipeline) & replace param; backwards compatible unless relying on file 
% replacement by default

% 14 May 2025
% function created
