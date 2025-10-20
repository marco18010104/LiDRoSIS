function [labelROS, propsROS] = labellingROS(candidatesROS)
% LABELLINGROS - Label and extract properties of ROS candidates in a binary mask.
%
% This function processes a binary mask representing candidate ROS (Reactive Oxygen Species)
% regions, labels connected components, and extracts relevant morphological properties for
% each detected object.
%
% INPUT:
%   candidatesROS - Binary image (logical or numeric) where ROS candidate regions are true/nonzero.
%
% OUTPUT:
%   labelROS  - Labeled image (uint16 or similar), where each connected component (ROS candidate)
%               has a unique integer label.
%   propsROS  - Struct array with morphological properties of each labeled ROS object, including:
%       - Centroid: [x, y] coordinates of the object center.
%       - Area: Number of pixels in the object.
%       - Eccentricity: Eccentricity of the ellipse that has the same second-moments as the object.
%       - BoundingBox: [x, y, width, height] bounding box around the object.
%       - PixelIdxList: Linear indices of pixels belonging to the object.
%       - EquivDiameter: Diameter of a circle with the same area as the object.
%       - Perimeter: Perimeter length of the object.
%       - MajorAxisLength: Length of the major axis of the ellipse.
%       - MinorAxisLength: Length of the minor axis of the ellipse.
%       - Solidity: Ratio of the object area to the convex hull area.
%       - Extent: Ratio of the object area to the bounding box area.
%       - ConvexArea: Number of pixels in the convex hull of the object.
%
% EXCEPTIONS:
%   - The input should be a binary mask; behavior with non-binary input is undefined.
%
% EXAMPLE:
%   bw = imread('ros_candidates.png') > 0; % binary mask
%   [labels, props] = labellingROS(bw);
%   imshow(label2rgb(labels)); % visualize labeled regions
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

labelROS = bwlabel(candidatesROS);
propsROS = regionprops(labelROS, ...
    'Centroid', 'Area', 'Eccentricity', 'BoundingBox', 'PixelIdxList', ...
    'EquivDiameter', 'Perimeter', 'MajorAxisLength', 'MinorAxisLength', ...
    'Solidity', 'Extent', 'ConvexArea');

end
