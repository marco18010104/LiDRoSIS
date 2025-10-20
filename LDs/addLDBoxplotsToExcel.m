function addLDBoxplotsToExcel(filename, varargin)
% ADDLDBOXPLOTSTOEXCEL - Adds boxplot figures of specified metrics into an Excel workbook.
%
% This function reads a sheet from an Excel file containing tabular metric data,
% groups data by specified categorical variables, generates boxplots for each metric,
% saves the figures as PNG files, and embeds them into newly created sheets in the Excel workbook.
%
% It supports flexible input parameters and gracefully handles missing data or sheets.
%
% INPUTS:
%   filename       : (char) Full path to the Excel file to modify.
%
%   Name-Value Pairs:
%     'SheetName'      : (char) Name of the Excel sheet with metric data. Default: 'NucleusMetrics'
%     'GroupVars'      : (cell of char) Variables (column names) to group data by. Default: {'Dose','Nanoparticles','CellLine'}
%     'Metrics'        : (cell of char) List of metric variable names to plot. 
%                        Default: typical lipid droplet metrics found in the sheet.
%     'OutputFigFolder': (char) Folder path to save PNG figures. If empty (default), figures are saved temporarily only.
%
% OUTPUT:
%   None (figures are saved to disk optionally, and embedded into the Excel workbook)
%
% EXCEPTIONS / WARNINGS:
%   - Throws warning if the specified sheet or metrics do not exist.
%   - Creates missing grouping columns with default 'Unknown' values.
%   - Handles Excel COM automation errors, saving figures on disk if embedding fails.
%
% DEPENDENCIES:
%   - Requires MATLAB with COM Automation support (Windows only).
%
% EXAMPLE USAGE:
%   addBoxplotsToExcel('Results_LD.xlsx', ...
%                      'SheetName', 'LDMetrics', ...
%                      'GroupVars', {'Dose','Nanoparticles'}, ...
%                      'Metrics', {'MeanArea', 'MeanIntensity_Red'}, ...
%                      'OutputFigFolder', 'figures');
%
% NOTES:
%   - Ensure Excel file is closed before running this function.
%   - For large datasets, rendering plots may take several seconds each.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M. , FCUL-IST, 2025.

    % === PARSE INPUTS ===
    p = inputParser;
    addRequired(p, 'filename', @ischar);
    addParameter(p, 'SheetName', 'NucleusMetrics', @ischar);
    addParameter(p, 'GroupVars', {'Dose','Nanoparticles','CellLine'}, ...
                 @(x) iscell(x) && all(cellfun(@ischar,x)));
    addParameter(p, 'Metrics', {}, @(x) iscell(x) && all(cellfun(@ischar,x)));
    addParameter(p, 'OutputFigFolder', '', @ischar);
    parse(p, filename, varargin{:});

    sheetName     = p.Results.SheetName;
    groupVars     = p.Results.GroupVars;
    metricsToPlot = p.Results.Metrics;
    figOutFolder  = p.Results.OutputFigFolder;

    if ~isempty(figOutFolder) && ~exist(figOutFolder, 'dir')
        mkdir(figOutFolder);
    end

    % === READ DATA TABLE ===
    try
        data = readtable(filename, 'Sheet', sheetName);
    catch
        warning('❌ Sheet "%s" not found in Excel file.', sheetName);
        return;
    end

    % === SELECT METRICS TO PLOT ===
    if isempty(metricsToPlot)
        % Default typical metrics for Lipid Droplets analysis
        defaultMetrics = {'NumLDs', 'NumLDs_Diffuse', 'MeanArea', 'MeanCircularity', ...
                          'MeanIntensity_Red', 'MeanIntensity_Green', 'MeanIntensity_Coloc'};
        metricsToPlot = intersect(defaultMetrics, data.Properties.VariableNames);
        if isempty(metricsToPlot)
            warning('❌ No default metrics found in sheet "%s".', sheetName);
            return;
        end
    else
        % Keep only existing metrics from requested list
        metricsToPlot = metricsToPlot(ismember(metricsToPlot, data.Properties.VariableNames));
        if isempty(metricsToPlot)
            warning('❌ None of the requested metrics found in sheet "%s".', sheetName);
            return;
        end
    end

    % === ENSURE GROUPING COLUMNS EXIST ===
    for i = 1:length(groupVars)
        gv = groupVars{i};
        if ~ismember(gv, data.Properties.VariableNames)
            % Fill missing grouping variable with 'Unknown'
            data.(gv) = repmat({'Unknown'}, height(data), 1);
        end
    end

    existingGroupVars = groupVars(ismember(groupVars, data.Properties.VariableNames));

    % === START EXCEL AUTOMATION ===
    excel = actxserver('Excel.Application');
    excel.Visible = false;  % Run in background
    workbook = excel.Workbooks.Open(filename);

    % === GENERATE AND INSERT BOXPLOTS ===
    for m = metricsToPlot
        metricName = m{1};
        fig = figure('Visible', 'off'); clf;

        try
            % Create categorical group labels combining grouping vars
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
            warning('⚠️ Error generating boxplot for %s: %s', metricName, err.message);
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

        % === INSERT FIGURE INTO EXCEL ===
        try
            % Attempt to find or create a sheet named after the plot
            try
                sheet = workbook.Sheets.Item(['Boxplot_' sheetName '_' metricName]);
            catch
                % Create valid Excel sheet name (max 31 chars, no invalid chars)
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
                        % Fallback to a unique random sheet name
                        uuidStr = char(java.util.UUID.randomUUID().toString());
                        sheet.Name = ['Plot_' uuidStr(1:8)];
                    end
                end
            end
            sheet.Activate;
            shapes = sheet.Shapes;
            % Add picture: parameters left, top, width, height in points
            shapes.AddPicture(tempFigName, 0, 1, 10, 10, 600, 400);
            fprintf('✓ Boxplot "%s" (%s) inserted into Excel.\n', metricName, sheetName);
        catch ME
            warning('⚠️ Could not insert boxplot %s into Excel.\n%s\n', metricName, ME.message);
            fprintf('Figure saved at: %s\n', tempFigName);
        end

        % Remove temporary PNG file if saved only temporarily
        delete(tempFigName);
    end

    % === CLEANUP ===
    workbook.Save();
    workbook.Close();
    excel.Quit();
    delete(excel);

end
