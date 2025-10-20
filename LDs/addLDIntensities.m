function ldProps = addLDIntensities(ldProps, imgRGB, colocMask)
% ADDLDINTENSITIES - Adds mean intensity values for red and green channels to each Lipid Droplet (LD).
%
% This function computes the average pixel intensity of each LD region (based on `PixelIdxList`)
% from the red and green channels of the input RGB image. If a third argument `colocMask` is
% provided, it also computes the mean value of that mask over the LD pixels, typically used
% to indicate colocalization intensity (e.g., overlap of green/red).
%
% INPUTS:
%   ldProps   : (1xN struct array)
%       Structure array containing LD region properties (must include `PixelIdxList`).
%
%   imgRGB    : (HxWx3 numeric array)
%       The original RGB image from which intensity values are extracted.
%       Assumes:
%           - Channel 1: Red (e.g., Nile Red for hydrophobic LD core)
%           - Channel 2: Green (e.g., BODIPY for polar lipid content)
%
%   colocMask : (HxW logical or numeric matrix, optional)
%       Optional mask (same size as image) representing colocalized LD regions.
%       When provided, adds a field `MeanIntensityColoc` to each LD.
%       If omitted, this field is set to `NaN`.
%
% OUTPUT:
%   ldProps   : (1xN struct array)
%       Same as input, with added scalar fields per LD:
%           - MeanIntensityRed     : Mean intensity in the red channel
%           - MeanIntensityGreen   : Mean intensity in the green channel
%           - MeanIntensityColoc   : (if applicable) Mean of colocMask over LD pixels
%
% EXCEPTIONS & EDGE CASES:
%   - LDs with empty PixelIdxList are skipped (intensities not computed).
%   - colocMask can be logical or numeric. It will be cast to `double` internally.
%
% DEPENDENCIES:
%   - None (uses only base MATLAB functions).
%
% EXAMPLE USAGE:
%   img = imread('image.tif');
%   ldProps = regionprops(ldMask, 'PixelIdxList', 'Centroid');
%   colocMask = ldMaskRed & ldMaskGreen;
%   ldProps = addLDIntensities(ldProps, img, colocMask);
%
%   fprintf('LD#1 red intensity: %.2f\n', ldProps(1).MeanIntensityRed);
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

    % Extract color channels
    red   = imgRGB(:,:,1);
    green = imgRGB(:,:,2);

    % Loop over each LD and compute intensity values
    for k = 1:numel(ldProps)
        pixels = ldProps(k).PixelIdxList;

        if isempty(pixels)
            continue;
        end

        % Compute channel intensities over LD region
        ldProps(k).MeanIntensityRed   = mean(red(pixels));
        ldProps(k).MeanIntensityGreen = mean(green(pixels));

        % Optional: mean intensity over colocMask
        if nargin > 2 && ~isempty(colocMask)
            colocMaskNumeric = double(colocMask);
            ldProps(k).MeanIntensityColoc = mean(colocMaskNumeric(pixels));
        else
            ldProps(k).MeanIntensityColoc = NaN;
        end
    end
end
