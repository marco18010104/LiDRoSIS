function diffuseLDMask = detectDiffuseLDs(imgRGB, debug, nucMask)
% detectDiffuseLDs - Detects diffuse (soft-edged) lipid droplets using intensity-based clustering (K-means).
%
% PURPOSE:
%   Identifies lipid droplets with diffuse morphology, typically less well-defined by edge-based methods.
%   Uses intensity-based K-means clustering and optionally filters by spatial proximity to nuclei.
%
% INPUTS:
%   imgRGB   : MxNx3 RGB image - The original fluorescence image.
%   debug    : Boolean - If true, enables debug plots of intermediate steps.
%   nucMask  : (Optional) MxN binary mask of nuclei. If provided, used to exclude irrelevant regions.
%
% OUTPUT:
%   diffuseLDMask : MxN binary mask of detected diffuse LDs.
%
% METHOD OVERVIEW:
%   - Convert image to grayscale and enhance contrast.
%   - Apply intensity-based K-means clustering to segment bright regions.
%   - Select the brightest cluster as potential diffuse LDs.
%   - Filter by size, morphology, and optionally by distance to nuclei.
%
% EXAMPLE USAGE:
%   mask = detectDiffuseLDs(imgRGB, true, nucleiMask);
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% ---------------------- 1. Preprocessing ------------------------

% Convert to grayscale and normalize intensity
imgGray = im2double(rgb2gray(imgRGB));
imgGray = imadjust(imgGray);  % contrast enhancement

% ---------------------- 2. Parameters ---------------------------

numClusters = 3;                  % Number of intensity clusters for K-means
intensityThreshold = 0.05;       % Minimum intensity to consider a pixel in clustering
maxPixels = 50000;               % Limit for memory-efficient subsampling
minObjectSize = 30;              % Minimum size of objects to keep (in pixels)
maxDist = 90;                    % Maximum allowed distance from any nucleus

% ---------------------- 3. Clustering Setup ---------------------

% Extract pixel values above intensity threshold
pixelVals = imgGray(:);
pixelVals = pixelVals(pixelVals > intensityThreshold);

% Subsample to prevent memory overload in large images
if numel(pixelVals) > maxPixels
    pixelValsSample = datasample(pixelVals, maxPixels, 'Replace', false);
else
    pixelValsSample = pixelVals;
end

% ---------------------- 4. Initial K-means ----------------------

% Perform K-means on the sample to get stable cluster centers
[~, clusterCenters] = kmeans(pixelValsSample, numClusters, 'Replicates', 3);
clusterCenters = clusterCenters(:);  % ensure column vector

% Assign all pixels to one of the clusters using the trained centers
fullIdx = kmeans(imgGray(:), numClusters, ...
    'Start', clusterCenters, 'MaxIter', 100);
segmentedImg = reshape(fullIdx, size(imgGray));

% ---------------------- 5. Extract Brightest Cluster ------------

% Identify the brightest cluster (assumed to represent LDs)
[~, sortedIdx] = sort(clusterCenters, 'ascend');
brightestCluster = sortedIdx(end);  % highest intensity cluster
diffuseLDMask = segmentedImg == brightestCluster;

% Morphological cleanup
diffuseLDMask = bwareaopen(diffuseLDMask, minObjectSize);
diffuseLDMask = imclose(diffuseLDMask, strel('disk', 3));

% ---------------------- 6. Nucleus Filtering --------------------

if nargin > 2 && ~isempty(nucMask)
    % Remove pixels overlapping directly with nuclei
    diffuseLDMask = diffuseLDMask & ~nucMask;

    % Remove objects that are too far from any nucleus
    D = bwdist(nucMask);  % Distance map from nuclei
    labeled = bwlabel(diffuseLDMask);  % Label diffuse LDs
    props = regionprops(labeled, 'PixelIdxList');

    for k = 1:numel(props)
        pixDist = D(props(k).PixelIdxList);
        if all(pixDist > maxDist)
            diffuseLDMask(props(k).PixelIdxList) = 0;  % Remove distant object
        end
    end
end

% ---------------------- 7. Debug Plotting -----------------------

if debug
    figure('Name', 'Diffuse LD Detection');
    subplot(1,3,1); imshow(imgGray, []); title('Enhanced Grayscale Image');
    subplot(1,3,2); imshow(label2rgb(segmentedImg)); title('K-means Clusters');
    subplot(1,3,3); imshow(diffuseLDMask); title('Diffuse LD Mask');
end

end
