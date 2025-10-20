function ldByNucleus = groupLDsByNucleus(ldProps, numNuclei)
% GROUPLDSBYNUCLEUS - Group Lipid Droplets (LDs) by assigned nucleus.
%
%   This function organizes detected Lipid Droplets (LDs) into cell-based
%   groups according to their assigned nucleus. It assumes that each LD in the
%   `ldProps` structure array contains the field `AssignedNucleusID`, indicating
%   the nucleus to which it belongs.
%
%   The function returns a cell array of length `numNuclei`, where each element
%   contains a structure array of LDs assigned to that nucleus.
%
% INPUTS:
%   ldProps    : (struct array)
%       Structure array of LDs, each with at least the field:
%           - AssignedNucleusID (int): Index of the nucleus the LD belongs to.
%             Must be in the range [1, numNuclei].
%
%   numNuclei : (integer)
%       Total number of segmented nuclei in the image. Defines the length of
%       the output cell array.
%
% OUTPUT:
%   ldByNucleus : (cell array)
%       A cell array of length `numNuclei`. Each element is a structure array
%       containing all LDs assigned to that nucleus. If no LDs are assigned
%       to a given nucleus, that cell is empty.
%
% EXAMPLE:
%   % Assuming you already have LDs with AssignedNucleusID field
%   groupedLDs = groupLDsByNucleus(ldProps, numel(nucProps));
%   numLDsInNucleus1 = numel(groupedLDs{1});
%
% NOTES:
%   - LDs with `AssignedNucleusID <= 0` or outside valid range are ignored.
%   - The input structure array may come from red, green, coloc, or diffuse LDs.
%
% DEPENDENCIES:
%   None. This is a standalone utility function.
%
% SEE ALSO:
%   assignLDsToNuclei, exportLDDataToExcel
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Initialize cell array for each nucleus
ldByNucleus = cell(numNuclei, 1);

% Group LDs by nucleus
for i = 1:length(ldProps)
    nid = ldProps(i).AssignedNucleusID;
    if nid > 0 && nid <= numNuclei
        ldByNucleus{nid}(end+1) = ldProps(i); %#ok<AGROW>
    end
end

end
