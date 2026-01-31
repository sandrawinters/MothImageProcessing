function [] = vis(im,fullscreen)
%displays image with a square root transformation

if nargin<2
    fullscreen = 0;
end

figure; 
if fullscreen==1 
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
end

imshow(real(sqrt(im2double(im))))

end

