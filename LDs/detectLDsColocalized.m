function [ldColocMask, ldColocLabel, ldColocProps] = detectLDsColocalized(ldMaskGreen, ldMaskRed, debug)
% detectLDsColocalized - Detects colocalized lipid droplets (LDs) in green and red channels.
%
% PURPOSE:
%   Identifies LDs that are present simultaneously in both green and red masks, indicating
%   potential colocalization. Morphological constraints are applied to filter out spurious
%   intersections, and object properties are extracted.
%
% INPUTS:
%   ldMaskGreen : Binary mask (MxN) containing green-channel LDs (logical).
%   ldMaskRed   : Binary mask (MxN) containing red-channel LDs (logical).
%   debug       : Boolean flag. If true, enables visual debugging plots.
%
% OUTPUTS:
%   ldColocMask  : Binary mask of colocalized LDs (green ∩ red).
%   ldColocLabel : Labeled image of colocalized LDs (integer labels).
%   ldColocProps : Struct array with region properties of colocalized LDs.
%
% MORPHOLOGICAL FILTERING CRITERIA:
%   - Area between 4 and 300 pixels.
%   - Eccentricity less than 0.75 (more circular objects).
%   - Solidity greater than 0.7 (compactness).
%
% EXAMPLE USAGE:
%   colocMask = detectLDsColocalized(ldMaskGreen, ldMaskRed, true);
%   imshow(colocMask);
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% ------------------ 1. Dilate Masks Slightly ------------------

% Light dilation to allow for minor misalignments between red and green masks
se = strel('disk', 1);
ldMaskGreenDil = imdilate(ldMaskGreen, se);
ldMaskRedDil   = imdilate(ldMaskRed, se);

% ------------------ 2. Logical Intersection ------------------

% Identify colocalized regions: overlapping red and green pixels
colocMask = ldMaskGreenDil & ldMaskRedDil;

% ------------------ 3. Morphological Cleaning ------------------

% Remove small noise and fill holes in detected regions
colocMask = bwareaopen(colocMask, 5);
colocMask = imfill(colocMask, 'holes');

% ------------------ 4. Labeling ------------------

% Assign unique labels to each connected component
colocLabel = bwlabel(colocMask);

% ------------------ 5. Morphological Filtering ------------------

% Extract region properties for filtering
props = regionprops(colocLabel, ...
    'Area', 'Eccentricity', 'Solidity', ...
    'Centroid', 'PixelIdxList', 'BoundingBox', ...
    'EquivDiameter', 'MajorAxisLength', 'MinorAxisLength');

% Keep only those that meet morphological criteria
validIdx = find([props.Area] >= 20 & [props.Area] <= 300 & ...
                [props.Eccentricity] < 0.85 & [props.Solidity] > 0.7);

% Create filtered labeled mask
ldColocLabel = ismember(colocLabel, validIdx);
ldColocMask  = ldColocLabel > 0;
ldColocLabel = bwlabel(ldColocMask);

% Compute updated region properties for the filtered colocalized LDs
ldColocProps = regionprops(ldColocLabel, ...
    'Area', 'Centroid', 'PixelIdxList', ...
    'Eccentricity', 'EquivDiameter', 'BoundingBox', ...
    'MajorAxisLength', 'MinorAxisLength', 'Solidity');

% ------------------ 6. Debug Visualization ------------------

if debug
    figure('Name','Colocalization Detection Debug');

    subplot(2,3,1); imshow(ldMaskGreen); title('LDs - Green Channel');
    subplot(2,3,2); imshow(ldMaskRed); title('LDs - Red Channel');
    subplot(2,3,3); imshow(colocMask); title('Raw Intersection (Dilated Masks)');
    subplot(2,3,4); imshow(ldColocMask); title('Filtered Colocalized LDs');
    subplot(2,3,5); imshow(label2rgb(ldColocLabel)); title('Labeled Colocalized LDs');
    subplot(2,3,6); imshowpair(ldMaskGreen, ldMaskRed); title('Green vs Red Overlay');
end

end
