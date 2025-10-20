function ldProps = assignLDsToNuclei(ldProps, nucProps)
% ASSIGNLDSTONUCLEI - Assigns each Lipid Droplet (LD) to its nearest nucleus.
%
% This function calculates the Euclidean distance between the centroids of each LD and all
% detected nuclei. It assigns each LD to the nucleus with the minimum distance, storing the index
% of the corresponding nucleus in a new field `AssignedNucleusID` inside the `ldProps` structure.
%
% INPUTS:
%   ldProps  : (1xN struct array)
%       Structure array containing properties of detected Lipid Droplets.
%       Must contain the field:
%           - Centroid : [x, y] coordinates of the LD center.
%
%   nucProps : (1xM struct array)
%       Structure array with properties of segmented nuclei.
%       Must contain the field:
%           - Centroid : [x, y] coordinates of each nucleus.
%
% OUTPUT:
%   ldProps  : (1xN struct array)
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
%   ldProps = regionprops(ldMask, 'Centroid', 'Area');
%   nucProps = regionprops(nucMask, 'Centroid');
%   ldProps = assignLDsToNuclei(ldProps, nucProps);
%
%   % Access assignment:
%   for i = 1:numel(ldProps)
%       fprintf('LD #%d assigned to Nucleus #%d\n', i, ldProps(i).AssignedNucleusID);
%   end
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

    % Return empty if no LDs or nuclei are provided
    if isempty(ldProps) || isempty(nucProps)
        ldProps = [];
        return;
    end

    % Extract centroids into Nx2 matrices
    ldCentroids = reshape([ldProps.Centroid], 2, []).';      % N_ld x 2
    nucCentroids = reshape([nucProps.Centroid], 2, []).';    % N_nuc x 2

    % Assign nearest nucleus for each LD
    for i = 1:size(ldCentroids, 1)
        distances = sqrt(sum((nucCentroids - ldCentroids(i,:)).^2, 2)); % Euclidean distance
        [~, minIdx] = min(distances);  % Index of closest nucleus
        ldProps(i).AssignedNucleusID = minIdx;
    end
end
