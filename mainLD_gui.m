% % PT VERSION
% % function mainLD_gui(imageTable, outputDir, axOrig, axOverlay, txtTerminal, stopFlagHandle)
% % % MAINLD_GUI - Versão GUI do pipeline de análise de LDs com atualização interativa.
% % %
% % %   Requer eixos da GUI para visualização de imagem original e overlays, terminal textual
% % %   e uma função anónima para consulta de stopFlag (boolean).
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
% %         % --- Extração de caminho e metadados
% %         imgPath = imageTable.FullPath{i};
% %         [~, name, ~] = fileparts(imgPath);
% % 
% %         relPath = fullfile(imageTable.CellLine{i}, ...
% %                            imageTable.IrradiationSource{i}, ...
% %                            imageTable.Nanoparticles{i}, ...
% %                            imageTable.Dose{i}, ...
% %                            imageTable.Objective{i});
% %         outFolder = fullfile(outputDir, relPath);
% %         if ~exist(outFolder, 'dir'), mkdir(outFolder); end
% % 
% %         % Skip se já processado
% %         overlayPath = fullfile(outFolder, [name '_nuclei_overlay.png']);
% %         if exist(overlayPath, 'file')
% %             updateTerminal(txtTerminal, ['🔁 A saltar imagem já processada: ', name]);
% %             continue;
% %         end
% % 
% %         updateTerminal(txtTerminal, sprintf('🔬 A processar %d/%d: %s', ...
% %             i, height(imageTable), name));
% % 
% %         img = imread(imgPath);
% %         imgRed = img(:,:,1);
% %         imgGreen = img(:,:,2);
% % 
% %         imshow(img, 'Parent', axOrig);
% %         drawnow;
% % 
% %         % --- Segmentação de núcleos
% %         [nucMask, nucLabel, nucProps] = segmentNuclei(img, false);
% % 
% %         % --- LDs Verdes
% %         ldCandidatesGreen = detectLDsGreen(img, nucMask, [], false);
% %         [ldLabelGreen, ldPropsGreen] = labelLDs(ldCandidatesGreen);
% %         ldPropsGreen = assignLDsToNuclei(ldPropsGreen, nucProps);
% %         ldPropsGreen = addLDIntensities(ldPropsGreen, img);
% %         ldMaskGreen = createLDMaskFromProps(ldPropsGreen, size(img,1:2));
% %         ldOverlayGreen = generateLDOverlay(img, ldLabelGreen);
% % 
% %         % --- LDs Vermelhos
% %         ldCandidatesRed = detectLDsRed(img, nucMask, [], false);
% %         [ldLabelRed, ldPropsRed] = labelLDs(ldCandidatesRed);
% %         ldPropsRed = assignLDsToNuclei(ldPropsRed, nucProps);
% %         ldPropsRed = addLDIntensities(ldPropsRed, img);
% %         ldMaskRed = createLDMaskFromProps(ldPropsRed, size(img,1:2));
% %         ldOverlayRed = generateLDOverlay(img, ldLabelRed);
% % 
% %         % --- LDs Colocalizados
% %         [ldColocMask, ldColocLabel, ldPropsColoc] = detectLDsColocalized(ldMaskGreen, ldMaskRed, false);
% %         ldPropsColoc = assignLDsToNuclei(ldPropsColoc, nucProps);
% %         ldPropsColoc = addLDIntensities(ldPropsColoc, img, ldColocMask);
% %         ldOverlayColoc = generateLDOverlay(img, ldColocLabel);
% % 
% %         % --- LDs Difusos
% %         diffuseLDMask = detectDiffuseLDs(img, false, nucMask);
% %         diffuseLDLabel = bwlabel(diffuseLDMask);
% %         diffuseLDProps = regionprops(logical(diffuseLDMask), ...
% %             'Centroid', 'Area', 'PixelIdxList', ...
% %             'Eccentricity', 'EquivDiameter', ...
% %             'Perimeter', 'MajorAxisLength', ...
% %             'MinorAxisLength', 'Solidity', ...
% %             'Extent', 'ConvexArea');
% %         diffuseLDProps = assignLDsToNuclei(diffuseLDProps, nucProps);
% %         diffuseLDProps = addLDIntensities(diffuseLDProps, img);
% %         diffuseLDOverlay = labeloverlay(img, diffuseLDLabel, 'Transparency', 0.4, 'Colormap', parula);
% % 
% %         % --- Atualizar overlay
% %         fullOverlay = imtile({ldOverlayRed, ldOverlayGreen, ldOverlayColoc, diffuseLDOverlay});
% %         imshow(fullOverlay, 'Parent', axOverlay);
% %         drawnow;
% % 
% %         % --- Agrupamento por núcleo
% %         ldByNucleusRed = groupLDsByNucleus(ldPropsRed, numel(nucProps));
% %         ldByNucleusGreen = groupLDsByNucleus(ldPropsGreen, numel(nucProps));
% %         ldByNucleusColoc = groupLDsByNucleus(ldPropsColoc, numel(nucProps));
% %         diffuseLDsByNucleus = groupLDsByNucleus(diffuseLDProps, numel(nucProps));
% % 
% %         % --- Métricas de Colocalização
% %         colocMetrics = calculateColocalizationMetrics(imgRed, imgGreen, ...
% %                                                       ldMaskGreen | ldMaskRed, false);
% % 
% %         % --- Exportar para Excel
% %         exportLDDataToExcel(name, img, ...
% %             nucProps, ...
% %             ldPropsRed, ldByNucleusRed, ...
% %             ldPropsGreen, ldByNucleusGreen, ...
% %             ldPropsColoc, ldByNucleusColoc, ...
% %             diffuseLDProps, diffuseLDsByNucleus, ...
% %             imageTable(i,:), outFolder, colocMetrics);
% % 
% %         % % --- Boxplots
% %         % try
% %         %     filename = fullfile(outFolder, [name '_LDReport.xlsx']);
% %         %     addLDBoxplotsToExcel(filename, ...
% %         %         'SheetName', 'NucleusMetrics', ...
% %         %         'GroupVars', {'Dose', 'Nanoparticles'}, ...
% %         %         'Metrics', {'MeanLDs_Red', 'MeanLDs_Green', 'MeanLDs_Coloc'});
% %         % 
% %         %     addLDBoxplotsToExcel(filename, ...
% %         %         'SheetName', 'LDMetrics', ...
% %         %         'GroupVars', {'Dose', 'Nanoparticles'}, ...
% %         %         'Metrics', {'Area', 'Diameter', 'Circularity', 'Eccentricity', ...
% %         %                     'MeanIntensity_Red', 'MeanIntensity_Green', 'MeanRatio'});
% %         % 
% %         %     updateTerminal(txtTerminal, ['📈 Boxplots adicionados a "', name, '".']);
% %         % catch ME
% %         %     updateTerminal(txtTerminal, ['⚠️ Erro nos boxplots de "', name, '": ', ME.message]);
% %         % end
% % 
% %         % --- Guardar imagens
% %         imwrite(uint8(255 * mat2gray(nucMask)), fullfile(outFolder, [name '_nuclei.png']));
% %         imwrite(labeloverlay(img, nucLabel, 'Transparency', 0.6), ...
% %                 fullfile(outFolder, [name '_nuclei_overlay.png']));
% %         imwrite(ldOverlayGreen, fullfile(outFolder, [name '_LDGreen_overlay.png']));
% %         imwrite(ldOverlayRed, fullfile(outFolder, [name '_LDRed_overlay.png']));
% %         imwrite(ldOverlayColoc, fullfile(outFolder, [name '_LDColoc_overlay.png']));
% %         imwrite(diffuseLDOverlay, fullfile(outFolder, [name '_LD_diffuse_overlay.png']));
% %         imwrite(uint8(255 * mat2gray(ldMaskGreen)), fullfile(outFolder, [name '_LDGreen_mask.png']));
% %         imwrite(uint8(255 * mat2gray(ldMaskRed)), fullfile(outFolder, [name '_LDRed_mask.png']));
% %         imwrite(uint8(255 * mat2gray(ldColocMask)), fullfile(outFolder, [name '_LDColoc_mask.png']));
% %         imwrite(uint8(255 * mat2gray(diffuseLDMask)), ...
% %                 fullfile(outFolder, [name '_LD_diffuse_mask.png']));
% % 
% %         updateTerminal(txtTerminal, ['✅ Imagem "', name, '" processada com sucesso.']);
% % 
% %         % Liberta memória
% %         clearvars -except imageTable outputDir axOrig axOverlay txtTerminal stopFlagHandle i
% %     end
% % 
% %     % --- Agregação final
% %     updateTerminal(txtTerminal, '📦 A agregar relatórios...');
% %     ldReports = dir(fullfile(outputDir, '**', '*_LDReport.xlsx'));
% % 
% %     if isempty(ldReports)
% %         updateTerminal(txtTerminal, '⚠️ Nenhum relatório LD encontrado para agregação.');
% %     else
% %         aggregateLDReportsByGroup(outputDir);
% %         updateTerminal(txtTerminal, '✅ Agregação final concluída.');
% %     end
% % 
% % catch ME
% %     updateTerminal(txtTerminal, ['❌ Erro na análise: ', getReport(ME)]);
% % end
% % end
% 
% 
% % ENG VERSION
% function mainLD_gui(imageTable, outputDir, axOrig, axOverlay, txtTerminal, stopFlagHandle)
% %MAINLD_GUI GUI-based version of the LDs analysis pipeline with interactive updates.
% %
% %   This function processes Lipid Droplets (LDs) across all input images,
% %   visualizes them in a GUI with real-time feedback, and exports results.
% %
% %   INPUTS:
% %       imageTable     : table containing image paths and experimental metadata
% %       outputDir      : root folder for saving results
% %       axOrig         : UIAxes for displaying the original image
% %       axOverlay      : UIAxes for displaying LD overlays
% %       txtTerminal    : UI text element or component for command-line output
% %       stopFlagHandle : function handle that returns true if the user stopped the analysis
% %
% %   AUTHOR:
% %       Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.
% 
% try
%     % Loop through each image listed in the input table
%     for i = 1:height(imageTable)
%         % Check if user requested interruption
%         if stopFlagHandle()
%             updateTerminal(txtTerminal, '⛔ Analysis stopped by user.');
%             return;
%         end
% 
%         % ---------------- IMAGE & METADATA EXTRACTION ----------------
%         imgPath = imageTable.FullPath{i};                          % Full image path
%         [~, name, ~] = fileparts(imgPath);                         % Extract filename
%         relPath = fullfile(imageTable.CellLine{i}, ...
%                            imageTable.IrradiationSource{i}, ...
%                            imageTable.Nanoparticles{i}, ...
%                            imageTable.Dose{i}, ...
%                            imageTable.Objective{i});              % Subfolder structure by metadata
% 
%         outFolder = fullfile(outputDir, relPath);                  % Output directory for this image
%         if ~exist(outFolder, 'dir'), mkdir(outFolder); end
% 
%         % ---------------- SKIP ALREADY PROCESSED IMAGES ----------------
%         overlayPath = fullfile(outFolder, [name '_nuclei_overlay.png']);
%         if exist(overlayPath, 'file')
%             updateTerminal(txtTerminal, ['🔁 Skipping previously processed image: ', name]);
%             continue;
%         end
% 
%         updateTerminal(txtTerminal, sprintf('🔬 Processing %d/%d: %s', ...
%             i, height(imageTable), name));
% 
%         % ---------------- LOAD AND DISPLAY ORIGINAL IMAGE ----------------
%         img = imread(imgPath);
%         imgRed = img(:,:,1);         % Red channel (LDs)
%         imgGreen = img(:,:,2);       % Green channel (LDs)
% 
%         imshow(img, 'Parent', axOrig);  % Show original image in GUI
%         drawnow;
% 
%         % ---------------- NUCLEI SEGMENTATION ----------------
%         [nucMask, nucLabel, nucProps] = segmentNuclei(img, false);
% 
%         % ---------------- GREEN LDs ----------------
%         ldCandidatesGreen = detectLDsGreen(img, nucMask, [], false);
%         [ldLabelGreen, ldPropsGreen] = labelLDs(ldCandidatesGreen);
%         ldPropsGreen = assignLDsToNuclei(ldPropsGreen, nucProps);
%         ldPropsGreen = addLDIntensities(ldPropsGreen, img);
%         ldMaskGreen = createLDMaskFromProps(ldPropsGreen, size(img,1:2));
%         ldOverlayGreen = generateLDOverlay(img, ldLabelGreen);
% 
%         % ---------------- RED LDs ----------------
%         ldCandidatesRed = detectLDsRed(img, nucMask, [], false);
%         [ldLabelRed, ldPropsRed] = labelLDs(ldCandidatesRed);
%         ldPropsRed = assignLDsToNuclei(ldPropsRed, nucProps);
%         ldPropsRed = addLDIntensities(ldPropsRed, img);
%         ldMaskRed = createLDMaskFromProps(ldPropsRed, size(img,1:2));
%         ldOverlayRed = generateLDOverlay(img, ldLabelRed);
% 
%         % ---------------- COLOCALIZED LDs ----------------
%         [ldColocMask, ldColocLabel, ldPropsColoc] = detectLDsColocalized(ldMaskGreen, ldMaskRed, false);
%         ldPropsColoc = assignLDsToNuclei(ldPropsColoc, nucProps);
%         ldPropsColoc = addLDIntensities(ldPropsColoc, img, ldColocMask);
%         ldOverlayColoc = generateLDOverlay(img, ldColocLabel);
% 
%         % ---------------- DIFFUSE LDs ----------------
%         diffuseLDMask = detectDiffuseLDs(img, false, nucMask);
%         diffuseLDLabel = bwlabel(diffuseLDMask);
%         diffuseLDProps = regionprops(logical(diffuseLDMask), ...
%             'Centroid', 'Area', 'PixelIdxList', ...
%             'Eccentricity', 'EquivDiameter', ...
%             'Perimeter', 'MajorAxisLength', ...
%             'MinorAxisLength', 'Solidity', ...
%             'Extent', 'ConvexArea');
%         diffuseLDProps = assignLDsToNuclei(diffuseLDProps, nucProps);
%         diffuseLDProps = addLDIntensities(diffuseLDProps, img);
%         diffuseLDOverlay = labeloverlay(img, diffuseLDLabel, 'Transparency', 0.4, 'Colormap', parula);
% 
%         % ---------------- UPDATE GUI OVERLAY PANEL ----------------
%         fullOverlay = imtile({ldOverlayRed, ldOverlayGreen, ldOverlayColoc, diffuseLDOverlay});
%         imshow(fullOverlay, 'Parent', axOverlay);
%         drawnow;
% 
%         % ---------------- LDs GROUPED BY NUCLEUS ----------------
%         ldByNucleusRed     = groupLDsByNucleus(ldPropsRed,     numel(nucProps));
%         ldByNucleusGreen   = groupLDsByNucleus(ldPropsGreen,   numel(nucProps));
%         ldByNucleusColoc   = groupLDsByNucleus(ldPropsColoc,   numel(nucProps));
%         diffuseLDsByNucleus= groupLDsByNucleus(diffuseLDProps, numel(nucProps));
% 
%         % ---------------- COLOCALIZATION METRICS ----------------
%         colocMetrics = calculateColocalizationMetrics(imgRed, imgGreen, ...
%                                                       ldMaskGreen | ldMaskRed, false);
% 
%         % ---------------- EXPORT TO EXCEL ----------------
%         exportLDDataToExcel(name, img, ...
%             nucProps, ...
%             ldPropsRed, ldByNucleusRed, ...
%             ldPropsGreen, ldByNucleusGreen, ...
%             ldPropsColoc, ldByNucleusColoc, ...
%             diffuseLDProps, diffuseLDsByNucleus, ...
%             imageTable(i,:), outFolder, colocMetrics);
% 
%         % ---------------- EXPORT OVERLAY AND MASK IMAGES ----------------
%         imwrite(uint8(255 * mat2gray(nucMask)), fullfile(outFolder, [name '_nuclei.png']));
%         imwrite(labeloverlay(img, nucLabel, 'Transparency', 0.6), fullfile(outFolder, [name '_nuclei_overlay.png']));
%         imwrite(ldOverlayGreen,   fullfile(outFolder, [name '_LDGreen_overlay.png']));
%         imwrite(ldOverlayRed,     fullfile(outFolder, [name '_LDRed_overlay.png']));
%         imwrite(ldOverlayColoc,   fullfile(outFolder, [name '_LDColoc_overlay.png']));
%         imwrite(diffuseLDOverlay, fullfile(outFolder, [name '_LD_diffuse_overlay.png']));
% 
%         imwrite(uint8(255 * mat2gray(ldMaskGreen)),   fullfile(outFolder, [name '_LDGreen_mask.png']));
%         imwrite(uint8(255 * mat2gray(ldMaskRed)),     fullfile(outFolder, [name '_LDRed_mask.png']));
%         imwrite(uint8(255 * mat2gray(ldColocMask)),   fullfile(outFolder, [name '_LDColoc_mask.png']));
%         imwrite(uint8(255 * mat2gray(diffuseLDMask)), fullfile(outFolder, [name '_LD_diffuse_mask.png']));
% 
%         % ---------------- SUCCESS MESSAGE ----------------
%         updateTerminal(txtTerminal, ['✅ Image "', name, '" successfully processed.']);
% 
%         % ---------------- MEMORY MANAGEMENT ----------------
%         clearvars -except imageTable outputDir axOrig axOverlay txtTerminal stopFlagHandle i
%     end
% 
%     % ---------------- AGGREGATE ALL EXCEL REPORTS ----------------
%     updateTerminal(txtTerminal, '📦 Aggregating Excel reports...');
%     ldReports = dir(fullfile(outputDir, '**', '*_LDReport.xlsx'));
% 
%     if isempty(ldReports)
%         updateTerminal(txtTerminal, '⚠️ No LD reports found to aggregate.');
%     else
%         aggregateLDReportsByGroup(outputDir);
%         updateTerminal(txtTerminal, '✅ Final aggregation completed.');
%     end
% 
% catch ME
%     % ---------------- ERROR HANDLING ----------------
%     updateTerminal(txtTerminal, ['❌ Error during analysis: ', getReport(ME)]);
% end
% end

function mainLD_gui(imageTable, outputDir, axOrig, axOverlay, ...
                    txtTerminal, stopFlagHandle, progTxt, metricsTable)
%MAINLD_GUI GUI-based version of the LDs analysis pipeline with interactive updates.
%
%   This function processes Lipid Droplets (LDs) across all input images,
%   visualizes them in a GUI with real-time feedback, and exports results.
%
%   INPUTS:
%       imageTable     : table containing image paths and experimental metadata
%       outputDir      : root folder for saving results
%       axOrig         : UIAxes for displaying the original image
%       axOverlay      : UIAxes for displaying LD overlays
%       txtTerminal    : UI text element or component for command-line output
%       stopFlagHandle : function handle that returns true if the user stopped the analysis
%       progTxt        : (optional) uicontrol text handle for progress display
%       metricsTable   : (optional) uitable handle to show summary metrics
%
%   AUTHOR:
%       Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

if nargin < 7,  progTxt      = [];  end
if nargin < 8,  metricsTable = [];  end

try
    % Loop through each image listed in the input table
    for i = 1:height(imageTable)
        % Show progress (if provided)
        if ~isempty(progTxt) && isgraphics(progTxt)
            progTxt.String = sprintf('Progress: %d / %d', i, height(imageTable));
            drawnow limitrate;
        end
        
        % Check if user requested interruption
        if stopFlagHandle()
            updateTerminal(txtTerminal, '⛔ Analysis stopped by user.');
            return;
        end

        % ---------------- IMAGE & METADATA EXTRACTION ----------------
        imgPath = imageTable.FullPath{i};                          
        [~, name, ~] = fileparts(imgPath);                         
        relPath = fullfile(imageTable.CellLine{i}, ...
                           imageTable.IrradiationSource{i}, ...
                           imageTable.Nanoparticles{i}, ...
                           imageTable.Dose{i}, ...
                           imageTable.Objective{i});              

        outFolder = fullfile(outputDir, relPath);                  
        if ~exist(outFolder, 'dir'), mkdir(outFolder); end

        % ---------------- SKIP ALREADY PROCESSED IMAGES ----------------
        overlayPath = fullfile(outFolder, [name '_nuclei_overlay.png']);
        if exist(overlayPath, 'file')
            updateTerminal(txtTerminal, ['🔁 Skipping previously processed image: ', name]);
            continue;
        end

        updateTerminal(txtTerminal, sprintf('🔬 Processing %d/%d: %s', i, height(imageTable), name));

        % ---------------- LOAD AND DISPLAY ORIGINAL IMAGE ----------------
        img = imread(imgPath);
        imshow(img, 'Parent', axOrig);
        drawnow;

        % ---------------- NUCLEI SEGMENTATION ----------------
        [nucMask, nucLabel, nucProps] = segmentNuclei(img, false);

        % ---------------- GREEN LDs ----------------
        ldCandidatesGreen = detectLDsGreen(img, nucMask, [], false);
        [ldLabelGreen, ldPropsGreen] = labelLDs(ldCandidatesGreen);
        ldPropsGreen = assignLDsToNuclei(ldPropsGreen, nucProps);
        ldPropsGreen = addLDIntensities(ldPropsGreen, img);
        ldMaskGreen = createLDMaskFromProps(ldPropsGreen, size(img,1:2));
        ldOverlayGreen = generateLDOverlay(img, ldLabelGreen);

        % ---------------- RED LDs ----------------
        ldCandidatesRed = detectLDsRed(img, nucMask, [], false);
        [ldLabelRed, ldPropsRed] = labelLDs(ldCandidatesRed);
        ldPropsRed = assignLDsToNuclei(ldPropsRed, nucProps);
        ldPropsRed = addLDIntensities(ldPropsRed, img);
        ldMaskRed = createLDMaskFromProps(ldPropsRed, size(img,1:2));
        ldOverlayRed = generateLDOverlay(img, ldLabelRed);

        % ---------------- COLOCALIZED LDs ----------------
        [ldColocMask, ldColocLabel, ldPropsColoc] = detectLDsColocalized(ldMaskGreen, ldMaskRed, false);
        ldPropsColoc = assignLDsToNuclei(ldPropsColoc, nucProps);
        ldPropsColoc = addLDIntensities(ldPropsColoc, img, ldColocMask);
        ldOverlayColoc = generateLDOverlay(img, ldColocLabel);

        % ---------------- DIFFUSE LDs ----------------
        diffuseLDMask = detectDiffuseLDs(img, false, nucMask);
        diffuseLDLabel = bwlabel(diffuseLDMask);
        diffuseLDProps = regionprops(logical(diffuseLDMask), ...
            'Centroid', 'Area', 'PixelIdxList', ...
            'Eccentricity', 'EquivDiameter', ...
            'Perimeter', 'MajorAxisLength', ...
            'MinorAxisLength', 'Solidity', ...
            'Extent', 'ConvexArea');
        diffuseLDProps = assignLDsToNuclei(diffuseLDProps, nucProps);
        diffuseLDProps = addLDIntensities(diffuseLDProps, img);
        diffuseLDOverlay = labeloverlay(img, diffuseLDLabel, 'Transparency', 0.4, 'Colormap', parula);

        % ---------------- UPDATE GUI OVERLAY PANEL ----------------
        fullOverlay = imtile({ldOverlayRed, ldOverlayGreen, ldOverlayColoc, diffuseLDOverlay});
        imshow(fullOverlay, 'Parent', axOverlay);
        drawnow;
        
        % ---- Overlay quadrant labels ------------------------------------
        % Delete old labels (tag = 'OverlayLabel') from previous loop
        delete(findall(axOverlay,'Tag','OverlayLabel'));
    
        % Put new labels in pixel coordinates
        [hImg,wImg,~] = size(fullOverlay);
        hold(axOverlay,'on');
        txtArgs = {'Color','w','FontSize',10,'FontWeight','bold', ...
                   'Tag','OverlayLabel','Interpreter','none'};
        text(axOverlay, 0.05*wImg, 0.05*hImg, 'LD-Red',          txtArgs{:});
        text(axOverlay, 0.55*wImg, 0.05*hImg, 'LD-Green',        txtArgs{:});
        text(axOverlay, 0.05*wImg, 0.55*hImg, 'LD-Colocalized',  txtArgs{:});
        text(axOverlay, 0.55*wImg, 0.55*hImg,'LD-Diffuse',       txtArgs{:});
        hold(axOverlay,'off');

        % ---------------- LDs GROUPED BY NUCLEUS ----------------
        ldByNucleusRed      = groupLDsByNucleus(ldPropsRed,      numel(nucProps));
        ldByNucleusGreen    = groupLDsByNucleus(ldPropsGreen,    numel(nucProps));
        ldByNucleusColoc    = groupLDsByNucleus(ldPropsColoc,    numel(nucProps));
        diffuseLDsByNucleus = groupLDsByNucleus(diffuseLDProps,  numel(nucProps));

        % ---------------- COLOCALIZATION METRICS ----------------
        colocMetrics = calculateColocalizationMetrics(img(:,:,1), img(:,:,2), ...
                                                      ldMaskGreen | ldMaskRed, false);

        % ---------------- EXPORT TO EXCEL ----------------
        exportLDDataToExcel(name, img, ...
            nucProps, ...
            ldPropsRed, ldByNucleusRed, ...
            ldPropsGreen, ldByNucleusGreen, ...
            ldPropsColoc, ldByNucleusColoc, ...
            diffuseLDProps, diffuseLDsByNucleus, ...
            imageTable(i,:), outFolder, colocMetrics);

        % ---------------- EXPORT OVERLAY AND MASK IMAGES ----------------
        imwrite(uint8(255 * mat2gray(nucMask)), fullfile(outFolder, [name '_nuclei.png']));
        imwrite(labeloverlay(img, nucLabel, 'Transparency', 0.6), fullfile(outFolder, [name '_nuclei_overlay.png']));
        imwrite(ldOverlayGreen,   fullfile(outFolder, [name '_LDGreen_overlay.png']));
        imwrite(ldOverlayRed,     fullfile(outFolder, [name '_LDRed_overlay.png']));
        imwrite(ldOverlayColoc,   fullfile(outFolder, [name '_LDColoc_overlay.png']));
        imwrite(diffuseLDOverlay, fullfile(outFolder, [name '_LD_diffuse_overlay.png']));

        imwrite(uint8(255 * mat2gray(ldMaskGreen)),   fullfile(outFolder, [name '_LDGreen_mask.png']));
        imwrite(uint8(255 * mat2gray(ldMaskRed)),     fullfile(outFolder, [name '_LDRed_mask.png']));
        imwrite(uint8(255 * mat2gray(ldColocMask)),   fullfile(outFolder, [name '_LDColoc_mask.png']));
        imwrite(uint8(255 * mat2gray(diffuseLDMask)), fullfile(outFolder, [name '_LD_diffuse_mask.png']));

        % -------------- UPDATE METRICS TABLE (if any) ----------------
        if ~isempty(metricsTable) && isgraphics(metricsTable)
            newRow = {name, ...
                      numel(ldPropsRed), numel(ldPropsGreen), ...
                      numel(ldPropsColoc), numel(diffuseLDProps)};
            if isempty(metricsTable.Data)
                metricsTable.ColumnName = {'Image','LD_Red','LD_Green','LD_Coloc','LD_Diffuse'};
                metricsTable.Data       = newRow;
            else
                metricsTable.Data(end+1,1:numel(newRow)) = newRow;
            end
        end

        % ---------------- SUCCESS MESSAGE ----------------
        updateTerminal(txtTerminal, ['✅ Image "', name, '" successfully processed.']);

        % ---------------- MEMORY MANAGEMENT ----------------
        clearvars -except imageTable outputDir axOrig axOverlay txtTerminal stopFlagHandle progTxt metricsTable i
    end

    % ---------------- AGGREGATE ALL EXCEL REPORTS ----------------
    updateTerminal(txtTerminal, '📦 Aggregating Excel reports...');
    ldReports = dir(fullfile(outputDir, '**', '*_LDReport.xlsx'));

    if isempty(ldReports)
        updateTerminal(txtTerminal, '⚠️ No LD reports found to aggregate.');
    else
        aggregateLDReportsByGroup(outputDir);
        updateTerminal(txtTerminal, '✅ Final aggregation completed.');
    end

catch ME
    % ---------------- ERROR HANDLING ----------------
    updateTerminal(txtTerminal, ['❌ Error during analysis: ', getReport(ME)]);
end
end
