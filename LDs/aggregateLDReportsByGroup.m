function aggregateLDReportsByGroup(rootDir)
% AGGREGATELDREPORTSBYGROUP Aggregates Lipid Droplet (LD) reports by experimental group and dose.
%
%   This function scans recursively through all subfolders within the specified root directory,
%   identifying experimental groups based on folder hierarchy. For each group, it collects all
%   LD report files matching the pattern '*_LDReport.xlsx', reads their 'GlobalMetrics' sheet,
%   and groups them by dose. It then aggregates the data per group and dose, saving combined Excel
%   files with aggregated 'GlobalMetrics' tables. It also generates boxplots (not included here)
%   for the grouped data.
%
% USAGE:
%   aggregateLDReportsByGroup('C:\Data\Experiment');
%
% INPUT:
%   rootDir (string) - Full path to the root directory containing LD report subfolders.
%
% OUTPUT:
%   None (writes aggregated Excel files to rootDir with naming pattern 'Aggregated_<GroupName>_LD.xlsx').
%
% EXCEPTIONS:
%   Throws an error if no LD report files are found under rootDir.
%
% WARNINGS:
%   - Ignores report files with unreadable or missing 'GlobalMetrics' sheets.
%   - Skips files without a numeric 'Dose' entry.
%   - Warns if folder structure does not allow experimental group identification.
%
% NOTES:
%   - Experimental groups are inferred from the folder path components (last 4 to 1 folders).
%   - Dose values are normalized to strings in the format '<value>Gy'.
%
% EXAMPLE:
%   rootDir = 'C:\Users\Researcher\LD_Data';
%   aggregateLDReportsByGroup(rootDir);
%   % This will create aggregated Excel reports per group and dose under rootDir.
%
% DEPENDENCIES:
%   Requires MATLAB functions: readcell, writetable, containers.Map, dir, warning, error.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Find all LD report Excel files recursively
files = dir(fullfile(rootDir, '**', '*_LDReport.xlsx'));
if isempty(files)
    error('No LD report files (*.xlsx) found under the directory: %s', rootDir);
end

fprintf('🔎 Aggregating LD reports by experimental group...\n');

% Initialize container map to group files by experimental group and dose
groupDoseMap = containers.Map();

for i = 1:numel(files)
    fpath = fullfile(files(i).folder, files(i).name);

    % Extract experimental group key from folder path
    tokens = split(fpath, filesep);
    if numel(tokens) < 5
        warning('Path %s too short to define experimental group. File ignored.', fpath);
        continue;
    end
    % Group key composed by joining last 4 folder names before file
    groupKey = strjoin(tokens(end-4:end-1), '_');

    % Attempt to read 'GlobalMetrics' sheet
    try
        raw = readcell(fpath, 'Sheet', 'GlobalMetrics');
    catch
        warning('Failed to read GlobalMetrics sheet in file %s. File ignored.', fpath);
        continue;
    end

    % Find 'Dose' row in the first column
    idxDose = find(strcmpi(raw(:,1), 'Dose'), 1);
    if isempty(idxDose)
        warning('Dose entry missing in GlobalMetrics sheet of file %s. File ignored.', fpath);
        continue;
    end

    doseValRaw = raw{idxDose, 2};
    doseNum = str2double(string(doseValRaw));
    if isnan(doseNum)
        warning('Dose value is not numeric in file %s. File ignored.', fpath);
        continue;
    end
    doseStr = sprintf('%gGy', doseNum);

    % Initialize or update group-dose map structure
    if ~isKey(groupDoseMap, groupKey)
        groupDoseMap(groupKey) = containers.Map();
    end
    doseMap = groupDoseMap(groupKey);

    if ~isKey(doseMap, doseStr)
        doseMap(doseStr) = {};
    end
    doseList = doseMap(doseStr);
    doseList{end+1} = fpath;
    doseMap(doseStr) = doseList;
    groupDoseMap(groupKey) = doseMap;
end

% Write aggregated Excel reports for each experimental group
for groupNameCell = keys(groupDoseMap)
    groupName = groupNameCell{1};
    doseMap = groupDoseMap(groupName);

    fprintf('📦 Processing group "%s":\n', groupName);

    outFile = fullfile(rootDir, ['Aggregated_' groupName '_LD.xlsx']);
    if isfile(outFile)
        delete(outFile); % Remove existing output file to avoid conflicts
    end

    for doseCell = keys(doseMap)
        dose = doseCell{1};
        fileList = doseMap(dose);

        fprintf('  → Dose %s (%d files)\n', dose, numel(fileList));

        allGlobals = table();

        for iFile = 1:numel(fileList)
            f = fileList{iFile};
            try
                raw = readcell(f, 'Sheet', 'GlobalMetrics');
                G = rawToStructArray(raw);
                [~, fname, ext] = fileparts(f);
                G.ImageName = repmat(string([fname ext]), height(G), 1);
                allGlobals = [allGlobals; G];
            catch ME
                warning('Failed to read or process file %s: %s', f, ME.message);
            end
        end

        % Write aggregated GlobalMetrics table for the current dose
        try
            writetable(allGlobals, outFile, 'Sheet', [dose '_GlobalMetrics']);
        catch ME
            warning('Failed to write aggregated data to %s: %s', outFile, ME.message);
        end
    end

    fprintf('✔ Aggregation completed for group "%s": %s\n', groupName, outFile);
end
end


function T = rawToStructArray(raw)
% RAWTOSTRUCTARRAY Converts raw cell array from readcell into a single-row table.
%
%   Converts a Nx2 cell array where first column contains field names and second column values,
%   into a single-row MATLAB table with valid field names.
%
% INPUT:
%   raw (cell Nx2) - Raw cell data from reading an Excel sheet.
%
% OUTPUT:
%   T (table) - Single-row table with fields as variable names.
%
% EXAMPLE:
%   raw = {'Dose', 5; 'CellLine', 'A549'};
%   T = rawToStructArray(raw);
%   % T.Dose -> 5
%   % T.CellLine -> 'A549'

keys = raw(:,1);
vals = raw(:,2);
s = struct();
for k = 1:numel(keys)
    if ischar(keys{k}) || isstring(keys{k})
        key = matlab.lang.makeValidName(keys{k});
        s.(key) = vals{k};
    end
end
T = struct2table(s, 'AsArray', true);
end
