function exportROSDataToExcel(name, img, nucProps, propsROS, byNucleusROS, ...
      diffuseROSProps, diffuseROSbyNucleus, imageInfo, outFolder)
% EXPORTROSDATATOEXCEL - Export comprehensive ROS analysis data to an Excel report.
%
% This function compiles global, per-nucleus, and per-ROS-object metrics from
% reactive oxygen species (ROS) detection and writes the data into an Excel file.
% It handles both "normal" ROS and diffuse ROS subsets, merges their properties,
% calculates summary statistics, and organizes the data into meaningful sheets.
%
% INPUTS:
%   name              - (string) base filename/identifier for this image/report.
%   img               - (HxWx3 uint8/double) original RGB image (currently unused).
%   nucProps          - (struct array) nuclei properties, must contain 'Area' field.
%   propsROS          - (struct array/table/cell) properties of detected ROS objects.
%   byNucleusROS      - (cell array) ROS objects grouped per nucleus.
%   diffuseROSProps   - (struct array/table/cell) properties of detected diffuse ROS objects.
%   diffuseROSbyNucleus - (cell array) diffuse ROS objects grouped per nucleus.
%   imageInfo         - (table) metadata with variables: CellLine, Dose, Nanoparticles, etc.
%   outFolder         - (string) folder path to save the Excel report.
%
% OUTPUTS:
%   None (writes an Excel file named '<name>_ROSReport.xlsx' in outFolder)
%
% EXCEPTIONS:
%   Errors may occur if:
%     - outFolder does not exist or is not writable.
%     - imageInfo lacks expected metadata fields.
%
% EXAMPLES:
%   exportROSDataToExcel('sample1', img, nucProps, propsROS, byNucROS, diffuseProps, diffuseByNuc, imageInfo, 'C:\Results')
%
% NOTES:
%   - Input propsROS and diffuseROSProps may be tables, cells, or structs; the function converts them internally.
%   - Calculates metrics like counts, areas, intensities, eccentricities, and fluorescence sums.
%   - Ensures output tables have consistent columns and reorder columns for readability.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Build full filename for Excel output
filename = fullfile(outFolder, [name '_ROSReport.xlsx']);

numCells = numel(nucProps);
nucAreas = [nucProps.Area]';
meanNucArea = mean(nucAreas);

% Helper: Convert input to struct array if needed
function s = ensureStructArray(x)
    if istable(x)
        s = table2struct(x);
    elseif iscell(x)
        s = [x{:}];
    else
        s = x;
    end
end

propsROS = ensureStructArray(propsROS);
diffuseROSProps = ensureStructArray(diffuseROSProps);

% Helper: Compute summary metrics for ROS sets
function R = calcMetrics(p)
    if isempty(p)
        R = struct('count', 0, 'totalArea', 0, 'meanArea', NaN, ...
                   'meanEcc', NaN, 'meanEquivDiameter', NaN, ...
                   'totalFluor', NaN, 'meanIntensity', NaN, 'stdIntensity', NaN);
        return
    end
    areaVals = [p.Area];
    eccVals = [p.Eccentricity];
    equivDiameterVals = [p.EquivDiameter];
    intensityVals = [p.MeanIntensityGreen];

    R.count = numel(p);
    R.totalArea = sum(areaVals);
    R.meanArea = mean(areaVals);
    R.meanEcc = mean(eccVals);
    R.meanEquivDiameter = mean(equivDiameterVals);
    R.meanIntensity = mean(intensityVals);
    R.stdIntensity = std(intensityVals);
    R.totalFluor = sum(areaVals .* intensityVals);
end

R = calcMetrics(propsROS);
D = calcMetrics(diffuseROSProps);

% Compute ROS counts per nucleus
if isempty(byNucleusROS)
    numROSperNuc = zeros(numCells,1);
else
    numROSperNuc = cellfun(@numel, byNucleusROS(:));
end
if isempty(diffuseROSbyNucleus)
    numDiffperNuc = zeros(numCells,1);
else
    numDiffperNuc = cellfun(@numel, diffuseROSbyNucleus(:));
end

meanROSPerNucleus = mean(numROSperNuc);
meanDiffuseROSPerNucleus = mean(numDiffperNuc);

% --------- Global metrics sheet ---------
globalData = {
    'Filename', name;
    'Cell Line', imageInfo.CellLine{1};
    'Dose', imageInfo.Dose{1};
    'NPs', imageInfo.Nanoparticles{1};
    'Num Nuclei', numCells;
    'Mean Nucleus Area [px]', meanNucArea;
    'Num ROS', R.count;
    'Num ROS Diffuse', D.count;
    'Mean ROS per Nucleus', meanROSPerNucleus;
    'Mean ROS Diffuse per Nucleus', meanDiffuseROSPerNucleus;
    'Mean ROS Area', R.meanArea;
    'Mean ROS Area Diffuse', D.meanArea;
    'Total ROS Area', R.totalArea;
    'Total ROS Area Diffuse', D.totalArea;
    'Mean ROS Intensity', R.meanIntensity;
    'Std ROS Intensity', R.stdIntensity;
    'Mean ROS Diffuse Intensity', D.meanIntensity;
    'Std ROS Diffuse Intensity', D.stdIntensity;
    'Total ROS Fluorescence', R.totalFluor;
    'Total ROS Diffuse Fluorescence', D.totalFluor;
};
writecell(globalData, filename, 'Sheet', 'GlobalMetrics');

% --------- Nucleus metrics sheet ---------
nucleusTable = table((1:numCells)', nucAreas, numROSperNuc, numDiffperNuc, ...
    'VariableNames', {'NucleusID', 'NucleusArea', 'NumROS', 'NumROS_Diffuse'});
writetable(nucleusTable, filename, 'Sheet', 'NucleusMetrics');

% --------- ROS metrics sheet helpers ---------
function simpleProps = keepSimpleFields(propsROS)
    if isempty(propsROS)
        simpleProps = propsROS;
        return
    end
    fNames = fieldnames(propsROS);
    toKeep = false(size(fNames));
    for i = 1:length(fNames)
        val = propsROS(1).(fNames{i});
        if (isscalar(val) && (isnumeric(val) || islogical(val))) || ischar(val) || isstring(val)
            toKeep(i) = true;
        end
    end
    simpleProps = rmfield(propsROS, fNames(~toKeep));
end

function tbl = prepareROSTable(propsROS)
    if isempty(propsROS)
        tbl = table();
        return
    end

    % Calculate circularity if missing
    if ~isfield(propsROS, 'Circularity') && isfield(propsROS, 'Perimeter')
        for k = 1:numel(propsROS)
            A = propsROS(k).Area;
            P = propsROS(k).Perimeter;
            if ~isempty(P) && P > 0
                propsROS(k).Circularity = 4 * pi * A / (P^2);
            else
                propsROS(k).Circularity = NaN;
            end
        end
    end

    % Ensure intensity field exists
    if ~isfield(propsROS, 'MeanIntensityGreen')
        for k = 1:numel(propsROS)
            propsROS(k).MeanIntensityGreen = NaN;
        end
    end

    propsROS = keepSimpleFields(propsROS);
    tbl = struct2table(propsROS);

    % Desired column order with priority fields first
    desiredOrder = {
        'NucleusID', 'Channel', ...
        'Area', 'Circularity', ...
        'Eccentricity', 'EquivDiameter', ...
        'MeanIntensityGreen', ...
        'PixelIdxList'
    };

    % Add missing columns
    for i = 1:numel(desiredOrder)
        v = desiredOrder{i};
        if ~ismember(v, tbl.Properties.VariableNames)
            if strcmp(v, 'PixelIdxList')
                tbl.(v) = cell(height(tbl), 1);
            else
                tbl.(v) = NaN(height(tbl), 1);
            end
        end
    end

    % Reorder columns: desired first, then remaining
    allVars = tbl.Properties.VariableNames;
    tailVars = setdiff(allVars, desiredOrder, 'stable');
    tbl = tbl(:, [desiredOrder, tailVars]);
end

Tred = prepareROSTable(propsROS);
Tdiffuse = prepareROSTable(diffuseROSProps);

if ~isempty(Tred), Tred.Channel = repmat("ROS", height(Tred), 1); end
if ~isempty(Tdiffuse), Tdiffuse.Channel = repmat("Diffuse", height(Tdiffuse), 1); end

% Union of variable names to standardize tables
allVars = union(Tred.Properties.VariableNames, Tdiffuse.Properties.VariableNames);

% Add missing vars to each table
function T = addMissingVars(T, vars)
    for v = vars
        varName = v{1};
        if ~ismember(varName, T.Properties.VariableNames)
            T.(varName) = NaN(height(T), 1);
        end
    end
end

Tred = addMissingVars(Tred, allVars);
Tdiffuse = addMissingVars(Tdiffuse, allVars);

% Ensure PixelIdxList is a cell column
tables = {Tred, Tdiffuse};
for i = 1:numel(tables)
    T = tables{i};
    if ismember('PixelIdxList', T.Properties.VariableNames)
        if ~iscell(T.PixelIdxList)
            T.PixelIdxList = num2cell(T.PixelIdxList);
        end
    else
        T.PixelIdxList = cell(height(T), 1);
    end
    tables{i} = T;
end
[Tred, Tdiffuse] = deal(tables{:});

% Combine ROS and Diffuse ROS tables
ROSmetricsTable = [Tred; Tdiffuse];
writetable(ROSmetricsTable, filename, 'Sheet', 'ROSMetrics');

fprintf('✓ Excel export completed: %s\n', filename);

end
