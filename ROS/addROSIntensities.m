function rosProps = addROSIntensities(rosProps, imgRGB)
% ADDROSINTENSITIES - Adds mean green channel intensity to each ROS object.
%
% PURPOSE:
%   Computes and assigns the mean intensity of the green channel within each
%   reactive oxygen species (ROS) region defined in rosProps.
%
% INPUTS:
%   rosProps - Struct array with ROS properties obtained from regionprops.
%              Must include field 'PixelIdxList' indicating pixel indices of each ROS.
%   imgRGB   - RGB image matrix where the green channel contains ROS fluorescence signal.
%
% OUTPUT:
%   rosProps - Same struct array augmented with a new field:
%              'MeanIntensityGreen' containing the average green intensity of each ROS.
%
% NOTES:
%   - If 'PixelIdxList' is empty for a ROS, the mean intensity is skipped.
%   - The input image is assumed to be in standard uint8 or double format; intensity
%     values are used as-is.
%
% EXAMPLE:
%   rosProps = regionprops(binaryMask, 'PixelIdxList');
%   imgRGB = imread('ros_image.png');
%   rosProps = addROSIntensities(rosProps, imgRGB);
%   disp([rosProps.MeanIntensityGreen]);
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

green = imgRGB(:,:,2); % Extract green channel

for k = 1:numel(rosProps)
    pixels = rosProps(k).PixelIdxList;
    if isempty(pixels)
        continue; % Skip if no pixels
    end
    % Compute mean intensity of green channel within ROS region
    rosProps(k).MeanIntensityGreen = mean(green(pixels));
end

end
