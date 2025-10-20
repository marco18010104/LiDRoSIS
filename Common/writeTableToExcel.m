function writeTableToExcel(T, file, sheet)
% WRITETABLETOEXCEL - Write a MATLAB table to a specific sheet in an Excel file.
%
%   This utility function writes a MATLAB table to a designated worksheet
%   in an Excel `.xlsx` file. If the file does not exist, it will be created.
%   If the specified sheet already exists, it will be overwritten.
%
% INPUTS:
%   T     - (table) A MATLAB table to be written. Must be a valid table object.
%   file  - (char or string) Full path to the Excel file. If the file does not exist,
%           it will be created. Extension must be `.xlsx` or compatible.
%   sheet - (char or string) Name of the sheet to write the table to.
%           If the sheet already exists in the file, its contents will be replaced.
%
% OUTPUT:
%   None (side effect: writes to disk).
%
% EXCEPTIONS:
%   - Will raise an error if `T` is not a table.
%   - Will raise an error if `file` is not writable (e.g., open in Excel).
%   - Will raise an error if `sheet` is invalid (e.g., too long or not supported by Excel).
%
% DEPENDENCIES:
%   - MATLAB built-in `writetable` function.
%
% EXAMPLE:
%   T = table([1;2], ["A";"B"], 'VariableNames', {'ID', 'Label'});
%   writeTableToExcel(T, 'Results.xlsx', 'Summary');
%
%   This will write the table T to the sheet named 'Summary' in Results.xlsx.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Validate inputs
if ~istable(T)
    error('Input T must be a MATLAB table.');
end
if ~ischar(file) && ~isstring(file)
    error('Input "file" must be a character vector or string.');
end
if ~ischar(sheet) && ~isstring(sheet)
    error('Input "sheet" must be a character vector or string.');
end

% Write to Excel
writetable(T, file, 'Sheet', sheet);

end
