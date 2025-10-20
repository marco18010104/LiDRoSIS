% % PT VERSION
% % function mainROS_gui(imageTable, outputDir, axOrig, axOverlay, txtTerminal, stopFlagHandle)
% % % MAINROS_GUI - Versão GUI do pipeline ROS com atualizações gráficas e terminal.
% % %
% % % INPUTS:
% % %   imageTable, outputDir, axOrig, axOverlay, txtTerminal, stopFlagHandle (função boolean)
% % %
% % % AUTHOR:
% % %   Ferreira, M., FCUL-IST, 2025
% % 
% % try
% %     for i = 1:height(imageTable)
% %         if stopFlagHandle()
% %             updateTerminal(txtTerminal, '⛔ Análise interrompida pelo utilizador.');
% %             return;
% %         end
% % 
% %         imgPath = imageTable.FullPath{i};
% %         [~, name, ~] = fileparts(imgPath);
% % 
% %         relPath = fullfile(imageTable.CellLine{i}, ...
% %             imageTable.IrradiationSource{i}, ...
% %             imageTable.Nanoparticles{i}, ...
% %             imageTable.Dose{i}, ...
% %             imageTable.Objective{i});
% %         outFolder = fullfile(outputDir, relPath);
% %         if ~exist(outFolder, 'dir'), mkdir(outFolder); end
% % 
% %         overlayPath = fullfile(outFolder, [name '_ROS_overlay.png']);
% %         if exist(overlayPath, 'file')
% %             updateTerminal(txtTerminal, ['🔁 A saltar imagem já processada: ', name]);
% %             continue;
% %         end
% % 
% %         updateTerminal(txtTerminal, sprintf('🔬 A processar %d/%d: %s', i, height(imageTable), name));
% % 
% %         img = imread(imgPath);
% %         imshow(img, 'Parent', axOrig);
% %         drawnow;
% % 
% %         % --- Segmentação Núcleos
% %         [nucMask, nucLabel, nucProps] = segmentNuclei(img, false);
% % 
% %         % --- Detecção ROS (total)
% %         rosCandidates = detectROS(img, false, nucMask);
% %         [rosLabel, rosProps] = labelLDs(rosCandidates);
% %         rosProps = assignLDsToNuclei(rosProps, nucProps);
% %         rosProps = addLDIntensities(rosProps, img);
% %         rosMask = createLDMaskFromProps(rosProps, size(img,1:2));
% %         rosOverlay = generateLDOverlay(img, rosLabel);
% % 
% %         % --- Detecção ROS Difuso
% %         diffuseROSMask = detectDiffuseROS(img, false, nucMask);
% %         diffuseROSLabel = bwlabel(diffuseROSMask);
% %         diffuseROSProps = regionprops(logical(diffuseROSMask), ...
% %             'Centroid', 'Area', 'PixelIdxList', ...
% %             'Eccentricity', 'EquivDiameter', ...
% %             'Perimeter', 'MajorAxisLength', ...
% %             'MinorAxisLength', 'Solidity', ...
% %             'Extent', 'ConvexArea');
% %         diffuseROSProps = assignLDsToNuclei(diffuseROSProps, nucProps);
% %         diffuseROSProps = addLDIntensities(diffuseROSProps, img);
% %         diffuseROSOverlay = labeloverlay(img, diffuseROSLabel, 'Transparency', 0.4, 'Colormap', hot);
% % 
% %         % --- Overlay completo lado direito
% %         fullOverlay = imtile({rosOverlay, diffuseROSOverlay});
% %         imshow(fullOverlay, 'Parent', axOverlay);
% %         drawnow;
% % 
% %         % --- Agrupamento por núcleo
% %         rosByNucleus = groupLDsByNucleus(rosProps, numel(nucProps));
% %         diffuseROSByNucleus = groupLDsByNucleus(diffuseROSProps, numel(nucProps));
% % 
% %         % --- Exportar dados para Excel
% %         exportROSDataToExcel(name, img, ...
% %             nucProps, ...
% %             rosProps, rosByNucleus, ...
% %             diffuseROSProps, diffuseROSByNucleus, ...
% %             imageTable(i,:), outFolder);
% % 
% %         % % --- Boxplots
% %         % try
% %         %     filename = fullfile(outFolder, [name '_ROSReport.xlsx']);
% %         %     addROSBoxplotsToExcel(filename, ...
% %         %         'SheetName', 'NucleusMetrics', ...
% %         %         'GroupVars', {'Dose', 'Nanoparticles'}, ...
% %         %         'Metrics', {'MeanROS', 'MeanDiffuseROS'});
% %         % 
% %         %     updateTerminal(txtTerminal, ['📈 Boxplots adicionados a "', name, '".']);
% %         % catch ME
% %         %     updateTerminal(txtTerminal, ['⚠️ Erro nos boxplots de "', name, '": ', ME.message]);
% %         % end
% % 
% %         % --- Salvar máscaras e overlays
% %         imwrite(uint8(255 * mat2gray(nucMask)), fullfile(outFolder, [name '_nuclei.png']));
% %         imwrite(labeloverlay(img, nucLabel, 'Transparency', 0.6), ...
% %             fullfile(outFolder, [name '_nuclei_overlay.png']));
% %         imwrite(rosOverlay, fullfile(outFolder, [name '_ROS_overlay.png']));
% %         imwrite(diffuseROSOverlay, fullfile(outFolder, [name '_ROS_diffuse_overlay.png']));
% %         imwrite(uint8(255 * mat2gray(rosMask)), fullfile(outFolder, [name '_ROS_mask.png']));
% %         imwrite(uint8(255 * mat2gray(diffuseROSMask)), fullfile(outFolder, [name '_ROS_diffuse_mask.png']));
% % 
% %         updateTerminal(txtTerminal, ['✅ Imagem "', name, '" processada com sucesso.']);
% % 
% %         clearvars -except imageTable outputDir axOrig axOverlay txtTerminal stopFlagHandle i
% %     end
% % 
% %     updateTerminal(txtTerminal, '📦 A agregar relatórios ROS...');
% %     rosReports = dir(fullfile(outputDir, '**', '*_ROSReport.xlsx'));
% % 
% %     if isempty(rosReports)
% %         updateTerminal(txtTerminal, '⚠️ Nenhum relatório ROS encontrado para agregação.');
% %     else
% %         aggregateROSReportsByGroup(outputDir);
% %         updateTerminal(txtTerminal, '✅ Agregação final ROS concluída.');
% %     end
% % catch ME
% %     updateTerminal(txtTerminal, ['❌ Erro na análise ROS: ', getReport(ME)]);
% % end
% % end
% 
% 
% % ENG VERSION
% function mainROS_gui(imageTable, outputDir, axOrig, axOverlay, txtTerminal, stopFlagHandle)
% %MAINROS_GUI GUI-based ROS image analysis pipeline with live visual and textual feedback.
% %
% %   This function processes ROS signal data from RGB microscopy images,
% %   segments nuclei, detects ROS and diffuse ROS, and exports results.
% %
% %   INPUTS:
% %       imageTable      : Table with image paths and associated metadata
% %       outputDir       : Root directory for saving outputs
% %       axOrig          : UIAxes object for original image display
% %       axOverlay       : UIAxes object for overlays (ROS, DiffuseROS)
% %       txtTerminal     : UI text area or field for outputting analysis status
% %       stopFlagHandle  : Function handle that returns true if the process must stop
% %
% %   AUTHOR:
% %       Prepared for scientific use by Ferreira, M., FCUL-IST, 2025
% 
% try
%     % Loop over each image in the table
%     for i = 1:height(imageTable)
%         % Check if user requested stop
%         if stopFlagHandle()
%             updateTerminal(txtTerminal, '⛔ Analysis interrupted by user.');
%             return;
%         end
% 
%         % ---------------- PATH MANAGEMENT ----------------
%         imgPath = imageTable.FullPath{i};            % Full image path
%         [~, name, ~] = fileparts(imgPath);           % Extract base name
% 
%         % Generate output folder based on metadata
%         relPath = fullfile(imageTable.CellLine{i}, ...
%                            imageTable.IrradiationSource{i}, ...
%                            imageTable.Nanoparticles{i}, ...
%                            imageTable.Dose{i}, ...
%                            imageTable.Objective{i});
%         outFolder = fullfile(outputDir, relPath);
%         if ~exist(outFolder, 'dir'), mkdir(outFolder); end
% 
%         % Skip processing if overlay already exists
%         overlayPath = fullfile(outFolder, [name '_ROS_overlay.png']);
%         if exist(overlayPath, 'file')
%             updateTerminal(txtTerminal, ['🔁 Skipping previously processed image: ', name]);
%             continue;
%         end
% 
%         updateTerminal(txtTerminal, sprintf('🔬 Processing %d/%d: %s', ...
%             i, height(imageTable), name));
% 
%         % ---------------- IMAGE LOADING ----------------
%         img = imread(imgPath);                       % Load RGB image
%         imshow(img, 'Parent', axOrig);               % Show original in GUI
%         drawnow;
% 
%         % ---------------- NUCLEI SEGMENTATION ----------------
%         [nucMask, nucLabel, nucProps] = segmentNuclei(img, false);
% 
%         % ---------------- DETECT ROS OBJECTS ----------------
%         rosCandidates = detectROS(img, false, nucMask);              % Candidate detection
%         [rosLabel, rosProps] = labelLDs(rosCandidates);              % Label and extract props
%         rosProps = assignLDsToNuclei(rosProps, nucProps);            % Assign to nuclei
%         rosProps = addLDIntensities(rosProps, img);                  % Add intensity metrics
%         rosMask = createLDMaskFromProps(rosProps, size(img,1:2));    % Create binary mask
%         rosOverlay = generateLDOverlay(img, rosLabel);               % Create overlay for GUI
% 
%         % ---------------- DETECT DIFFUSE ROS ----------------
%         diffuseROSMask = detectDiffuseROS(img, false, nucMask);      % Diffuse object detection
%         diffuseROSLabel = bwlabel(diffuseROSMask);                   % Label diffuse ROS
%         diffuseROSProps = regionprops(logical(diffuseROSMask), ...   % Extract morphological features
%             'Centroid', 'Area', 'PixelIdxList', ...
%             'Eccentricity', 'EquivDiameter', ...
%             'Perimeter', 'MajorAxisLength', ...
%             'MinorAxisLength', 'Solidity', ...
%             'Extent', 'ConvexArea');
%         diffuseROSProps = assignLDsToNuclei(diffuseROSProps, nucProps);
%         diffuseROSProps = addLDIntensities(diffuseROSProps, img);
%         diffuseROSOverlay = labeloverlay(img, diffuseROSLabel, ...
%                                          'Transparency', 0.4, ...
%                                          'Colormap', hot);
% 
%         % ---------------- DISPLAY COMPOSITE OVERLAY ----------------
%         fullOverlay = imtile({rosOverlay, diffuseROSOverlay});
%         imshow(fullOverlay, 'Parent', axOverlay);
%         drawnow;
% 
%         % ---------------- GROUP OBJECTS BY NUCLEUS ----------------
%         rosByNucleus = groupLDsByNucleus(rosProps, numel(nucProps));
%         diffuseROSByNucleus = groupLDsByNucleus(diffuseROSProps, numel(nucProps));
% 
%         % ---------------- EXPORT METRICS TO EXCEL ----------------
%         exportROSDataToExcel(name, img, ...
%             nucProps, ...
%             rosProps, rosByNucleus, ...
%             diffuseROSProps, diffuseROSByNucleus, ...
%             imageTable(i,:), outFolder);
% 
%         % % OPTIONAL: Export summary plots to Excel
%         % try
%         %     filename = fullfile(outFolder, [name '_ROSReport.xlsx']);
%         %     addROSBoxplotsToExcel(filename, ...
%         %         'SheetName', 'NucleusMetrics', ...
%         %         'GroupVars', {'Dose', 'Nanoparticles'}, ...
%         %         'Metrics', {'MeanROS', 'MeanDiffuseROS'});
%         %     updateTerminal(txtTerminal, ['📈 Boxplots added to "', name, '".']);
%         % catch ME
%         %     updateTerminal(txtTerminal, ['⚠️ Error in boxplot generation for "', name, '": ', ME.message]);
%         % end
% 
%         % ---------------- SAVE MASKS AND OVERLAYS ----------------
%         imwrite(uint8(255 * mat2gray(nucMask)), fullfile(outFolder, [name '_nuclei.png']));
%         imwrite(labeloverlay(img, nucLabel, 'Transparency', 0.6), ...
%             fullfile(outFolder, [name '_nuclei_overlay.png']));
%         imwrite(rosOverlay, fullfile(outFolder, [name '_ROS_overlay.png']));
%         imwrite(diffuseROSOverlay, fullfile(outFolder, [name '_ROS_diffuse_overlay.png']));
%         imwrite(uint8(255 * mat2gray(rosMask)), fullfile(outFolder, [name '_ROS_mask.png']));
%         imwrite(uint8(255 * mat2gray(diffuseROSMask)), ...
%             fullfile(outFolder, [name '_ROS_diffuse_mask.png']));
% 
%         updateTerminal(txtTerminal, ['✅ Image "', name, '" processed successfully.']);
% 
%         % Clear temporary variables for memory efficiency
%         clearvars -except imageTable outputDir axOrig axOverlay txtTerminal stopFlagHandle i
%     end
% 
%     % ---------------- FINAL REPORT AGGREGATION ----------------
%     updateTerminal(txtTerminal, '📦 Aggregating ROS reports...');
%     rosReports = dir(fullfile(outputDir, '**', '*_ROSReport.xlsx'));
% 
%     if isempty(rosReports)
%         updateTerminal(txtTerminal, '⚠️ No ROS reports found for aggregation.');
%     else
%         aggregateROSReportsByGroup(outputDir);
%         updateTerminal(txtTerminal, '✅ Final ROS aggregation completed.');
%     end
% 
% catch ME
%     % ---------------- ERROR HANDLING ----------------
%     updateTerminal(txtTerminal, ['❌ Error in ROS analysis: ', getReport(ME)]);
% end
% end

function mainROS_gui(imageTable, outputDir, axOrig, axOverlay, ...
                    txtTerminal, stopFlagHandle, progTxt, metricsTable)
%MAINROS_GUI GUI-based ROS image analysis pipeline with live visual and textual feedback.
%
%   This function processes ROS signal data from RGB microscopy images,
%   segments nuclei, detects ROS and diffuse ROS, and exports results.
%
%   INPUTS:
%       imageTable      : Table with image paths and associated metadata
%       outputDir       : Root directory for saving outputs
%       axOrig          : UIAxes object for original image display
%       axOverlay       : UIAxes object for overlays (ROS, DiffuseROS)
%       txtTerminal     : UI text area or field for outputting analysis status
%       stopFlagHandle  : Function handle that returns true if the process must stop
%       progTxt         : (optional) uicontrol text handle for progress display
%       metricsTable    : (optional) uitable handle to show summary metrics
%
%   AUTHOR:
%       Prepared for scientific use by Ferreira, M., FCUL-IST, 2025

if nargin < 7,  progTxt      = [];  end
if nargin < 8,  metricsTable = [];  end

try
    % Loop over each image in the table
    for i = 1:height(imageTable)
        % Show progress (if provided)
        if ~isempty(progTxt) && isgraphics(progTxt)
            progTxt.String = sprintf('Progress: %d / %d', i, height(imageTable));
            drawnow limitrate;
        end

        % Check if user requested stop
        if stopFlagHandle()
            updateTerminal(txtTerminal, '⛔ Analysis interrupted by user.');
            return;
        end

        % ---------------- PATH MANAGEMENT ----------------
        imgPath = imageTable.FullPath{i};
        [~, name, ~] = fileparts(imgPath);

        % Generate output folder based on metadata
        relPath = fullfile(imageTable.CellLine{i}, ...
                           imageTable.IrradiationSource{i}, ...
                           imageTable.Nanoparticles{i}, ...
                           imageTable.Dose{i}, ...
                           imageTable.Objective{i});
        outFolder = fullfile(outputDir, relPath);
        if ~exist(outFolder, 'dir'), mkdir(outFolder); end

        % Skip processing if overlay already exists
        overlayPath = fullfile(outFolder, [name '_ROS_overlay.png']);
        if exist(overlayPath, 'file')
            updateTerminal(txtTerminal, ['🔁 Skipping previously processed image: ', name]);
            continue;
        end

        updateTerminal(txtTerminal, sprintf('🔬 Processing %d/%d: %s', i, height(imageTable), name));

        % ---------------- IMAGE LOADING ----------------
        img = imread(imgPath);
        imshow(img, 'Parent', axOrig);
        drawnow;

        % ---------------- NUCLEI SEGMENTATION ----------------
        [nucMask, nucLabel, nucProps] = segmentNuclei(img, false);

        % ---------------- DETECT ROS OBJECTS ----------------
        rosCandidates = detectROS(img, false, nucMask);
        [rosLabel, rosProps] = labelLDs(rosCandidates);
        rosProps = assignLDsToNuclei(rosProps, nucProps);
        rosProps = addLDIntensities(rosProps, img);
        rosMask = createLDMaskFromProps(rosProps, size(img,1:2));
        rosOverlay = generateLDOverlay(img, rosLabel);

        % ---------------- DETECT DIFFUSE ROS ----------------
        diffuseROSMask = detectDiffuseROS(img, false, nucMask);
        diffuseROSLabel = bwlabel(diffuseROSMask);
        diffuseROSProps = regionprops(logical(diffuseROSMask), ...
            'Centroid', 'Area', 'PixelIdxList', ...
            'Eccentricity', 'EquivDiameter', ...
            'Perimeter', 'MajorAxisLength', ...
            'MinorAxisLength', 'Solidity', ...
            'Extent', 'ConvexArea');
        diffuseROSProps = assignLDsToNuclei(diffuseROSProps, nucProps);
        diffuseROSProps = addLDIntensities(diffuseROSProps, img);
        diffuseROSOverlay = labeloverlay(img, diffuseROSLabel, ...
                                         'Transparency', 0.4, ...
                                         'Colormap', hot);

        % ---------------- DISPLAY COMPOSITE OVERLAY ----------------
        fullOverlay = imtile({rosOverlay, diffuseROSOverlay});
        imshow(fullOverlay, 'Parent', axOverlay);
        drawnow;

        % ------------- OVERLAY QUADRANT LABELS (left/right) ---------------
        delete(findall(axOverlay,'Tag','OverlayLabel'));  % remove old
        [hImg,wImg,~] = size(fullOverlay);
        hold(axOverlay,'on');
        lblProps = {'Color','w','FontSize',10,'FontWeight','bold','Tag','OverlayLabel'};
        text(axOverlay, 0.05*wImg, 0.05*hImg, 'ROS-Total',   lblProps{:});
        text(axOverlay, 0.55*wImg, 0.05*hImg, 'ROS-Diffuse', lblProps{:});
        hold(axOverlay,'off');

        % ---------------- GROUP OBJECTS BY NUCLEUS ----------------
        rosByNucleus = groupLDsByNucleus(rosProps, numel(nucProps));
        diffuseROSByNucleus = groupLDsByNucleus(diffuseROSProps, numel(nucProps));

        % ---------------- EXPORT METRICS TO EXCEL ----------------
        exportROSDataToExcel(name, img, ...
            nucProps, ...
            rosProps, rosByNucleus, ...
            diffuseROSProps, diffuseROSByNucleus, ...
            imageTable(i,:), outFolder);

        % -------------- UPDATE METRICS TABLE (if any) ----------------
        if ~isempty(metricsTable) && isgraphics(metricsTable)
            newRow = {name, numel(rosProps), numel(diffuseROSProps)};
            if isempty(metricsTable.Data)
                metricsTable.ColumnName = {'Image','ROS','DiffuseROS'};
                metricsTable.Data       = newRow;
            else
                metricsTable.Data(end+1,1:numel(newRow)) = newRow;
            end
        end

        % ---------------- SAVE MASKS AND OVERLAYS ----------------
        imwrite(uint8(255 * mat2gray(nucMask)), fullfile(outFolder, [name '_nuclei.png']));
        imwrite(labeloverlay(img, nucLabel, 'Transparency', 0.6), fullfile(outFolder, [name '_nuclei_overlay.png']));
        imwrite(rosOverlay, fullfile(outFolder, [name '_ROS_overlay.png']));
        imwrite(diffuseROSOverlay, fullfile(outFolder, [name '_ROS_diffuse_overlay.png']));
        imwrite(uint8(255 * mat2gray(rosMask)), fullfile(outFolder, [name '_ROS_mask.png']));
        imwrite(uint8(255 * mat2gray(diffuseROSMask)), fullfile(outFolder, [name '_ROS_diffuse_mask.png']));

        updateTerminal(txtTerminal, ['✅ Image "', name, '" processed successfully.']);

        % Clear temporary variables for memory efficiency
        clearvars -except imageTable outputDir axOrig axOverlay txtTerminal stopFlagHandle progTxt metricsTable i
    end

    % ---------------- FINAL REPORT AGGREGATION ----------------
    updateTerminal(txtTerminal, '📦 Aggregating ROS reports...');
    rosReports = dir(fullfile(outputDir, '**', '*_ROSReport.xlsx'));

    if isempty(rosReports)
        updateTerminal(txtTerminal, '⚠️ No ROS reports found for aggregation.');
    else
        aggregateROSReportsByGroup(outputDir);
        updateTerminal(txtTerminal, '✅ Final ROS aggregation completed.');
    end

catch ME
    % ---------------- ERROR HANDLING ----------------
    updateTerminal(txtTerminal, ['❌ Error in ROS analysis: ', getReport(ME)]);
end
end
