function aggregateROSReportsByGroup(rootDir)
% AGGREGATEROSREPORTSBYGROUP - Aggregate ROS Excel reports by experimental group and dose.
%
% This function recursively scans a root directory for ROS report Excel files
% named '*_ROSReport.xlsx'. It groups these reports by experimental group (derived
% from directory structure) and by radiation dose (extracted from the 'GlobalMetrics'
% sheet). For each group and dose, it aggregates the global metrics from all reports
% into a single Excel file with separate sheets per dose.
%
% INPUT:
%   rootDir - (string) Root directory path containing subdirectories with ROS report files.
%
% OUTPUT:
%   None (writes aggregated Excel files for each experimental group inside rootDir)
%
% BEHAVIOR:
%   - Experimental groups are inferred from directory structure (last 4 folder levels).
%   - Doses are normalized (e.g., "10 Gy" -> "10Gy") for grouping.
%   - Aggregation collects all 'GlobalMetrics' tables from each file for given group/dose.
%   - Warnings are issued if files are unreadable or metadata missing.
%
% EXCEPTIONS:
%   Throws error if no '*_ROSReport.xlsx' files are found in rootDir or subfolders.
%
% EXAMPLE:
%   aggregateROSReportsByGroup('C:\Data\ROSResults')
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Search recursively for all ROS report files
files = dir(fullfile(rootDir, '**', '*_ROSReport.xlsx'));
if isempty(files)
    error('No *_ROSReport.xlsx files found in directory %s', rootDir);
end

fprintf('🔎 Aggregating ROS reports by experimental group...\n');

% Map to group file paths by experimental group key and dose key
groupDoseMap = containers.Map();

for i = 1:numel(files)
    fpath = fullfile(files(i).folder, files(i).name);

    % Extract relative folder tokens for group identification
    tokens = split(fpath, filesep);
    if numel(tokens) < 5
        warning('Path too short to define experimental group: %s. Skipping.', fpath);
        continue;
    end
    % Group key from last 4 folders before filename (e.g., parent dirs)
    groupKey = strjoin(tokens(end-4:end-1), '_');

    % Read 'GlobalMetrics' sheet to find dose
    try
        raw = readcell(fpath, 'Sheet', 'GlobalMetrics');
    catch
        warning('Failed reading GlobalMetrics sheet in %s. Skipping.', fpath);
        continue;
    end

    % Find row with label 'Dose'
    idxDose = find(strcmpi(raw(:,1), 'Dose'), 1);
    if isempty(idxDose)
        warning('No "Dose" row found in GlobalMetrics of %s. Skipping.', fpath);
        continue;
    end

    % Parse numeric dose value (handle formats like "10 Gy", "2Gy", etc)
    doseValRaw = string(raw{idxDose, 2});
    doseNum = sscanf(doseValRaw, '%f');
    if isempty(doseNum) || isnan(doseNum)
        warning('Non-numeric dose value in %s: %s. Skipping.', fpath, doseValRaw);
        continue;
    end
    doseStr = sprintf('%gGy', doseNum);

    % Initialize dose map for group if missing
    if ~isKey(groupDoseMap, groupKey)
        groupDoseMap(groupKey) = containers.Map();
    end
    doseMap = groupDoseMap(groupKey);

    % Append file path to list for this dose
    if ~isKey(doseMap, doseStr)
        doseMap(doseStr) = {};
    end
    doseList = doseMap(doseStr);
    doseList{end+1} = fpath;
    doseMap(doseStr) = doseList;
    groupDoseMap(groupKey) = doseMap;
end

% For each group and dose, aggregate GlobalMetrics tables and save to Excel
for groupName = keys(groupDoseMap)
    groupName = groupName{1};
    doseMap = groupDoseMap(groupName);

    fprintf('📦 Group "%s":\n', groupName);

    outFile = fullfile(rootDir, ['Aggregated_' groupName '_ROS.xlsx']);
    if isfile(outFile)
        delete(outFile);
    end

    for dose = keys(doseMap)
        dose = dose{1};
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
                warning('Failed to read GlobalMetrics from %s: %s', f, ME.message);
            end
        end

        % Write aggregated GlobalMetrics to output file, sheet named after dose
        try
            writetable(allGlobals, outFile, 'Sheet', [dose '_GlobalMetrics']);
        catch ME
            warning('Failed writing GlobalMetrics to %s: %s', outFile, ME.message);
        end
    end

    fprintf('✔ Aggregation for group "%s" completed: %s\n', groupName, outFile);
end

end

function T = rawToStructArray(raw)
% RAWTOSTRUCTARRAY - Convert a two-column cell array of keys and values to a single-row table.
%
% INPUT:
%   raw - cell array Nx2, with keys in first column and values in second.
%
% OUTPUT:
%   T - table with fields named after keys and corresponding values.
%
% This helper is used to convert readcell output of GlobalMetrics into a table.

keys = raw(:,1);
vals = raw(:,2);
s = struct();
for k = 1:numel(keys)
    if ischar(keys{k}) || isstring(keys{k})
        key = matlab.lang.makeValidName(keys{k});
        s.(key) = vals{k};
    end
end
T = struct2table(s, 'AsArray', true);  % ensures one-row table
end
