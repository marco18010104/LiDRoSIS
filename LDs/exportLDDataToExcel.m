function exportLDDataToExcel(name, img, nucProps, ldPropsRed, ldByNucleusRed, ...
    ldPropsGreen, ldByNucleusGreen, ldPropsColoc, ldByNucleusColoc, ...
    diffuseLDProps, diffuseLDsByNucleus, imageInfo, outFolder, colocMetrics)
% exportLDDataToExcel - Export Lipid Droplet (LD) data and metrics to an Excel file.
%
% This function compiles global metrics, per-nucleus statistics, and individual LD object
% properties into a structured Excel file. It supports LDs classified into red, green, 
% colocalized (red ∩ green), and diffuse (non-classical) types.
%
% INPUTS:
%   name                : String, sample/image identifier (used for naming output file).
%   img                 : Original RGB image (not directly used).
%   nucProps            : Struct array of nucleus properties (from regionprops).
%   ldPropsRed          : Struct array of red LD properties.
%   ldByNucleusRed      : Cell array linking red LDs to nuclei.
%   ldPropsGreen        : Struct array of green LD properties.
%   ldByNucleusGreen    : Cell array linking green LDs to nuclei.
%   ldPropsColoc        : Struct array of colocalized LD properties.
%   ldByNucleusColoc    : Cell array linking colocalized LDs to nuclei.
%   diffuseLDProps      : Struct array of diffuse LD properties.
%   diffuseLDsByNucleus : Cell array linking diffuse LDs to nuclei.
%   imageInfo           : Struct with fields: CellLine, Dose, Nanoparticles (metadata).
%   outFolder           : Directory path for saving the Excel file.
%   colocMetrics        : Struct with colocalization metrics (Pearson, Manders, Overlap).
%
% OUTPUT:
%   Writes an Excel file named '[name]_LDReport.xlsx' with three sheets:
%     - 'GlobalMetrics'  : Aggregated metrics per image.
%     - 'NucleusMetrics' : Per-nucleus LD statistics.
%     - 'LDMetrics'      : Full table of individual LD objects.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Define output filename
filename = fullfile(outFolder, [name '_LDReport.xlsx']);

% Extract nucleus area and compute average
numCells = numel(nucProps);
nucAreas = [nucProps.Area]';
meanNucArea = mean(nucAreas);

% Convert any input to struct array if necessary
    function s = ensureStructArray(x)
        if istable(x)
            s = table2struct(x);
        elseif iscell(x)
            s = [x{:}];
        else
            s = x;
        end
    end

ldPropsRed = ensureStructArray(ldPropsRed);
ldPropsGreen = ensureStructArray(ldPropsGreen);
ldPropsColoc = ensureStructArray(ldPropsColoc);
diffuseLDProps = ensureStructArray(diffuseLDProps);

%% ---------------------- 1. Global Metrics sheet -----------------

% Compute basic metrics (counts, area, intensity, etc.)
    function R = calcMetrics(p)
        if isempty(p)
            R = struct('count', 0, 'totalArea', 0, 'meanArea', NaN, ...
                       'meanEcc', NaN, 'meanEquivDiameter', NaN, ...
                       'meanIntensity', NaN, 'stdIntensity', NaN);
            return
        end
        areaVals = [p.Area];
        eccVals = [p.Eccentricity];
        equivDiameterVals = [p.EquivDiameter];
        if isfield(p, 'MeanIntensityRed')
            intensities = [p.MeanIntensityRed];
        elseif isfield(p, 'MeanIntensityColoc')
            intensities = [p.MeanIntensityColoc];
        else
            intensities = NaN(size(areaVals));
        end
        R.count = numel(p);
        R.totalArea = sum(areaVals);
        R.meanArea = mean(areaVals);
        R.meanEcc = mean(eccVals);
        R.meanEquivDiameter = mean(equivDiameterVals);
        R.meanIntensity = mean(intensities);
        R.stdIntensity = std(intensities);
    end

% Get metrics for each LD type
R = calcMetrics(ldPropsRed);
G = calcMetrics(ldPropsGreen);
C = calcMetrics(ldPropsColoc);
D = calcMetrics(diffuseLDProps);

% Compute mean number of LDs per nucleus
meanLDsPerNucleus.Red = mean(cellfun(@numel, ldByNucleusRed(:)));
meanLDsPerNucleus.Green = mean(cellfun(@numel, ldByNucleusGreen(:)));
meanLDsPerNucleus.Coloc = mean(cellfun(@numel, ldByNucleusColoc(:)));
meanLDsPerNucleus.Diffuse = mean(cellfun(@numel, diffuseLDsByNucleus(:)));

% Calculate global mean Red/Green intensity ratio
meanRatioAll = NaN;
if ~isempty(ldPropsRed) && ~isempty(ldPropsGreen)
    reds = [ldPropsRed.MeanIntensityRed];
    greens = [ldPropsRed.MeanIntensityGreen];
    validIdx = greens > 0;
    if any(validIdx)
        meanRatioAll = mean(reds(validIdx) ./ greens(validIdx));
    end
end

% Extract experimental metadata
cellLine = imageInfo.CellLine{1};
dose = imageInfo.Dose{1};
nps = imageInfo.Nanoparticles{1};

% Assemble global metrics into cell array
globalData = {
    'Filename', name;
    'Cell Line', cellLine;
    'Dose', dose;
    'NPs', nps;
    'Num Nuclei', numCells;
    'Mean Nucleus Area [px]', meanNucArea;
    'Mean LDs per Nucleus Red', meanLDsPerNucleus.Red;
    'Mean LDs per Nucleus Green', meanLDsPerNucleus.Green;
    'Mean LDs per Nucleus Colocalized', meanLDsPerNucleus.Coloc;
    'Mean LDs per Nucleus Diffuse', meanLDsPerNucleus.Diffuse;
    'Num LDs Red', R.count;
    'Num LDs Green', G.count;
    'Num LDs Colocalized', C.count;
    'Num LDs Diffuse', D.count;
    'Mean LD Area Red', R.meanArea;
    'Mean LD Area Green', G.meanArea;
    'Mean LD Area Coloc', C.meanArea;
    'Mean LD Area Diffuse', D.meanArea;
    'Total LD Area Red', R.totalArea;
    'Total LD Area Green', G.totalArea;
    'Total LD Area Coloc', C.totalArea;
    'Total LD Area Diffuse', D.totalArea;
    'Mean Intensity Red', R.meanIntensity;
    'Mean Intensity Green', G.meanIntensity;
    'Mean Intensity Coloc', C.meanIntensity;
    'Mean Intensity Diffuse', D.meanIntensity;
    'Std Intensity Red', R.stdIntensity;
    'Std Intensity Green', G.stdIntensity;
    'Std Intensity Coloc', C.stdIntensity;
    'Std Intensity Diffuse', D.stdIntensity;
    'Global MeanRatio (Red/Green)', meanRatioAll;
    'Pearson Colocalization', colocMetrics.Pearson;
    'Manders M1', colocMetrics.Manders_M1;
    'Manders M2', colocMetrics.Manders_M2;
    'Overlap Colocalization', colocMetrics.Overlap;
};

writecell(globalData, filename, 'Sheet', 'GlobalMetrics');

%% --------------------- 2. Nucleus Metrics sheet -----------------

% Build nucleus-level table
nucleusTable = table((1:numCells)', nucAreas, ...
    'VariableNames', {'NucleusID', 'NucleusArea'});
nucleusTable.MeanLDs_Red = cellfun(@numel, ldByNucleusRed(:));
nucleusTable.MeanLDs_Green = cellfun(@numel, ldByNucleusGreen(:));
nucleusTable.MeanLDs_Coloc = cellfun(@numel, ldByNucleusColoc(:));
nucleusTable.MeanLDs_Diffuse = cellfun(@numel, diffuseLDsByNucleus(:));
nucleusTable.CellLine = repmat({cellLine}, numCells, 1);
nucleusTable.Dose = repmat({dose}, numCells, 1);
nucleusTable.Nanoparticles = repmat({nps}, numCells, 1);

writetable(nucleusTable, filename, 'Sheet', 'NucleusMetrics');

%% ---------------------- 3. LD Metrics sheet ---------------------

% Prepare LD tables: keep simple fields, compute circularity and ratios
    function simpleProps = keepSimpleFields(ldProps)
        if isempty(ldProps), simpleProps = ldProps; return; end
        fNames = fieldnames(ldProps);
        toKeep = false(size(fNames));
        for i = 1:length(fNames)
            val = ldProps(1).(fNames{i});
            if (isscalar(val) && (isnumeric(val) || islogical(val))) || ischar(val) || isstring(val)
                toKeep(i) = true;
            end
        end
        simpleProps = rmfield(ldProps, fNames(~toKeep));
    end

    function tbl = prepareLDTable(ldProps)
        if isempty(ldProps), tbl = table(); return; end

        % Compute circularity if possible
        if ~isfield(ldProps, 'Circularity') && isfield(ldProps, 'Perimeter')
            for k = 1:numel(ldProps)
                A = ldProps(k).Area;
                P = ldProps(k).Perimeter;
                if P > 0
                    ldProps(k).Circularity = 4 * pi * A / (P^2);
                else
                    ldProps(k).Circularity = NaN;
                end
            end
        end

        % Fill missing intensity fields
        if ~isfield(ldProps, 'MeanIntensityRed'), [ldProps.MeanIntensityRed] = deal(NaN); end
        if ~isfield(ldProps, 'MeanIntensityGreen'), [ldProps.MeanIntensityGreen] = deal(NaN); end
        if ~isfield(ldProps, 'MeanIntensityColoc'), [ldProps.MeanIntensityColoc] = deal(NaN); end

        % Compute Red/Green intensity ratio
        for k = 1:numel(ldProps)
            r = ldProps(k).MeanIntensityRed;
            g = ldProps(k).MeanIntensityGreen;
            if ~isnan(r) && ~isnan(g) && g > 0
                ldProps(k).MeanRatio = r / g;
            else
                ldProps(k).MeanRatio = NaN;
            end
        end

        ldProps = keepSimpleFields(ldProps);
        tbl = struct2table(ldProps);
    end

% Generate individual LD tables
Tred     = prepareLDTable(ldPropsRed);
Tgreen   = prepareLDTable(ldPropsGreen);
Tcoloc   = prepareLDTable(ldPropsColoc);
Tdiffuse = prepareLDTable(diffuseLDProps);

% Add channel label and metadata
if ~isempty(Tred),     Tred.Channel     = repmat("Red", height(Tred), 1); end
if ~isempty(Tgreen),   Tgreen.Channel   = repmat("Green", height(Tgreen), 1); end
if ~isempty(Tcoloc),   Tcoloc.Channel   = repmat("Colocalized", height(Tcoloc), 1); end
if ~isempty(Tdiffuse), Tdiffuse.Channel = repmat("Diffuse", height(Tdiffuse), 1); end

for T = {'Tred', 'Tgreen', 'Tcoloc', 'Tdiffuse'}
    if ~isempty(eval(T{1}))
        eval([T{1} '.CellLine = repmat({cellLine}, height(' T{1} '), 1);']);
        eval([T{1} '.Dose = repmat({dose}, height(' T{1} '), 1);']);
        eval([T{1} '.Nanoparticles = repmat({nps}, height(' T{1} '), 1);']);
    end
end

% Harmonize variables across LD tables
allVars = union(union(Tred.Properties.VariableNames, Tgreen.Properties.VariableNames), ...
                union(Tcoloc.Properties.VariableNames, Tdiffuse.Properties.VariableNames));

    function T = addMissingVars(T, vars)
        for v = vars
            if ~ismember(v{1}, T.Properties.VariableNames)
                T.(v{1}) = NaN(height(T), 1);
            end
        end
    end

Tred     = addMissingVars(Tred, allVars);
Tgreen   = addMissingVars(Tgreen, allVars);
Tcoloc   = addMissingVars(Tcoloc, allVars);
Tdiffuse = addMissingVars(Tdiffuse, allVars);

Tred     = Tred(:, allVars);
Tgreen   = Tgreen(:, allVars);
Tcoloc   = Tcoloc(:, allVars);
Tdiffuse = Tdiffuse(:, allVars);

% Optionally remove heavy fields (PixelIdxList)
if ismember('PixelIdxList', Tred.Properties.VariableNames)
    Tred.PixelIdxList = [];
end
if ismember('PixelIdxList', Tgreen.Properties.VariableNames)
    Tgreen.PixelIdxList = [];
end
if ismember('PixelIdxList', Tcoloc.Properties.VariableNames)
    Tcoloc.PixelIdxList = [];
end
if ismember('PixelIdxList', Tdiffuse.Properties.VariableNames)
    Tdiffuse.PixelIdxList = [];
end

% Concatenate all LDs into one table
Tall = [Tred; Tgreen; Tcoloc; Tdiffuse];

% Write LD table to Excel
writetable(Tall, filename, 'Sheet', 'LDMetrics');

end