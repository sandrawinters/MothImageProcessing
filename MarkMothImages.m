function [] = MarkMothImages(imDir,stdDir,scaleDir,wingDir,stdType,scaleLen,wingNames,wingSep)
%Marks standards, scale bars, and wing locations in each wood tiger moth image
%   For each image in imDir, the user is asked to mark the standard, scale
%   bar, and wing locations. The type of standard measured is specified in
%   the stdType arg (default 'AvianTech'). The scale bar length is
%   specified in the scaleLen arg (user asked to enter length if it isn't
%   provided). The wings are labeled clockwise from top left based on the
%   wingNames arg; if this is not provided, the user is asked to enter each
%   wing name. The wing separation method is specified by wingSep; if they
%   are cleanly separable by a cross (i.e., no vertical or horizontal
%   overlap, use the 'crosshair' method, otherwise use 'rectangles' (see
%   MarkWing.m). In the first image, the user marks each one (instructions
%   are given in the text above the image). After the first image, the
%   marked locations from the previous image are pre-displayed. To accept
%   these regions, click Yes; to re-mark any of them, click the relevant
%   button (repeat until satisfied). Result files for each image are saved
%   in the appropriate folder. Images are measured if any of the three
%   results files are missing (i.e., to re-measure, just delete one of them
%   & re-run).
%
%   INPUT
%   imDir (string): folder of images to be measured (asks if not provided)
%   stdDir (string): folder to save standard results (asks if not provided)
%   scaleDir (string): folder to save scale bar results (asks if not provided)
%   wingDir (string): folder to save wing location results (asks if not provided)
%   stdType (string): type of standard to measure, must match an option in MatchStandardFun (default 'AvianTech')
%   scaleLen (double): real length of scale bar (e.g., in mm) (asks if not provided)
%   wingNames (1 x 4 cell of strings): identifiers for each wing, order = top left, top right, bottom right, bottom left (asks if not provided)
%   wingSep (string): method to use for separating wings (see doc MarkWing) (default 'crosshair')
%
%   OUTPUT
%   n/a
%
%   CREATES
%   standard measurements saved to stdDir/<image_filename>_standardResults.mat (contains stucture 'standard')
%   scale bar measurements saved to scaleDir/<image_filename>_scaleBar.mat (contains stucture 'scale')
%   wing locations saved to wingDir/<image_filename>_wingLocs.mat (contains stucture 'wingLocs')
%
%   RELIES ON
%   MatchStandardFun.m
%   standard measurement function associated with stdType (see MatchStandardFun.m)
%   MarkScale.m
%   MarkWing.m
%   vis.m
%   CalcPatchGrid.m
%
%   Sandra Winters <sandra.winters@helsinki.fi>
%   updated 21 Jul 2025

%% check args & set defaults 
if nargin<1 || isempty(imDir)
    imDir = uigetdir('','Select folder of images'); 
end

if nargin<2 || isempty(stdDir)
    stdDir = uigetdir('','Select folder for standard results'); 
end
if isfolder(stdDir)==0
    mkdir(stdDir)
end

if nargin<3 || isempty(scaleDir)
    scaleDir = uigetdir('','Select folder for scale bar results'); 
end
if isfolder(scaleDir)==0
    mkdir(scaleDir)
end

if nargin<4 || isempty(wingDir)
    wingDir = uigetdir('','Select folder for wing location results'); 
end
if isfolder(wingDir)==0
    mkdir(wingDir)
end

if nargin<5 || isempty(stdType)
    stdType = 'AvianTech';
    disp('Setting standard type to AvianTech')
end
[stdFun, patchGrid] = MatchStandardFun(stdType); %match specified standard type to standard measurement function

if nargin<6 || isempty(scaleLen)
    scaleLen = input('Enter the length of the scale bar: ','s');
    scaleLen = str2double(scaleLen);
end

if nargin<7 || isempty(wingNames)
    topLeft = input('Enter the name of the top left wing: ','s');
    topRight = input('Enter the name of the top right wing: ','s');
    bottomRight = input('Enter the name of the bottom right wing: ','s');
    bottomLeft = input('Enter the name of the bottom left wing: ','s');

    wingNames = {topLeft,topRight,bottomRight,bottomLeft};
end

if nargin<8 || isempty(wingSep)
    wingSep = 'crosshair';
    disp("Setting wing separation method to 'crosshair'")
end

imExt = '.tiff';
quit = 0;

global resp;

%% get list of images
ims = dir(fullfile(imDir,['*' imExt]));
ims = ims(~startsWith({ims.name},'.')); %exclude hidden mac files

%% loop through images and mark/check locations
for i = 1:length(ims)
    %check if all results already exist
    if exist(fullfile(stdDir,strrep(ims(i).name,imExt,'_standardResults.mat')),'file')==0 || ... 
       exist(fullfile(scaleDir,strrep(ims(i).name,imExt,'_scaleBar.mat')),'file')==0 || ... 
       exist(fullfile(wingDir,strrep(ims(i).name,imExt,'_wingLocs.mat')),'file')==0
        
        %get image
        im = im2double(imread(fullfile(imDir,ims(i).name)));

        %mark all regions in first image
        if i==1
            %standard
            [standard.patchRGB, ... 
             standard.meanRGB, ... 
             standard.sdRGB, ... 
             standard.medianRGB, ... 
             standard.flag, ... 
             standard.clicks, ...
             standard.crop] = feval(stdFun,im);
            standard.image = ims(i).name;
            save(fullfile(stdDir,strrep(ims(i).name,imExt,'_standardResults.mat')),'standard');

            %scale bar
            scale = MarkScale(im,[],[],scaleLen);
            scale.image = ims(i).name;
            save(fullfile(scaleDir,strrep(ims(i).name,imExt,'_scaleBar.mat')),'scale');
            
            %wing locations
            wingLocs = MarkWing(im,wingSep,wingNames);
            wingLocs.image = ims(i).name;
            save(fullfile(wingDir,strrep(ims(i).name,imExt,'_wingLocs.mat')),'wingLocs');    

        %for other images...
        else
            %load previous results
            load(fullfile(stdDir,strrep(ims(i-1).name,imExt,'_standardResults.mat')),'standard')
            load(fullfile(scaleDir,strrep(ims(i-1).name,imExt,'_scaleBar.mat')),'scale')
            load(fullfile(wingDir,strrep(ims(i-1).name,imExt,'_wingLocs.mat')),'wingLocs')
            
            %continue until satisfied
            ok = 0;
            while ok==0
                %display image to mark regions from previous results
                vis(im); title(ims(i).name)

                %mark standard patches
                CalcPatchGrid(standard.clicks,patchGrid);
                % TODO add plot
                
                %mark scale bar
                drawline('Position',scale.coords);
                
                %mark wing locations
                for w = 1:length(wingNames)
                    drawrectangle('Position',wingLocs.(wingNames{w}),'Label',wingNames{w},'LabelAlpha',0.4,'LabelVisible','hover');
                end                

                %check if satisfied
                resp = '';
                f = uifigure('Name','Regions okay?', ... 
                             'Units','normalized', ...
                             'Position',[0.88 0.43 0.10 0.16]);
                uibutton(f,'Text','OK','Position',[20, 130, 150, 30],'ButtonPushedFcn',@(btn,event) buttonCallback('OK'));
                uibutton(f,'Text','Update standard','Position',[20, 100, 150, 30],'ButtonPushedFcn', @(btn,event) buttonCallback('Update standard'));
                uibutton(f,'Text','Update scale bar','Position',[20, 70, 150, 30],'ButtonPushedFcn', @(btn,event) buttonCallback('Update scale bar'));
                uibutton(f,'Text','Update wing locations','Position', [20, 40, 150, 30], 'ButtonPushedFcn', @(btn,event) buttonCallback('Update wing locations'));
                uibutton(f,'Text','Exit','Position', [20, 10, 150, 30], 'ButtonPushedFcn', @(btn,event) buttonCallback('Exit'));
                
                waitfor(f)

                % % resp = questdlg('Regions ok?','Continue','Yes','Update standard','Update scale bar','Update wing locations','Exit','Yes');
                % respOpts = {'Yes','Update standard','Update scale bar','Update wing locations','Exit'}; 
                % [idx, tf] = listdlg('ListString', respOpts,...
                %                     'SelectionMode', 'Single', ...
                %                     'PromptString', 'Regions ok?', ...
                %                     'Initialvalue', 1, ...
                %                     'Name', 'Continue', ...
                %                     'ListSize',[150, 100]);
                % 
                % if tf
                %     resp = respOpts{idx};
                % else
                %     resp = 'Exit';
                % end
                
                %remeasure & flag as necessary
                if strcmp(resp,'OK')
                    ok = 1;
                elseif strcmp(resp,'Update standard')
                    %measure standard
                    [standard.patchRGB, ... 
                     standard.meanRGB, ... 
                     standard.sdRGB, ... 
                     standard.medianRGB, ... 
                     standard.flag, ... 
                     standard.clicks, ...
                     standard.crop] = feval(stdFun,im);
                    standard.image = ims(i).name;
                elseif strcmp(resp,'Update scale bar')
                    %mark scale bar
                    scale = MarkScale(im,[],[],scaleLen);
                    scale.image = ims(i).name;
                elseif strcmp(resp,'Update wing locations')
                    %mark wing locations
                    wingLocs = MarkWing(im,wingSep,wingNames);
                    wingLocs.image = ims(i).name;
                elseif strcmp(resp,'Exit')
                    ok = 1;
                    quit = 1;
                end %if continue
                
                %close figure
                close gcf
            end %while

            %exit if requested 
            if quit
                return
            end

            %save results
            % standard.image = ims(i).name;
            save(fullfile(stdDir,strrep(ims(i).name,imExt,'_standardResults.mat')),'standard');
            
            % scale.image = ims(i).name;
            save(fullfile(scaleDir,strrep(ims(i).name,imExt,'_scaleBar.mat')),'scale');

            % wingLocs.image = ims(i).name;
            save(fullfile(wingDir,strrep(ims(i).name,imExt,'_wingLocs.mat')),'wingLocs');  
        end %if first image
    end %if results exist
    
    %display message when finished
    if i == length(ims)
        msgbox('Congratulations! You have finished measuring all images!','Done','modal');
    end
end %for

end %function

%% button callback function
function buttonCallback(buttonName)
    global resp;
    resp = buttonName;
    closereq()
end

%% changelog
% 21 Jul 2025
% updated to include real scale bar length (added param, sent to 
% MarkScale);
% CHANGED DEFAULT wingLocs to ask user if not provided (instead of using 
% {'left_hindwing','left_forewing','right_forewing','right_hindwing'} as
% default;
% added wingSep param (specifies wing separation method), passed to
% MarkWing;
% NOTE CHANGE IN ARGUMENT ORDER (... stdType,wingNames --> stdType, 
% scaleLen,wingNames,wingSep) 
% ...MIGHT NOT BE BACKWARDS COMPATIBLE

% 14 Feb 2025
% removed wing labels from marked wing locations by default, now they are
% only visible when the mouse hovers over the box;
% updated to exclude .tiff files that start with . (so are actually hidden
% mac files, not tiffs SIGH)