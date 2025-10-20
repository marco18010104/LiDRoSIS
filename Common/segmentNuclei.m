function [nucMask, nucLabel, nucProps] = segmentNuclei(imgRGB, debug, varargin)
%SEGMENTNUCLEI Segment nuclei in RGB images using the blue (DAPI) channel.
%
%   This function performs:
%     - Adaptive contrast enhancement of the DAPI channel
%     - Binarization and morphological filtering
%     - Border exclusion and cleanup
%     - Merging of small objects near valid nuclei
%     - Extraction of geometric and spatial properties
%     - Optional debug visualization with centroids and radial profiles
%
%   INPUTS:
%       imgRGB      : RGB image with nuclei stained in blue (DAPI)
%       debug       : (optional) logical flag to show debug plots [default: false]
%       varargin    : optional parameter pairs:
%           * 'minArea'         : minimum object area to retain [default: 100 pixels]
%           * 'borderMargin'    : minimum distance to image border [default: 5 pixels]
%           * 'mergeCloseSmall' : whether to merge small objects near real nuclei [default: true]
%           * 'mergeAreaFraction': small object threshold as a fraction of median area [default: 0.4]
%           * 'mergeDist'       : maximum distance for merging [default: 15 pixels]
%
%   OUTPUTS:
%       nucMask  : binary mask of segmented nuclei
%       nucLabel : labeled mask (1 label per nucleus)
%       nucProps : struct array with region properties (e.g., Centroid, Area, Perimeter)
%
%   AUTHOR:
%       Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% =================== PARAMETER PARSING ===================
if nargin < 2, debug = false; end   % Default debug is false if not provided

% Define default parameters and overwrite if provided via varargin
params = struct( ...
    'minArea', 100, ...
    'borderMargin', 5, ...
    'mergeCloseSmall', true, ...
    'mergeAreaFraction', 0.4, ...
    'mergeDist', 15 ...
);
params = parseInputs(params, varargin{:});

% =================== INPUT VALIDATION ===================
% Ensure input is RGB with 3 channels
if size(imgRGB, 3) ~= 3
    error('Input image must be RGB to extract the blue channel.');
end

% =================== PREPROCESSING ===================
fontSize = 18;
blueChannel = im2double(imgRGB(:,:,3));        % Extract the blue channel (DAPI)
blueEnhanced = adapthisteq(blueChannel);       % Apply adaptive histogram equalization

% =================== BINARIZATION ===================
T = graythresh(blueEnhanced);                  % Compute Otsu threshold
bw = imbinarize(blueEnhanced, T * 0.9);        % Threshold slightly lower (more sensitive)

% =================== MORPHOLOGICAL CLEANUP ===================
bw = imfill(bw, 'holes');                      % Fill interior holes in objects
bw = bwareaopen(bw, params.minArea);           % Remove small objects under minArea
bw = imclearborder(bw);                        % Remove objects touching the image border

% =================== LABEL AND EXTRACT PROPERTIES ===================
nucMask = bw;                                  % Binary mask of nuclei
nucLabel = bwlabel(nucMask);                   % Label connected components

% Extract initial region properties for each nucleus
nucProps = regionprops(nucMask, blueEnhanced, ...
    'Centroid', 'Area', 'Perimeter', 'MeanIntensity', ...
    'BoundingBox', 'Eccentricity', 'Solidity', ...
    'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'PixelIdxList');
boundaries = bwboundaries(nucMask);            % Extract object boundaries

% =================== FILTER NUCLEI NEAR IMAGE BORDER ===================
imgSize = size(nucMask);
validIdx = true(numel(nucProps),1);            % Initialize valid object mask

% Exclude nuclei whose centroids are too close to image borders
for i = 1:numel(nucProps)
    c = nucProps(i).Centroid;
    if c(1) <= params.borderMargin || c(1) >= imgSize(2) - params.borderMargin || ...
       c(2) <= params.borderMargin || c(2) >= imgSize(1) - params.borderMargin
        validIdx(i) = false;
    end
end

% Keep only valid nuclei and boundaries
nucProps = nucProps(validIdx);
boundaries = boundaries(validIdx);

% =================== MERGE SMALL OBJECTS CLOSE TO LARGER NUCLEI ===================
if params.mergeCloseSmall && numel(nucProps) > 1
    allAreas = [nucProps.Area];
    areaThresh = params.mergeAreaFraction * median(allAreas);  % Small object area threshold
    distThresh = params.mergeDist;                             % Max distance to merge

    isSmall = allAreas < areaThresh;
    isLarge = ~isSmall;

    largeCentroids = cat(1, nucProps(isLarge).Centroid);       % Collect centroids of large nuclei
    maskMerged = false(size(nucMask));                         % Initialize empty mask

    % Retain large nuclei
    for i = find(isLarge)
        maskMerged(nucProps(i).PixelIdxList) = true;
    end

    % Merge small nuclei if close to any large nucleus
    for i = find(isSmall)
        dists = sqrt(sum((largeCentroids - nucProps(i).Centroid).^2, 2));
        if any(dists < distThresh)
            maskMerged(nucProps(i).PixelIdxList) = true;
        end
    end

    % Update final mask and re-extract properties
    nucMask = maskMerged;
    nucLabel = bwlabel(nucMask);
    nucProps = regionprops(nucLabel, blueEnhanced, ...
        'Centroid', 'Area', 'Perimeter', 'MeanIntensity', ...
        'BoundingBox', 'Eccentricity', 'Solidity', ...
        'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'PixelIdxList');
    boundaries = bwboundaries(nucMask);        % Update boundaries after merging
end

% =================== POLAR SHAPE DESCRIPTORS ===================
% Compute radial profiles and angular descriptors for each nucleus
for k = 1:numel(nucProps)
    b = boundaries{k};
    x = b(:,2); y = b(:,1);
    xC = nucProps(k).Centroid(1);
    yC = nucProps(k).Centroid(2);
    nucProps(k).x = x;
    nucProps(k).y = y;
    nucProps(k).xCentroid = xC;
    nucProps(k).yCentroid = yC;
    nucProps(k).radius = sqrt((x - xC).^2 + (y - yC).^2);     % Distance from centroid
    nucProps(k).angles = atan2d((y - yC), (x - xC));          % Angle from centroid
end

% =================== DEBUG PLOTTING ===================
if debug
    subplot(2,2,1);
    imshow(imgRGB); title('Original RGB Image', 'FontSize', fontSize);

    subplot(2,2,2);
    imshow(blueEnhanced, []); title('Enhanced Blue Channel', 'FontSize', fontSize);

    subplot(2,2,3);
    imshow(nucMask); title('Final Nuclei Mask', 'FontSize', fontSize); hold on;
    for k = 1:numel(nucProps)
        plot(nucProps(k).xCentroid, nucProps(k).yCentroid, 'r+', 'MarkerSize', 14, 'LineWidth', 2);
    end

    subplot(2,2,4); hold on;
    for k = 1:numel(nucProps)
        plot(nucProps(k).radius, '-', 'DisplayName', sprintf('Obj %d', k));
    end
    legend;
    xlabel('Pixel Index Along Contour');
    ylabel('Radius (pixels)');
    title('Radial Profile Around Each Nucleus');
    grid on;
end
end

% =================== PARSE OPTIONAL PARAMETERS ===================
function params = parseInputs(defaults, varargin)
    params = defaults;
    for i = 1:2:length(varargin)
        if isfield(params, varargin{i})
            params.(varargin{i}) = varargin{i+1};
        else
            warning('Unknown parameter: %s', varargin{i});
        end
    end
end
