function [ldLabel, ldProps] = labelLDs(ldCandidates)
% LABELLDS - Label connected LD regions and extract geometric properties.
%
%   This function takes a binary mask of candidate Lipid Droplet (LD) regions,
%   labels the connected components, and extracts their geometric and shape
%   descriptors using `regionprops`.
%
%   The output includes:
%     - A labeled image (`ldLabel`) where each connected LD has a unique label.
%     - A structure array (`ldProps`) with region properties for each LD.
%
% INPUT:
%   ldCandidates : (logical array)
%       Binary image where pixels belonging to potential LDs are set to true (1).
%       Must be a 2D logical matrix.
%
% OUTPUT:
%   ldLabel : (uint16 array)
%       Labeled image where each connected LD candidate has a unique integer label.
%       Background pixels are 0. The label values range from 1 to N, where N is
%       the number of detected LD regions.
%
%   ldProps : (struct array)
%       Structure array of region properties for each labeled LD, with fields:
%           - Centroid          : [x, y] coordinates of the LD center
%           - Area              : Number of pixels in the region
%           - Eccentricity      : Ellipse eccentricity (0 = circle, 1 = line)
%           - BoundingBox       : Bounding rectangle [x, y, width, height]
%           - PixelIdxList      : Linear indices of pixels in the LD
%           - EquivDiameter     : Diameter of a circle with the same area
%           - Perimeter         : Perimeter length of the LD
%           - MajorAxisLength   : Major axis length of the ellipse fit
%           - MinorAxisLength   : Minor axis length of the ellipse fit
%           - Solidity          : Area / Convex hull area
%           - Extent            : Area / BoundingBox area
%           - ConvexArea        : Area of the convex hull around the LD
%
% DEPENDENCIES:
%   - bwlabel
%   - regionprops
%
% EXAMPLE USAGE:
%   binaryMask = imread('LD_mask.png') > 0;
%   [labelImage, properties] = labelLDs(binaryMask);
%   imshow(label2rgb(labelImage));  % Visualize labeled LDs
%
% NOTES:
%   - This function assumes a clean binary mask as input. For best results, ensure
%     preprocessing steps such as noise removal or morphological filtering are applied.
%   - Output `ldProps` can be passed to `assignLDsToNuclei`, `addLDIntensities`, or
%     exported to Excel using `exportLDDataToExcel`.
%
% SEE ALSO:
%   regionprops, bwlabel, assignLDsToNuclei, detectLDsRed, detectLDsGreen
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Validate input
if ~islogical(ldCandidates)
    error('Input ldCandidates must be a logical array (binary image).');
end

% Label connected components
ldLabel = bwlabel(ldCandidates);

% Extract region properties
ldProps = regionprops(ldLabel, ...
    'Centroid', 'Area', 'Eccentricity', 'BoundingBox', 'PixelIdxList', ...
    'EquivDiameter', 'Perimeter', 'MajorAxisLength', 'MinorAxisLength', ...
    'Solidity', 'Extent', 'ConvexArea');

end
