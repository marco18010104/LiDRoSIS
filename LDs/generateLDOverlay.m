function overlay = generateLDOverlay(img, ldLabel)
% generateLDOverlay - Generates a color overlay of labeled Lipid Droplets (LDs) on an image.
%
% PURPOSE:
%   This function creates a semi-transparent color overlay that highlights segmented Lipid Droplets (LDs),
%   labeled in `ldLabel`, on top of the original image `img`. It is useful for visualizing segmentation results
%   and confirming label assignments.
%
% INPUTS:
%   img      : MxNx3 uint8 RGB image or MxN grayscale image (original microscopy image)
%              - This image serves as the background for overlay.
%
%   ldLabel  : MxN matrix of type double or uint32, containing integer labels for each detected LD.
%              - Background should be 0.
%              - Each nonzero pixel represents a different LD object.
%
% OUTPUT:
%   overlay  : MxNx3 uint8 RGB image.
%              - The original image with colored LD labels overlaid using a perceptually uniform colormap.
%
% RAISES:
%   This function does not raise exceptions explicitly, but will error if:
%     - `img` and `ldLabel` have mismatched spatial dimensions.
%     - `ldLabel` contains NaNs or negative values.
%
% NOTES:
%   - Uses the `parula` colormap to assign unique colors to each LD label.
%   - The transparency is set to 50% for easy visualization of both LDs and underlying structures.
%
% EXAMPLE:
%   % Assume `imgRGB` is a 512x512x3 RGB image, and `ldLabel` is a 512x512 label matrix of LDs
%   overlayImage = generateLDOverlay(imgRGB, ldLabel);
%   imshow(overlayImage);
%   title('Lipid Droplet Segmentation Overlay');
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Ensure a valid number of labels to generate a colormap
numLabels = max(ldLabel(:));

% Generate a distinct colormap with one color per label
cmap = parula(numLabels);

% Create an overlay image by blending the labels over the original image
overlay = labeloverlay(img, ldLabel, ...
    'Colormap', cmap, ...
    'Transparency', 0.5);

end
