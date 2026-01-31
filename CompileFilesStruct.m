function [dataStruct] = CompileFilesStruct(fileDir,structName,varNames,fun)
% Combines all .mat files in a folder into a single .mat file
%   Iteratively loads all .mat files in a folder and combines them into a
%   single .mat table. Each .mat file should contain a structure (specified 
%   by structName). First column in resulting table is file name. Remaining 
%   columns are variables (fieldnames in structure, variables to compile 
%   specified by varNames; for all variables in structure send 'all').
%   Applies the function fun to the data when this argument is provided
%   (e.g. calculates the mean when fun = 'mean'). Only works when output is
%   1 row per file (i.e. variables that are 1 row or multi-row variables
%   that are sent to a function that returns one row); works with variables
%   that are >1 column. 
%
%   INPUT
%   fileDir (string): folder full of .mat files; asks if not included
%   structName (string): name of structure variable; asks if not included
%   varNames (string/string array): name of variables to be compiled (name to access after loading); asks if not included
%       can include multiple variables by sending a string array, e.g. {'var1','var2'}; each variable will be a column in data
%   fun (string): name of function to apply to data (e.g. 'mean'); default ''
%       special case: 'sum' is run with 'all' parameter, so that it returns
%           a single value (e.g., to calculate sum of pixels in mask)
%
%   OUTPUT
%   data (n files x n variables cell): table containing combined data
%       1st col is original filename
%       2nd+ cols are data from variables
%
%   CREATES/SAVES
%   n/a
%
%   RELIES ON
%   n/a
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   last updated 20 Nov 2023

%% check args
if nargin<1
    fileDir = uigetdir(cd,'Select directory for compilation');
end
if nargin<2
    structName = inputdlg('Name of structure to be compiled','structName',1,{''});
end
if nargin<3
    varNames = inputdlg('Name of variable to be compiled (enter ''all'' to compile all variables)','varNames',1,{''});
end
if nargin<4
    fun = '';
end

if isfolder(fileDir)==0
    error([origDir ' is not a directory'])
end

if ischar(varNames)
    varNames = {varNames};
end
if iscellstr(varNames)==0  %#ok<ISCLSTR>
    error('Variable to be compiled must be a string or string array')
end

%% get files
if ispc
    foldDelim = '\';
else
    foldDelim = '/';
end

files = dir([fileDir foldDelim '*.mat']);
files = {files.name}';
if isempty(files)
    error(['No .mat files in ' fileDir])
end

%% check variables
load([fileDir foldDelim files{1}],structName);
if strcmp(varNames,'all')
    varNames = fieldnames(eval(structName));
end

nCol = ones(1,length(varNames)+1);
for i = 1:length(varNames)
    if isempty(fun)>0
        if size(eval([structName '.' varNames{i}]),1)>1 || length(size([structName '.' varNames{i}]))>2
            disp(['WARNING: ' varNames{i} ' not compiled (more than 1 row)'])
            nCol(i+1) = 0;
        else
            nCol(i+1) = size(eval([structName '.' varNames{i}]),2);
        end
    else
        %TODO check function return values(s)
    end
end
varNames(nCol(2:end)==0) = [];
nCol(nCol==0) = [];

%% compile data
dataStruct = cell(length(files),length(varNames)+1);
for i = 1:length(files)
    load([fileDir foldDelim files{i}],structName);
    dataStruct(i,1) = strrep(files(i),'.mat','');
    for j = 1:length(varNames)
        var = eval([structName '.' varNames{j}]);
%         if isnumeric(var)
%             var = mat2cell(var);
%         elseif ischar(var)
%             var = cellstr(var);
%         end
        if iscell(var)==0
            var = {var};
        end
        
        if isempty(fun)
            dataStruct(i,j+1) = var;
        elseif strcmp(fun,'sum')
            dataStruct(i,j+1) = {sum(cell2mat(var),'all')};
        else
            dataStruct(i,j+1) = feval(fun,var); %#ok<FVAL>
        end
    end
end

varNames = reshape(varNames,1,[]);
dataStruct = cell2table(dataStruct,'VariableNames',[{'filename'},varNames]);


%% changelog
% 20 Nov 2023
% added special case for fun = 'sum' -- calculates the sum with 'all' param

% 10 Jun 2022 
% changed variable data to dataStruct to avoid conflicts when structName = 'data'

% 2 Mar 2021 
% updated to include option for applying function to data
