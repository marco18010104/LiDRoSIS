function propsROS = assignROSToNuclei(propsROS, nucProps)
% ASSIGNROSTONUCLEI - Assigns each Reactive Oxigen Species (ROS) to its nearest nucleus.
%
% This function calculates the Euclidean distance between the centroids of each ROS and all
% detected nuclei. It assigns each ROS to the nucleus with the minimum distance, storing the index
% of the corresponding nucleus in a new field `AssignedNucleusID` inside the `propsROS` structure.
%
% INPUTS:
%   propsROS  : (1xN struct array)
%       Structure array containing properties of detected ROS.
%       Must contain the field:
%           - Centroid : [x, y] coordinates of the ROS center.
%
%   nucProps : (1xM struct array)
%       Structure array with properties of segmented nuclei.
%       Must contain the field:
%           - Centroid : [x, y] coordinates of each nucleus.
%
% OUTPUT:
%   propsROS  : (1xN struct array)
%       The same input struct array with an added field:
%           - AssignedNucleusID : Index of the closest nucleus in `nucProps`.
%
% NOTES:
%   - If either input is empty, the output will be an empty struct (`[]`).
%   - Ties in distance (rare due to floating-point precision) will default to the first minimal value.
%
% DEPENDENCIES:
%   - None (uses only base MATLAB functions).
%
% EXAMPLE USAGE:
%   propsROS = regionprops(maskROS, 'Centroid', 'Area');
%   nucProps = regionprops(nucMask, 'Centroid');
%   propsROS = assignROSToNuclei(propsROS, nucProps);
%
%   % Access assignment:
%   for i = 1:numel(propsROS)
%       fprintf('ROS #%d assigned to Nucleus #%d\n', i, propsROS(i).AssignedNucleusID);
%   end
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.
    
    % Return empty if no LDs or nuclei are provided
    if isempty(propsROS) || isempty(nucProps)
        propsROS = [];
        return;
    end
    
    % Extract centroids into Nx2 matrices
    centroidsROS = reshape([propsROS.Centroid], 2, []).';      % N_ld x 2
    nucCentroids = reshape([nucProps.Centroid], 2, []).';    % N_nuc x 2
    
    % Assign nearest nucleus for each ROS
    for i = 1:size(centroidsROS, 1)
        distances = sqrt(sum((nucCentroids - centroidsROS(i,:)).^2, 2)); % Euclidean distance
        [~, minIdx] = min(distances); % Index of closest nucleus
        propsROS(i).AssignedNucleusID = minIdx;
    end
end
