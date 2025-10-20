function [ldMask, ldRGB] = createLDMaskFromProps(ldProps, imageSize)
% CREATELDMASKFROMPROPS - Generate binary and RGB masks from Lipid Droplet (LD) properties.
%
%   This function creates a binary mask and a color-coded RGB image of LDs
%   based on their geometric properties. Each LD is represented as a filled
%   circle centered at its centroid, with a radius derived from its area.
%   The color encoding reflects the relative size of the LD:
%       - Blue   : Small LDs (r ≤ 2 px)
%       - Green  : Medium LDs (2 < r ≤ 4 px)
%       - Red    : Large LDs (r > 4 px)
%
% INPUTS:
%   ldProps   : (struct array)
%       Structure array with LD properties, typically from `regionprops`,
%       containing at least the fields:
%           - Centroid : [x, y] coordinates of LD center
%           - Area     : Scalar area of each LD (used to estimate radius)
%
%   imageSize : (1x2 integer array)
%       Size of the image [rows, cols] used to create the output masks.
%       Should match the dimensions of the original image.
%
% OUTPUTS:
%   ldMask : (logical array)
%       Binary image (same size as input) where pixels inside any LD are set to 1.
%
%   ldRGB  : (MxNx3 double array)
%       RGB image with circular LDs color-coded by size class:
%           - Blue   : Small (r ≤ 2 px)
%           - Green  : Medium (2 < r ≤ 4 px)
%           - Red    : Large (r > 4 px)
%
% DEPENDENCIES:
%   - meshgrid (built-in)
%
% EXAMPLE USAGE:
%   img = imread('exampleLDImage.png');
%   ldProps = regionprops(ldBinaryMask, 'Centroid', 'Area');
%   [ldMask, ldRGB] = createLDMaskFromProps(ldProps, size(img(:,:,1)));
%   imshow(ldRGB);      % visualize the RGB mask
%   imshow(ldMask);     % visualize the binary LD mask
%
% NOTES:
%   - The radius is computed as: r = ceil(sqrt(Area / π))
%   - Overlapping LDs are combined in the binary mask (`ldMask`), but retain
%     individual color representation in the RGB image.
%   - The RGB image has double values in range [0,1]; scale as needed for display.
%
% SEE ALSO:
%   regionprops, bwlabel, labeloverlay

% Pre-allocate binary and RGB masks
ldMask = false(imageSize);
ldRGB = zeros([imageSize 3]);

% Pre-compute coordinate grid
[xx, yy] = meshgrid(1:imageSize(2), 1:imageSize(1));

% Loop through all LDs
for i = 1:numel(ldProps)
    if ldProps(i).Area > 0
        % Get centroid and radius from area
        center = round(ldProps(i).Centroid);
        r = ceil(sqrt(ldProps(i).Area / pi));

        % Assign color based on size
        if r <= 2
            color = [0 0 1];   % Small = Blue
        elseif r <= 4
            color = [0 1 0];   % Medium = Green
        else
            color = [1 0 0];   % Large = Red
        end

        % Create circular mask
        mask = (xx - center(1)).^2 + (yy - center(2)).^2 <= r^2;
        ldMask = ldMask | mask;  % Update binary mask

        % Update RGB image
        for c = 1:3
            channel = ldRGB(:,:,c);
            channel(mask) = color(c);
            ldRGB(:,:,c) = channel;
        end
    end
end

end
