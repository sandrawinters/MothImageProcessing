function [patchRGB,meanRGB,stdRGB,medianRGB,flag,clicks,crop] = MeasureJolyonStandard(im,gammaVis,zoom)
% Measures Jolyon's (2-patch) color standards in an image
%   User marks center of two patches in standard, which are then measured 
%   & color metrics calculated. Displays the selected regions of each 
%   patch, and asks user whether or not to flag the image for 
%   removal/inspection. Designed to work with the standards Jolyon 
%   Troscianko makes, but should work to measure any standard with a any
%   color standard with two square patches. 
%   
%   INPUT
%   im (m x n x 3 matrix): image to measure
%   gamma (boolean): add gamma correction? (default = 1)
%   zoom (boolean): crop to standard before measuring? (default = 0)
%
%   OUTPUT
%   patchRGB (structure): contains pixel values for each patch
%   meanRGB (8x3 matrix): mean RGB values for each patch
%   stdRGB (8x3 matrix): standard deviation of RGB values for each patch
%   flag (boolean): flag standard?
%   clicks (2x2 matrix): x,y click locations (row order: light patch, dark patch)
%   crop (1x4 vector): crop rectangle (see doc imcrop)
% 
%   CREATES
%   n/a
%
%   RELIES ON
%   n/a
%
%   Sandra Winters <sandra.winters@helsinki.fi> 
%   updated 27 Jan 2023

%% check args & set defaults
if nargin<1
    error('no image provided')
end

if nargin<2
    gammaVis = 1;
end

if nargin<3
    zoom = 0;
end

%% measure macbeth patches
im = im2double(im);

if gammaVis
    H = vision.GammaCorrector;
    imDisp = step(H,im);%apply gamma correction to aid visualisation
else
    imDisp = im;
end

if zoom
    [imDisp,crop] = imcrop(imDisp);
    im = imcrop(im,crop);
    close gcf
else
    crop = NaN;
end

imSize=size(im);

figure; imshow(imDisp); %show the gamma corrected image
title('Click on the center of the squares in the order: LIGHT patch then DARK patch')
hold on

%get user input for location of corner color patches
clicks= zeros(2,2); %in order of reflectance, light --> dark
[clicks(1,1),clicks(1,2)] = ginput(1); %light patch
plot(clicks(1,1),clicks(1,2),'x');

[clicks(2,1),clicks(2,2)] = ginput(1); %dark patch
plot(clicks(2,1),clicks(2,2),'x'); 

%draw a circle around each center, with a radius of 25% the distance btween patches
radius = sqrt((clicks(1,1)-clicks(2,1))^2 + (clicks(1,2)-clicks(2,2))^2)./4;

%create a circle of n radius with 200 equally spaced points
[x,y] = cylinder(radius,200);

%set up a structure for the results
patches = zeros(201,2,size(clicks,1));
patchRGB.vals = [];
meanRGB = zeros(size(clicks,1),3);
stdRGB = zeros(size(clicks,1),3);
medianRGB = zeros(size(clicks,1),3);

R = im(:,:,1);
R = double(R(:));
G = im(:,:,2);
G = double(G(:));
B = im(:,:,3);
B = double(B(:));

for cnt = 1:size(clicks,1)
    patches(:,1,cnt) = x(1,:)+clicks(cnt,1);
    patches(:,2,cnt) = y(1,:)+clicks(cnt,2);
    plot(patches(:,1,cnt),patches(:,2,cnt));
    
    %make a polygon mask for the patch
    BWmask = poly2mask((patches(:,1,cnt)),(patches(:,2,cnt)), imSize(1), imSize(2));
    BWmask = BWmask(:);  
    
    R_patch = R(BWmask == 1);
    G_patch = G(BWmask == 1);
    B_patch = B(BWmask == 1);

    patchRGB(cnt).vals = [R_patch G_patch B_patch];
    meanRGB(cnt,:) = mean(patchRGB(cnt).vals);
    stdRGB(cnt,:) = std(patchRGB(cnt).vals);
    medianRGB(cnt,:) = median(patchRGB(cnt).vals);
end

choice = questdlg('Flag standard?','Flag?','yes','no','no');
switch choice
    case 'yes'
        flag = 1;
    case 'no'
        flag = 0;
end

close all

%% changelog
% 27 Jan 2023
% created based on MeasureAvianTechStandard.m, & altered to work with 2 
% patches
