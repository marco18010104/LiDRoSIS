function diffuseROSMask = detectDiffuseROS(imgRGB, debug, nucMask)
% DETECTDIFFUSEROS - Detects diffuse Reactive Oxygen Species (ROS) regions with smooth edges
% using intensity-based clustering via k-means on grayscale fluorescence images.
%
% This method segments the image into clusters of intensity and selects the brightest cluster
% as the diffuse ROS candidate mask. Morphological filtering and optional exclusion of nuclei
% overlapping or distant objects are applied.
%
% INPUTS:
%   imgRGB      - MxNx3 numeric RGB image (uint8, uint16 or double [0,1]), fluorescence image.
%   debug       - (optional) logical scalar; if true, shows intermediate images for debugging.
%                 Default: false.
%   nucMask     - (optional) MxN logical binary mask of nuclei locations. Used to exclude ROS
%                 overlapping nuclei or too far from nuclei.
%
% OUTPUT:
%   diffuseROSMask - MxN logical mask identifying diffuse ROS candidate regions.
%
% EXCEPTIONS / WARNINGS:
%   - Throws error if imgRGB does not have 3 channels.
%   - Throws error if nucMask is provided but size or type does not match imgRGB.
%
% EXAMPLES:
%   img = imread('sample_cells.tif');
%   diffuseMask = detectDiffuseROS(img, true);
%
%   nucleiMask = segmentNuclei(img);
%   diffuseMask = detectDiffuseROS(img, false, nucleiMask);
%
% NOTES:
%   - Number of clusters (default 3) can be tuned for image characteristics.
%   - Intensity threshold and max pixel subsampling prevent k-means failures on large images.
%   - Morphological parameters can be adjusted to capture different ROS morphologies.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

if nargin < 2
    debug = false;
end

if size(imgRGB,3) ~= 3
    error('Input image must be an RGB image with 3 color channels.');
end

imgGray = im2double(rgb2gray(imgRGB));  % Convert to grayscale double [0,1]
imgGray = imadjust(imgGray);             % Contrast adjustment

% Parameters
numClusters = 3;         % Number of intensity clusters for k-means
intensityThreshold = 0.01; % Filter out very dark pixels for clustering
maxPixels = 50000;       % Max pixels for k-means subsampling to improve stability

% Prepare pixel data for clustering (intensity values above threshold)
pixelVals = imgGray(:);
pixelVals = pixelVals(pixelVals > intensityThreshold);

% Subsample pixels if dataset too large for k-means
if numel(pixelVals) > maxPixels
    pixelValsSample = datasample(pixelVals, maxPixels, 'Replace', false);
else
    pixelValsSample = pixelVals;
end

% Perform initial k-means clustering on sampled pixels to get cluster centers
[~, clusterCenters] = kmeans(pixelValsSample, numClusters, 'Replicates', 3);
clusterCenters = clusterCenters(:); % Ensure column vector

% Apply k-means to entire image using initialized cluster centers
fullIdx = kmeans(imgGray(:), numClusters, 'Start', clusterCenters, 'MaxIter', 100);

% Reshape clustering result to image size
segmentedImg = reshape(fullIdx, size(imgGray));

% Select brightest cluster as diffuse ROS mask
[~, sortedIdx] = sort(clusterCenters, 'ascend');
brightestCluster = sortedIdx(end);
diffuseROSMask = (segmentedImg == brightestCluster);

% Morphological filtering to remove small noise and close gaps
diffuseROSMask = bwareaopen(diffuseROSMask, 30);             % Remove small objects
diffuseROSMask = imclose(diffuseROSMask, strel('disk', 3));  % Close holes and gaps

% Optional nuclei-based filtering
if nargin > 2 && ~isempty(nucMask)
    if ~islogical(nucMask) || ~isequal(size(nucMask), size(diffuseROSMask))
        error('nucMask must be a logical mask matching image size.');
    end
    
    % Remove objects overlapping nuclei
    diffuseROSMask = diffuseROSMask & ~nucMask;
    
    % Remove objects too far from any nucleus (beyond maxDist pixels)
    maxDist = 90;
    D = bwdist(nucMask);
    
    labeled = bwlabel(diffuseROSMask);
    props = regionprops(labeled, 'PixelIdxList');
    
    for k = 1:numel(props)
        pixDist = D(props(k).PixelIdxList);
        if all(pixDist > maxDist)
            diffuseROSMask(props(k).PixelIdxList) = 0;
        end
    end
end

% Debug visualization
if debug
    figure('Name', 'Diffuse ROS Detection');
    subplot(1,3,1); imshow(imgGray, []); title('Adjusted Grayscale Image');
    subplot(1,3,2); imshow(label2rgb(segmentedImg)); title('K-means Clustering');
    subplot(1,3,3); imshow(diffuseROSMask); title('Diffuse ROS Mask');
end

end
