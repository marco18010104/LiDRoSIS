function addROSBoxplotsToExcel(filename, varargin)
% ADDROSBOXPLOTSTOEXCEL - Adds boxplots of metrics into an Excel workbook.
%
% This function reads metric data from a specified sheet in an Excel file (e.g., NucleusMetrics or ROSMetrics),
% generates boxplots grouped by experimental variables, saves plots as PNG files,
% and embeds the plots as images into new or existing sheets within the Excel workbook.
%
% Supports automatic selection of default metrics based on the sheet content.
%
% PARAMETERS:
%   filename         (char) - Full path to the Excel file to process.
%
% Name-Value Pairs:
%   'SheetName'      (char) - Name of the worksheet containing metrics. Default: 'NucleusMetrics'.
%   'GroupVars'      (cell) - Cell array of grouping variable names for boxplots, e.g., {'Dose', 'Nanoparticles'}.
%                             Default: {'Dose','Nanoparticles'}.
%   'Metrics'        (cell) - Metrics to plot. If empty or omitted, selects defaults based on data:
%                             For ROS metrics, tries 'NumROS' and 'NumROS_Diffuse',
%                             falling back to legacy names if needed.
%   'OutputFigFolder' (char) - Folder path to save PNG figures (optional). Default: '' (temporary files only).
%
% BEHAVIOR:
%   - Reads the specified sheet from the Excel file.
%   - Checks for required grouping variables; if missing, fills with 'Unknown'.
%   - Selects metrics to plot based on user input or defaults.
%   - Generates boxplots grouped by the concatenated grouping variables.
%   - Saves each boxplot as PNG in the optional output folder and a temporary file.
%   - Embeds the boxplot images into separate sheets in the Excel file via COM automation.
%
% NOTES:
%   - Requires MATLAB running on Windows with Excel installed (COM Automation support).
%   - The Excel file must be closed prior to running this function.
%
% EXAMPLE USAGE:
%   addBoxplotsToExcel('Results.xlsx', ...
%                     'SheetName', 'ROSMetrics', ...
%                     'GroupVars', {'Dose','Nanoparticles'}, ...
%                     'Metrics', {'NumROS','NumROS_Diffuse'}, ...
%                     'OutputFigFolder', 'figures');
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% === PARSE INPUTS ===
p = inputParser;
addRequired(p, 'filename', @ischar);
addParameter(p, 'SheetName', 'NucleusMetrics', @ischar);
addParameter(p, 'GroupVars', {'Dose','Nanoparticles'}, @(x) iscell(x) && all(cellfun(@ischar,x)));
addParameter(p, 'Metrics', {}, @(x) iscell(x) && all(cellfun(@ischar,x))); % empty means auto-select
addParameter(p, 'OutputFigFolder', '', @ischar);
parse(p, filename, varargin{:});

sheetName     = p.Results.SheetName;
groupVars     = p.Results.GroupVars;
metricsToPlot = p.Results.Metrics;
figOutFolder  = p.Results.OutputFigFolder;

% Create output folder if specified and missing
if ~isempty(figOutFolder) && ~exist(figOutFolder, 'dir')
    mkdir(figOutFolder);
end

% === READ DATA TABLE ===
try
    data = readtable(filename, 'Sheet', sheetName);
catch
    warning('Sheet "%s" not found in Excel file.', sheetName);
    return;
end

% === SELECT DEFAULT METRICS FOR ROS IF EMPTY ===
if isempty(metricsToPlot)
    if ismember('NumROS', data.Properties.VariableNames)
        metricsToPlot = {'NumROS', 'NumROS_Diffuse'};
    elseif ismember('NumROS_Red', data.Properties.VariableNames)
        metricsToPlot = {'NumROS_Red', 'NumROS_Diffuse'};
    else
        warning('No default ROS metrics found in sheet "%s".', sheetName);
        return;
    end
else
    % Fix requested metric names if legacy names exist
    for i = 1:length(metricsToPlot)
        if strcmp(metricsToPlot{i}, 'NumROS') && ~ismember('NumROS', data.Properties.VariableNames)
            if ismember('NumROS_Red', data.Properties.VariableNames)
                metricsToPlot{i} = 'NumROS_Red'; % Adjust to actual column name
            end
        end
    end
    % Filter metrics to those present in the data
    metricsToPlot = metricsToPlot(ismember(metricsToPlot, data.Properties.VariableNames));
    if isempty(metricsToPlot)
        warning('No valid metrics found in sheet "%s".', sheetName);
        return;
    end
end

% === ENSURE GROUPING VARIABLES EXIST ===
for i = 1:length(groupVars)
    gv = groupVars{i};
    if ~ismember(gv, data.Properties.VariableNames)
        data.(gv) = repmat({'Unknown'}, height(data), 1);
    end
end

existingGroupVars = groupVars(ismember(groupVars, data.Properties.VariableNames));

% === OPEN EXCEL VIA COM ===
excel = actxserver('Excel.Application');
excel.Visible = false;
workbook = excel.Workbooks.Open(filename);

% === GENERATE AND INSERT BOXPLOTS ===
for m = metricsToPlot
    metricName = m{1};
    fig = figure('Visible', 'off'); clf;

    try
        % Build concatenated grouping labels
        nRows = height(data);
        groupLabels = cell(nRows, 1);
        for i = 1:nRows
            parts = cell(1, length(existingGroupVars));
            for j = 1:length(existingGroupVars)
                val = data{i, existingGroupVars{j}};
                if iscell(val), val = val{1}; end
                if isstring(val), val = char(val); end
                if isnumeric(val), val = num2str(val); end
                parts{j} = val;
            end
            groupLabels{i} = strjoin(parts, '_');
        end
        groupLabels = categorical(groupLabels);

        % Create boxplot
        boxplot(data.(metricName), groupLabels, 'LabelOrientation', 'inline');
        title(sprintf('Boxplot: %s (%s)', metricName, sheetName), 'Interpreter', 'none');
        ylabel(metricName, 'Interpreter', 'none');
        set(gca, 'XTickLabelRotation', 45);
    catch err
        warning('Error generating boxplot for %s: %s', metricName, err.message);
        close(fig);
        continue;
    end

    % === SAVE FIGURE ===
    tempFigName = [tempname '.png'];
    if ~isempty(figOutFolder)
        finalFigName = fullfile(figOutFolder, sprintf('Boxplot_%s_%s.png', sheetName, metricName));
        saveas(fig, finalFigName);
    end
    saveas(fig, tempFigName);
    close(fig);

    % === INSERT IMAGE INTO EXCEL ===
    try
        try
            sheet = workbook.Sheets.Item(['Boxplot_' sheetName '_' metricName]);
        catch
            rawSheetName = sprintf('Boxplot_%s_%s', sheetName, metricName);
            validSheetName = regexprep(rawSheetName, '[:\\/*?[\]]', '_');
            if strlength(validSheetName) > 31
                validSheetName = validSheetName(1:31);
            end
            try
                sheet = workbook.Sheets.Item(validSheetName);
            catch
                sheet = workbook.Sheets.Add([], workbook.Sheets.Item(workbook.Sheets.Count));
                try
                    sheet.Name = validSheetName;
                catch
                    uuidStr = char(java.util.UUID.randomUUID().toString());
                    sheet.Name = ['Plot_' uuidStr(1:8)];
                end
            end
        end
        sheet.Activate;
        shapes = sheet.Shapes;
        shapes.AddPicture(tempFigName, 0, 1, 10, 10, 600, 400);
        fprintf('✓ Boxplot "%s" (%s) inserted into Excel.\n', metricName, sheetName);
    catch ME
        warning('Could not insert boxplot %s into Excel.\n%s\n', metricName, ME.message);
        fprintf('Figure saved at: %s\n', tempFigName);
    end

    delete(tempFigName);
end

% === CLEANUP ===
workbook.Save();
workbook.Close();
excel.Quit();
delete(excel);

end
