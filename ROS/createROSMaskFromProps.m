function [ldMask, ldRGB] = createROSMaskFromProps(ldProps, imageSize)
% CREATEROSEMASKFROMPROPS - Generate binary mask and RGB overlay image from ROS properties.
%
% This function creates a binary mask and a corresponding RGB image overlay by drawing
% filled circles at the centroids of detected ROS objects. The color of each circle encodes
% the size classification of the ROS object based on its area-derived radius.
%
% INPUTS:
%   ldProps    - Struct array with ROS properties, each element must include:
%                - Area: numeric scalar, area of the object in pixels
%                - Centroid: [x, y] coordinates of the object center
%   imageSize  - Size of the image to create [rows, cols], typically the size of the original image
%
% OUTPUTS:
%   ldMask - Logical binary mask of the same size as imageSize, where pixels inside any ROS circle are true
%   ldRGB  - uint8 RGB image (range [0 1]) with colored circles overlaid at ROS centroids:
%            Color coding by radius (r):
%              - r <= 2 : Blue   (small)
%              - 2 < r <= 4 : Green (medium)
%              - r > 4 : Red    (large)
%
% NOTES:
%   - The radius r is calculated as the ceiling of the radius of a circle with equivalent area: r = ceil(sqrt(Area/pi))
%   - The function assumes image coordinates with (1,1) at the top-left.
%
% EXAMPLES:
%   [ldMask, ldRGB] = createROSMaskFromProps(propsROS, [512, 512]);
%   imshow(ldRGB); % Visualize ROS overlay on blank background
%
% EXCEPTIONS:
%   - If ldProps is empty, outputs empty mask and image of zeros.
%   - Assumes valid input properties with positive Areas and Centroids.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Initialize outputs
ldMask = false(imageSize);
ldRGB = zeros([imageSize 3]);

% Create coordinate grids
[xx, yy] = meshgrid(1:imageSize(2), 1:imageSize(1));

for i = 1:numel(ldProps)
    if ldProps(i).Area > 0
        center = round(ldProps(i).Centroid);
        r = ceil(sqrt(ldProps(i).Area / pi));

        % Size classification and color coding
        if r <= 2
            color = [0 0 1];   % Blue - small
        elseif r <= 4
            color = [0 1 0];   % Green - medium
        else
            color = [1 0 0];   % Red - large
        end

        % Create circular mask for this ROS
        mask = (xx - center(1)).^2 + (yy - center(2)).^2 <= r^2;
        ldMask = ldMask | mask;

        % Add color to RGB overlay
        for c = 1:3
            channel = ldRGB(:,:,c);
            channel(mask) = color(c);
            ldRGB(:,:,c) = channel;
        end
    end
end

end
