function ROSByNucleus = groupROSByNucleus(propsROS, numNuclei)
% GROUPROSBYNUCLEUS - Group Reactive Oxigen Species (ROS) by assigned nucleus.
%
%   This function organizes detected ROS into cell-based groups according to 
%   their assigned nucleus. It assumes that each ROS in the `ldProps` structure 
%   array contains the field `AssignedNucleusID`, indicating the nucleus to which 
%   it belongs.
%
%   The function returns a cell array of length `numNuclei`, where each element
%   contains a structure array of ROS assigned to that nucleus.
%
% INPUTS:
%   propsROS    : (struct array)
%       Structure array of ROS, each with at least the field:
%           - AssignedNucleusID (int): Index of the nucleus the ROS belongs to.
%             Must be in the range [1, numNuclei].
%
%   numNuclei : (integer)
%       Total number of segmented nuclei in the image. Defines the length of
%       the output cell array.
%
% OUTPUT:
%   ROSByNucleus : (cell array)
%       A cell array of length `numNuclei`. Each element is a structure array
%       containing all ROS assigned to that nucleus. If no ROS are assigned
%       to a given nucleus, that cell is empty.
%
% EXAMPLE:
%   % Assuming you already have ROS with AssignedNucleusID field
%   groupedROS = groupROSByNucleus(propsROS, numel(nucProps));
%   numROSInNucleus1 = numel(groupedROS{1});
%
% NOTES:
%   - ROS with `AssignedNucleusID <= 0` or outside valid range are ignored.
%   - The input structure array may come from ROS or diffuse ROS.
%
% DEPENDENCIES:
%   None. This is a standalone utility function.
%
% SEE ALSO:
%   assignROSToNuclei, exportROSDataToExcel
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Initialize cell array for each nucleus
ROSByNucleus = cell(numNuclei, 1);

% Group ROS by nucleus
for i = 1:length(propsROS)
    nid = propsROS(i).AssignedNucleusID;
    if nid > 0 && nid <= numNuclei
        ROSByNucleus{nid}(end+1) = propsROS(i); %#ok<AGROW>
    end
end

end
