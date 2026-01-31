function [mask, flag] = MarkSplineROI(im)
%Mark an ROI on an image using spline interpolation of user-selected points
%   Quick chunking out of Will's code for another function...
%   TODO detailed summary

% Sandra Winters <sandra.winters@colorado.edu>
% code originally from Will Allen
% updated Jan 27 2026

% TODO clean up & streamline...
%      add instructions to figure
%      make flag optional

%% check args & set defaults 
% TODO 

im = im2double(im);

if isfolder('PRG')
    addpath('PRG')
end

%% select ROI 
%save crop temporarily - this is a bit of a hackky way of getting the data to the PRG function
gTIFFcrop = im;
face_path = '';
save 'temp.mat' gTIFFcrop face_path
% SW TODO make ^ less messy & update in all files...

%trace out the red patch outline
prg
waitfor(prg)

%create a mask
load('temp_res.mat','xy','flag') % again a hack to get the data from the PRG function

mask = poly2mask(xy(:,1), xy(:,2), size(im,1),size(im,2));

%delete temporary variables
delete('temp.mat','temp_res.mat');


%% changelog
% Jan 27 2026
% created based on code in MarkROI.m