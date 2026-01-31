function [imClust,imRecol,imOverlay,kMasks,clustDat] = KMClusterROI(im,mask,k,pxType,bgCol)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% check args & set defaults
if nargin<1 || isempty(im)
    error('no image provided')
end
im = im2double(im);

if nargin<2 || isempty(mask)
    error('no ROI mask provided')
end
if size(mask,3)>1
    mask = mask(:,:,1);
end
mask = logical(mask);

if nargin<3 || isempty(k)
    k = 'silhouette';
end

if nargin<4 || isempty(pxType)
    pxType = 'rgb';
end

if nargin<5 || isemtpy(bgCol)
    bgCol = sqrt(0.2);
end
if isscalar(bgCol)
    bgCol = repelem(bgCol,3);
end

%TODO check values

%% set up cluster data structure
clustDat.pxType = pxType;

%% extract & process ROI pixels
%extract pixels
px = reshape(im,[],3);
pxMasked = px(mask(:),:);

%transform pixels
if strcmp(pxType,'rgb')
    %use original RGB values
    dat = pxMasked;
elseif strcmp(pxType,'opponency')
    %use opponency channels
    lum = (pxMasked(:,1)+pxMasked(:,2))./2;
    rg = (pxMasked(:,1)-pxMasked(:,2))./(pxMasked(:,1)+pxMasked(:,2));
    by = (pxMasked(:,3)-lum)./(pxMasked(:,3)+lum);
    dat = [lum rg by];
elseif strcmpi(pxType,'lab')
    dat = rgb2lab(pxMasked);
elseif strcmpi(pxType,'hsv')
    dat = rgb2hsv(pxMasked);
elseif strcmpi(pxType,'pca')
    [~,score,latent] = pca(pxMasked);
    dat = [rescale(score(:,1)./latent(1)) rescale(score(:,2)./latent(2))];
end

%% cluster ROI
%determine optimal k (if needed)
if strcmpi(k,'silhouette')
    eva = evalclusters(dat,'kmeans','Silhouette','Klist',1:6);
    k = eva.OptimalK;
    clustDat.optimalK = 'silhouette';
end
clustDat.k = k;

%run k-means clustering
[km,centroids] = kmeans(dat,k);
clustDat.centroids = {centroids}; 

%     figure; scatter3(col(:,1),col(:,2),col(:,3),[],km,'.');
%     xlabel('Red-green')
%     ylabel('Blue-yellow')
%     zlabel('Luminance')

%generate clustered image
pxClust = zeros(size(px,1),1); %pixels outside ROI are 0s
pxClust(mask(:)) = km;
imClust = reshape(pxClust,size(mask));

%% generate masks for each cluster
kMasks = false([size(mask) k]);
for i = 1:k
    kMasks(:,:,i) = imClust==i;
end

%% recolor ROI
%calculate median color for each cluster
clustDat.medianColor = zeros(k,3);
for i = 1:k
    clustDat.medianColor(i,:) = median(pxMasked(km==i,:));
end

%generate recolored image
pxRecol = repmat(bgCol,size(px,1),1);
for i = 1:k
    mask = kMasks(:,:,i);
    pxRecol(mask(:),1) = clustDat.medianColor(i,1);
    pxRecol(mask(:),2) = clustDat.medianColor(i,2);
    pxRecol(mask(:),3) = clustDat.medianColor(i,3);
end
imRecol = reshape(pxRecol,size(im));

%generate image overlay
imOverlay = labeloverlay(im,imClust,'Colormap',clustDat.medianColor);
% imOverlay = labeloverlay(im,imClust,'Colormap','jet');

end %function