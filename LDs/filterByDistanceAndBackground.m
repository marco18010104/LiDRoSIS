function filteredMask = filterByDistanceAndBackground(ldMask, nucMask, colorChannel, params)
% filterByDistanceAndBackground - Filters LD objects based on distance to nuclei and local background.
%
% PURPOSE:
%   Excludes LD candidates that are either too far from nuclei or in regions of strong background,
%   using adaptive filtering based on proximity and local signal-to-background contrast.
%
% INPUTS:
%   ldMask        : Binary mask (MxN) of LD candidates.
%   nucMask       : Binary mask (MxN) of nuclei.
%   colorChannel  : Grayscale image (MxN) corresponding to the red channel.
%   params        : Struct with the following threshold parameters:
%                   • maxDistLowBg                 : max distance in low background regions.
%                   • maxDistHighBg                : max distance in strong background regions.
%                   • backgroundIntensityThreshold : threshold to define "strong background".
%
% OUTPUT:
%   filteredMask  : Binary mask with LDs that pass the filtering criteria.
%
% FILTERING LOGIC:
%   For each LD object:
%       - Compute minimum distance to any nucleus.
%       - Compute mean background intensity in the object’s surroundings.
%       - Accept the object if:
%           (minDist ≤ maxDistHighBg)
%           OR
%           (minDist ≤ maxDistLowBg AND background is weak)
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

    % Initialize output mask with all pixels set to false
    filteredMask = false(size(ldMask));

    % Store image size for object mask reconstruction
    imageSize = size(ldMask);

    % Early exit if either LD or nuclear mask is empty
    if isempty(ldMask) || nnz(ldMask) == 0 || isempty(nucMask) || nnz(nucMask) == 0
        return;
    end

    % Compute Euclidean distance transform from nuclei
    D = bwdist(nucMask);  % Each pixel contains distance to the nearest nucleus

    % Identify connected LD regions (objects)
    cc = bwconncomp(ldMask);

    % Early exit if no objects are found
    if cc.NumObjects == 0
        return;
    end

    % Retrieve pixel indices for each object
    props = regionprops(cc, 'PixelIdxList');

    % Iterate through each object
    for i = 1:cc.NumObjects
        pixIdx = props(i).PixelIdxList;

        % Safety check: ignore objects with invalid indices
        if any(pixIdx < 1) || any(pixIdx > numel(D))
            continue;
        end

        % Compute the minimum distance of the object to any nucleus
        minDist = min(D(pixIdx));

        % Create a binary mask for the current object
        maskObject = false(imageSize);
        maskObject(pixIdx) = true;

        % Dilate the object to define a background "ring" around it
        maskDilated = imdilate(maskObject, strel('disk', 10));

        % Define background as pixels in the dilated area but not in the object
        backgroundRegion = maskDilated & ~maskObject;

        % Skip objects with no valid background region
        if nnz(backgroundRegion) == 0
            continue;
        end

        % Compute mean intensity in the surrounding background
        meanBackgroundIntensity = mean(colorChannel(backgroundRegion));

        % Apply adaptive filtering criteria:
        % - Accept if distance is small OR distance is moderate and background is weak
        if (minDist <= params.maxDistHighBg) || ...
           (minDist <= params.maxDistLowBg && meanBackgroundIntensity <= params.backgroundIntensityThreshold)
            filteredMask(pixIdx) = true;  % Retain this object
        end
    end
end