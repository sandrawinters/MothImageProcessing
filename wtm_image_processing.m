% image processing pipeline for wood tiger moth images
% (currently only processes visible images)

% Sandra Winters <sandra.winters@colorado.edu
% updated Jan 30 2026

%% setup
% set your current directory (function cd) to folder of code
% set variable d to folder of images
    % Should contain a folder called 'raw_images' that has the original
    % (raw) images from the camera (or update 'raw_images' below to
    % whatever that folder is called on your computer)

% setup for default users; otherwise popup asks for locations
if ismember(getenv('USERNAME'),{'wintsand','Localadmin_wintsand','sandra'}) %SW computer
    if isunix %linux desktop
        cd ~/Dropbox/Color_scripts 
        % d = '/home/wintsand/Dropbox/wtm_images/testing';
        d = '/mnt/Elements/wtm_images/';
    else %PC laptop
        cd C:\Users\wintsand\Dropbox\Color_scripts
        % d = 'C:\Users\wintsand\Dropbox\wtm_images\testing';
        d = 'D:\wtm_images\';
    end
% YOU CAN ADD YOUR OWN DEFAULT BY UPDATING THE CODE BELOW 
% elseif strcmp(getenv('USERNAME'),<your_username>) 
%     cd <your_folder_of_code>
%     d = '<your_folder_of_images>';
else %unknown computer -- get user to select relevant directories
    cd(uigetdir(cd,'Select folder of code (current directory)'))
    d = uigetdir(cd,'Select folder of images (should contain "original_images" and other folders)');
end

% set vars - MAKE SURE ALL OF THE VARIABLES BELOW ARE CORRECT FOR YOUR IMAGE LAYOUT & MATERIALS! 
standard = 'AvianTech'; %type of color standard (see MatchStandardFun.m for more options, e.g. 'Jolyon' for DIY two-patch standards)
realScaleLength = 50; %real length of the scale bar (e.g. in mm)
wingNames = {'left_hindwing','left_forewing','right_forewing','right_hindwing'}; %wing names, order: clockwise from top left of image
wingSepMethod = 'crosshair'; %method for marking wings 
    %'crosshair': crop to wing region then separate using a click in the center (best when wings can be cleanly separated by a cross)
    %'rectangles': mark each wing using a separate rectangle (best when wings cannot be cleanly sparated)

ppmm = 10; %scaled image resolution in pixels per unit of realScaleLength above (e.g. pixels per mm)

imExt = '.tiff'; %image file extension

% NOTES: 
% if you have images sorted into folders (e.g. by year, location) and don't
% want to deal with this chaos, check out Folders2Filenames.m
% 
% images and data are linked using filenames, so NO CHANGING! (don't
% process images until filnames are finalized!!!)
%
% commented out sections below may be useful! remove comments from code as 
% needed. 

%% Extract images to process
% CopyEveryXImages(fullfile(d,'raw_images'), ... %folder of raw images 
%                  fullfile(d,'original_images_vis'), ... %folder to copy images to
%                  6, ... %image set size (3 vis images, 3 uv images)
%                  2, ... %copy every 2nd image -- vis image with -0.6 exposure compensation
%                  '.SRW') %image extension

% Copies every X image from a folder, useful when using the slider uv-vis
% camera with exposure bracketing. ALWAYS CHECK EXPOSURES TO MAKE SURE
% YOU'RE EXTRACTING THE RIGHT IMAGES. 

%% Rename as necessary
% Rename images here if you want to (e.g., based on ID in image -- easiest
% to just rename in file manager with preview; but see 
% rename_images_by_file.m for an option to generate a metadata file for
% renaming

% No file renaming past this point!! 

%% Convert raw images to linear tiffs
RawToTiff(fullfile(d,'original_images_vis'), ... %folder of raw images
          'dcraw') %method

%% Mark standards, scale bars, and wings - visible images

%OPTION 1: mark all at the same time
MarkMothImages(fullfile(d,'original_images_vis'), ... %folder of original images
               fullfile(d,'standards_vis'), ... %folder to save standard results
               fullfile(d,'scalebars_vis'), ... %folder to save scale bar results
               fullfile(d,'winglocs_vis'), ... %folder to save wing locations
               standard, ... %type of color standard 
               realScaleLength, ... %real length of scale bar 
               wingNames, ... %wing names, order: clockwise from top left
               wingSepMethod); %method for marking wings

% The first image will pop up, and ask you to mark the color standard,
% scale bar, and wing locations. See instructions for each below. After
% this, each image will pop up with these regions marked based on the
% locations in the previous image, and a box asking if the regions are ok. 
% To re-mark any of these options, select the relevant option, remark, and
% re-check the image (an image will keep popping up until it is marked ok,
% so you can re-measure all regions if necessary). Once an image is marked 
% as ok, the next will automatically pop up. Click exit to quit (note: if 
% you click exit, the regions of the currently displayed image will NOT be 
% saved; it will be the first image to pop up next time the function is 
% run). Each time the function is run it checks for all of the relevant
% results files for each image; to re-run any previously marked images
% (e.g., if you realize there was a problem after hitting ok), delete any
% of these .mat files saved by this function (in the standard, scale bar,
% or wing location folders) and the image will automatically be re-marked
% the next (!) time the function is run. 
%
% To measure standards: 
% (1) Click on the center of the corner patches in the order specified
% (2) After the last click, the measured regions of the patches will be
%     circled and a plot of the mean +/- SD for each patch will be 
%     displayed -- verify that everything looks ok (plot should be smoothly
%     decreasing, no signs of saturation, nothing weird in the measured
%     patch regions, etc.)
% (3) If there is a problem, click the flag button (images with flagged
%     standards are automatically excluded from additional processing);
%     otherwise, click ok
% 
% To measure scale bars: 
% (1) Draw a line from the beginning to the end of the scale bar (click to 
%     start, release to end) 
% (2) Reposition endpoints as necessary
% (3) Hit any key to proceed
% 
% To mark wing locations (using the default 'crosshair' method): 
% (1) Drag the crosshairs to select the region of the image containing just
%     the wings on the background
% (2) Adjust the region as necessary, then double-click inside the
%     rectangle
% (3) Click in the center of the wings, so that the crosshair separates
%     the four wings

%OPTION 2: mark each comnponent separately (see instructions for each above)
% MeasureStandards(fullfile(d,'original_images_vis'), ... %folder of original images
%                  fullfile(d,'standards_vis'), ... %folder to save standard results
%                  'AvianTech', ... %type of color standard 
%                  1, ... %display a noninear version of the image?
%                  0, ... %zoom before marking?
%                  1) %pre-mark with data from previous image?
% 
% MarkScales(fullfile(d,'original_images_vis'), ... %folder of original images
%            fullfile(d,'scalebars_vis'), ... %folder to save scale bar results
%            1, ... %display a noninear version of the image?
%            0, ... %zoom before marking?
%            1); %pre-mark with data from previous image?
% 
% MarkWings(fullfile(d,'original_images_vis'), ... %folder of original images
%           fullfile(d,'winglocs_vis'), ... %folder to save wing locations
%           'crosshair', ... %method for marking wings 
%           wingNames) %wing names, order: clockwise from top left

%% Standardize images
StandardizeImages(fullfile(d,'original_images_vis'), ... %folder of original images
                  fullfile(d,'standards_vis'), ... %folder of standard results
                  fullfile(d,'standardized_images_vis'), ... %folder to save standardized images
                  standard) %type of color standard 

%generate nonlinear versions
AddNonlins(fullfile(d,'standardized_images_vis'), ... %folder of linear images
           fullfile(d,'standardized_images_vis_sqrt')) %folder to save nonlinear (square root transformed) images

%% Crop to each wing
for i = 1:length(wingNames)
    CropImagesToRects(fullfile(d,'standardized_images_vis'), ... %folder of standardized images
                      fullfile(d,'winglocs_vis'), ... %folder of wing location data
                      fullfile(d,'wings_vis'), ... %folder to save cropped wings
                      ['wingLocs.' wingNames{i}], ... %variable to extract from wing location data
                      wingNames{i}) %text to add to new images
end

%% Scale images to standard resolution
ScaleImages(fullfile(d,'wings_vis'), ... %folder of images to scale
            fullfile(d,'scalebars_vis'), ... %folder of scale bar data
            fullfile(d,'wings_scaled_vis'), ... %folder to save scaled images
            'NA', ... %scale bar length (e.g. in mm) -- set to 'NA' to use saved realLength
            ppmm, ... %resolution of scaled images, in same unit as above (e.g. number of pixels per mm)
            [], ... %size up images if necessary? (leave at default)
            strcat('_',wingNames)) %text to exclude when matching image & scale bar files

%generate nonlinear versions
AddNonlins(fullfile(d,'wings_scaled_vis'), ... 
           fullfile(d,'wings_scaled_vis_sqrt'))

%% Auto-segmentation of wings
SAMImages(fullfile(d,'wings_scaled_vis_sqrt'), ... %folder of images to segment
          fullfile(d,'wing_masks'), ... %folder to save wing masks
          1, ... %resize parameter (make this smaller to save processing time)
          [8 8]) %pointGridSize (see doc imsegsam)
% Note: requires the "Image Processing Toolbox Model for Segment Anything
% Model" add-on

MaskImages(fullfile(d,'wings_scaled_vis_sqrt'), ... %folder of images to mask
           fullfile(d,'wing_masks'), ... %folder of wing masks
           fullfile(d,'wings_masked_sqrt'), ... %folder to save masked images
           sqrt(0.2)) %background color

%% WING SEGMENTATION SCREENING

% GO THROUGH WINGS_MASKED_SQRT AND DELETE ANY IMAGES WITH ERRORS

%delete associated wing masks
masks = dir(fullfile(d,'wing_masks',['*' imExt]));
maskedIms = dir(fullfile(d,'wings_masked_sqrt',['*' imExt]));
rm = ~ismember({masks.name},{maskedIms.name});
for i = 1:length(rm)
    if rm(i)
        delete(fullfile(d,'wing_masks',masks(i).name)); % delete associated wing mask
    end
end

clear masks maskedIms rm

%% Manually mark wings that didn't segment properly
MarkROIs(fullfile(d,'wings_scaled_vis_sqrt'), ... %folder of images to segment
         fullfile(d,'wing_masks'), ... %folder to save wing masks
         'spline', ... %type of ROI to mark (options: 'assisted', 'freehand', 'polygon', 'rectangle' 'spline', see doc MeasureROIs for more details)
         0, ... %zoom before marking?
         0) %display a noninear version of the image?

% NOTE: can test out different ROI marking types (replace 'spline' with 
% preferred option) to see what works best. 
% Basic instructions: 
% ROI marking options (type parameter) are mostly based on matlab draw
% functions: 'assisted' attempts to trace a boundary between user-selected
% points; 'freehand' draws boundary directly from user mouse movements
% (click down to start, release to finish), 'polygon' connects
% user-selected points with straight lines, and 'rectangle' draws a
% rectangle. Double-click in the ROI to finish and proceed to the next
% image. The 'spline' option (not a matlab draw function) uses spline
% interpolation of user-selected points in a custom GUI to generate the ROI
% (click 'Start', click once to initiate, mark points with double-click
% indicating final point, adjust points as necessary, click 'Save & Exit').

%generate masked images for manually-generated masks
MaskImages(fullfile(d,'wings_scaled_vis_sqrt'), ... %folder of images to mask
           fullfile(d,'wing_masks'), ... %folder of wing masks
           fullfile(d,'wings_masked_sqrt'), ... %folder to save masked images
           sqrt(0.2)) %background color
         
%% Segment melanization 
WtmClusterMelanin(fullfile(d,'wings_scaled_vis_sqrt'), ... %image directory
                  fullfile(d,'wing_masks'), ... %wing mask directory
                  fullfile(d,'melanin_masks'), ... %melanized mask directory
                  fullfile(d,'non-melanin_masks'), ... %non-melanized mask directory
                  fullfile(d,'wings_recolored'), ... %recolored image directory
                  fullfile(d,'wings_overlayed'), ... %overlayed image directory
                  2, ... %k
                  1) %erode radius

%% Generate comparison images for each wing
CreateImageComparisons({fullfile(d,'wings_scaled_vis_sqrt'), ... %folders to combine >>>
                        fullfile(d,'wings_masked_sqrt'), ... 
                        fullfile(d,'wings_recolored'), ...
                        fullfile(d,'wings_overlayed')}, ... % <<<
                       fullfile(d,'wing_comparisons')) %folder to save composite image

% Note: this generates composite images for each wing, combining the images
% from the folders specified. Useful for screening, but not necessary for
% analyses. 

%% Generate montage of comparison images 
% ims = dir(fullfile(d,'wing_comparisons/*.tiff'));
% figure; montage(fullfile({ims.folder}',{ims.name}'), ... 
%                 'BackgroundColor',sqrt([0.2 0.2 0.2]), ... 
%                 'Size',[5 4])
% imwrite(gcf.CData)

% Note: this combines many wing comparison images (generated immediately
% above) into a single figure, for easier viewing. Only sensible for a
% smallish number of images though (not the whole image database). To run 
% with a smaller number of exemplars: put selected comparison images in a
% folder, change 'wing_comparisons...' above to the name of that folder,
% and run the code. It will generate a matlab figure, which can be
% exported in whatever format you prefer. 

%% extract size data
%add wing size
data = CalcMaskSize(fullfile(d,'wing_masks'),fullfile(d,'wing_mask_data'));
data.Properties.VariableNames{end} = 'wing_px';

%add melanized size
data = join(data,CalcMaskSize(fullfile(d,'melanin_masks'),fullfile(d,'melanin_mask_data')));
data.Properties.VariableNames{end} = 'melanized_px';

%add nonmelanized size
data = join(data,CalcMaskSize(fullfile(d,'non-melanin_masks'),fullfile(d,'non-melanin_mask_data')));
data.Properties.VariableNames{end} = 'nonmelanized_px';

%calc prop melanized
data.prop_melanized = data.melanized_px ./ (data.melanized_px + data.nonmelanized_px);

%clean up filename
data.filename = strrep(data.filename,'_maskData','');

%save data file (saved to current directory)
writetable(data,fullfile(d,'data.csv'))

