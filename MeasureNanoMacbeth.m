function [patchRGB,meanRGB,stdRGB,medianRGB,flag,clicks,crop] = MeasureNanoMacbeth(im,nonLin,zoom)
% Measures Macbeth color standard patches in an image
%   User marks center of four corner patches in Macbeth (X-Rite) color
%   checker chart; each of the 24 patches are then measured & color metrics
%   calculated. Displays the selected regions of each patch & a plot of of 
%   the RGB values for greyscale patches, and asks user whether or not to 
%   flag the image for removal/inspection. 
%   Patch order is based on xrite patch numbers (brown >> cyan; white >> 
%   black; see GetMacbethColor). 
%   Note: the same as MeasureMacbeth, except that the radius is calculated
%   based on ./6 instead of ./4 (line 103)

%   INPUT
%   im (m x n x 3 matrix): image to measure
%   nonLin (boolean): add square root transformation? (default = 1)
%   zoom (boolean): crop to standard before measuring? (default = 0)
%
%   OUTPUT
%   patchRGB (structure): contains pixel values for each patch
%   meanRGB (24x3 matrix): mean RGB values for each patch
%   stdRGB (24x3 matrix): standard deviation of RGB values for each patch
%   flag (boolean): flag standard?
%   clicks (4x2 matrix): x,y click locations (order: brown, cyan, white, black)
%   crop (1x4 vector): crop rectangle (see imcrop)
% 
%   CREATES
%   n/a
%
%   RELIES ON
%   divideLine.m
%
%   Sandra Winters <sandra.winters@helsinki.fi> 
%   based on code from Will Allen
%   updated 1 June 2023

%% check args & set defaults
if nargin<1
    error('no image provided')
end

if nargin<2
    nonLin = 1;
end

if nargin<3
    zoom = 0;
end

%% measure macbeth patches
im = im2double(im);

if nonLin
    % H = vision.GammaCorrector;
    % imDisp = step(H,im);%apply gamma correction to aid visualisation
    % imDisp = real(sqrt(im));
    imDisp = im.^0.4;
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
title('Click on the centre of the corner squares of the Macbeth standard in the following order: white, black, brown, cyan')
hold on

%get user input for location of corner color patches
macxy= zeros(24,2);
[macxy(19,1),macxy(19,2)] = ginput(1); %white box
plot(macxy(19,1),macxy(19,2),'x');

[macxy(24,1),macxy(24,2)] = ginput(1); %black box
plot(macxy(24,1),macxy(24,2),'x');

[macxy(1,1),macxy(1,2)] = ginput(1); %brown box
plot(macxy(1,1),macxy(1,2),'x'); 

[macxy(6,1),macxy(6,2)] = ginput(1); %cyan box
plot(macxy(6,1),macxy(6,2),'x');

clicks = macxy([19,24,1,6],:);

%calculate center of each color patch
macxy(1:6,:) = divideLine([macxy(1,:);macxy(6,:)],6);
macxy(19:24,:) = divideLine([macxy(19,:);macxy(24,:)],6);
macxy(1:6:24,:) = divideLine([macxy(1,:);macxy(19,:)],4);
macxy(6:6:24,:) = divideLine([macxy(6,:);macxy(24,:)],4);
macxy(7:12,:) = divideLine([macxy(7,:);macxy(12,:)],6);
macxy(13:18,:) = divideLine([macxy(13,:);macxy(18,:)],6);

%mark center locations
plot(macxy(:,1),macxy(:,2),'x')

%draw a circle around each center, with a radius 1/20 distance btween b&w pythagoras
radius = sqrt((macxy(1,1)-macxy(2,1))^2 + (macxy(1,2)-macxy(2,2))^2)./6;

%create a circle of n radius with 200 equally spaced points
[x,y] = cylinder(radius,200);

%set up a structure for the results
patches = zeros(201,2,24);
patchRGB.vals = [];
meanRGB = zeros(24,3);
stdRGB = zeros(24,3);
medianRGB = zeros(24,3);

R = im(:,:,1);
R = double(R(:));
G = im(:,:,2);
G = double(G(:));
B = im(:,:,3);
B = double(B(:));

for cnt = 1:24
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
errorbar(meanRGB(19:24,1),stdRGB(19:24,1),'r');
hold on
errorbar(meanRGB(19:24,2),stdRGB(19:24,2),'g');
errorbar(meanRGB(19:24,3),stdRGB(19:24,3),'b');
hold off

choice = questdlg('Flag standard?','Flag?','yes','no','no');
switch choice
    case 'yes'
        flag = 1;
    case 'no'
        flag = 0;
end

close all

