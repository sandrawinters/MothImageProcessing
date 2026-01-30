% Renames images based on info in a csv file
%
% Sandra Winters <sandra.winters@colorado.edu>
% updated 23 Jul 2025

%% 
%generate list of image filenames
imDir = 'original_images_vis';
ims = dir(fullfile(d,imDir,'*.tiff'));
imData = table('Size',[length(ims) 2], ... 
               'VariableTypes',{'string','string'}, ... 
               'VariableNames',{'filename','id'});
imData.filename = strrep({ims.name}','.tiff','');
writetable(imData,fullfile(d,'image_data.csv'))

%update file to include IDs (in whatever software you prefer...)
%rename file to 'image_data_with_ids.csv' (so that it won't accidentally be
%overwritten by re-running ^)

%rename images based on IDs -- DON'T RUN THIS UNTIL YOU'RE 200% SURE ABOUT THE TABLE CONTENTS!!! 
imData = readtable('image_data_with_ids.csv','Delimiter',','); %note changed filename
for i = 1:height(imData)
    movefile(fullfile(d,imDir,imData.filename{i}), ... 
             fullfile(d,imDir,[imData.id{i} '.tiff']));
end
