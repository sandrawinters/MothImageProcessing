function [patchRGB,meanRGB,stdRGB,medianRGB,flag,clicks,crop] = MeasureAvianTechStandard(im,nonlinVis,zoom)
% Measures 4x2 Avian Technologies color standard patches in an image
%   User marks center of four corner patches in standard; each of the 8 
%   patches are then measured & color metrics calculated. Displays the 
%   selected regions of each patch & a plot of of the RGB values, and asks 
%   user whether or not to flag the image for removal/inspection. Designed
%   to work with Avian Technologies MNA-FSS08-C standards, but should work
%   to measure any standard with a 4x2 grid of square patches. 

%   INPUT
%   im (m x n x 3 matrix): image to measure
%   nonlinVis (boolean): add nonlinearization for visualization? (default = 1)
%   zoom (boolean): crop to standard before measuring? (default = 0)
%
%   OUTPUT
%   patchRGB (structure): contains pixel values for each patch
%   meanRGB (8x3 matrix): mean RGB values for each patch
%   stdRGB (8x3 matrix): standard deviation of RGB values for each patch
%   flag (boolean): flag standard?
%   clicks (4x2 matrix): x,y click locations (order: brown, cyan, white, black)
%   crop (1x4 vector): crop rectangle (see doc imcrop)
% 
%   CREATES
%   n/a
%
%   RELIES ON
%   divideLine.m
%   AddNonlin.m (if nonlinVis = true)
%
%   Sandra Winters <sandra.winters@helsinki.fi> 
%   updated 17 Jan 2025

% TODO update to use CalcPatchGrid

%% check args & set defaults
if nargin<1
    error('no image provided')
end

if nargin<2 || isempty(nonlinVis)
    nonlinVis = 1;
end

if nargin<3
    zoom = 0;
end

%% measure macbeth patches
im = im2double(im);

if nonlinVis
    imDisp = AddNonlin(im); %apply square root transformation for visualisation
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

figure; imshow(imDisp);%show the gamma corrected image
title('Click on the centre of the corner squares in the following order: white, darkest grey, lightest grey, black')
hold on

%get user input for location of corner color patches
macxy= zeros(8,2); %in order of reflectance, white --> black
[macxy(1,1),macxy(1,2)] = ginput(1); %white box
plot(macxy(1,1),macxy(1,2),'x');

[macxy(7,1),macxy(7,2)] = ginput(1); %grey next to black
plot(macxy(7,1),macxy(7,2),'x');

[macxy(2,1),macxy(2,2)] = ginput(1); %grey next to white
plot(macxy(2,1),macxy(2,2),'x');

[macxy(8,1),macxy(8,2)] = ginput(1); %black
plot(macxy(8,1),macxy(8,2),'x'); 

clicks = macxy([1,7,2,8],:);

%calculate center of each color patch
macxy(1:2:7,:) = divideLine([macxy(1,:);macxy(7,:)],4);
macxy(2:2:8,:) = divideLine([macxy(2,:);macxy(8,:)],4);

%mark center locations
plot(macxy(:,1),macxy(:,2),'x')

%draw a circle around each center, with a radius 1/20 distance btween b&w pythagoras
radius = sqrt((macxy(1,1)-macxy(2,1))^2 + (macxy(1,2)-macxy(2,2))^2)./4;

%create a circle of n radius with 200 equally spaced points
[x,y] = cylinder(radius,200);

%set up a structure for the results
patches = zeros(201,2,size(macxy,1));
patchRGB.vals = [];
meanRGB = zeros(size(macxy,1),3);
stdRGB = zeros(size(macxy,1),3);
medianRGB = zeros(size(macxy,1),3);

R = im(:,:,1);
R = double(R(:));
G = im(:,:,2);
G = double(G(:));
B = im(:,:,3);
B = double(B(:));

for cnt = 1:size(macxy,1)
    patches(:,1,cnt) = x(1,:)+macxy(cnt,1);
    patches(:,2,cnt) = y(1,:)+macxy(cnt,2);
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

figure
errorbar(meanRGB(:,1),stdRGB(:,1),'r');
hold on
errorbar(meanRGB(:,2),stdRGB(:,2),'g');
errorbar(meanRGB(:,3),stdRGB(:,3),'b');
hold off

choice = questdlg('Flag standard?','Flag?','yes','no','no');
switch choice
    case 'yes'
        flag = 1;
    case 'no'
        flag = 0;
end

close all

%% changelog
% 17 Jan 2025
% change click order to white, dark grey, light grey, black (reversed last
% two), since that works better with CalcPatchGrid (also that's what I do 
% automatically anyway...); this only impacts the clicks output (not the 
% order of pathes in other vars), and clicks isn't usually used, but *NOTE*
% results generated before today will store clicks in the old order

