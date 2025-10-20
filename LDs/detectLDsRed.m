function ldCandidatesRed = detectLDsRed(imgRGB, nucMask, params, debug)
% detectLDsRed - Detect Lipid Droplets (LDs) in the red channel using combined DoG and SDOG filtering.
%
% PURPOSE:
%   This function identifies Lipid Droplet candidates in the red channel of a fluorescence image
%   by applying a Difference of Gaussians (DoG) and a steerable DoG (SDOG) method. Results are
%   filtered based on object morphology, background intensity, and proximity to nuclei.
%
% INPUTS:
%   imgRGB   : MxNx3 RGB image (uint8 or double). The original microscopy image.
%
%   nucMask  : MxN binary mask indicating nuclear regions (logical or numeric). Used to exclude
%              LDs overlapping with nuclei and to compute distance-based filtering.
%
%   params   : Struct with parameter fields controlling thresholds and filtering.
%              If empty or not provided, default parameters are used.
%              Fields include:
%                 - dog: sigmaSmall, sigmaLarge, thresholdPercentile, minArea, maxArea,
%                        eccentricityMax, solidityMin
%                 - sdog: sigma, minArea, maxArea, eccentricityMax, solidityMin
%                 - intensityThreshold: minimum mean intensity for exclusive LDs
%                 - maxDistLowBg: max distance from nucleus in low background
%                 - maxDistHighBg: max distance in high background
%                 - backgroundIntensityThreshold: background threshold to classify as "high"
%
%   debug    : (Optional) Boolean flag to enable debug visualizations (default = true).
%
% OUTPUT:
%   ldCandidatesRed : MxN binary mask (logical) of detected LD candidates in the red channel.
%
% EXCEPTIONS:
%   - Errors if input dimensions are inconsistent.
%   - Protected against empty input masks or invalid object pixel indices.
%
% EXAMPLE USAGE:
%   img = imread('fluorescenceImage.tif');
%   [nucMask, ~, ~] = segmentNuclei(img, false);
%   ldMaskRed = detectLDsRed(img, nucMask, [], true);
%   imshow(ldMaskRed); title('Detected LDs (Red Channel)');
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% ----------------- Initialization ------------------

if nargin < 4
    debug = true;
end

if nargin < 3 || isempty(params)
    % Default parameter values
    params.dog = struct('sigmaSmall', 1.5, ...
                        'sigmaLarge', 3, ...
                        'thresholdPercentile', 98, ...
                        'minArea', 20, ...
                        'maxArea', 300, ...
                        'eccentricityMax', 0.85, ...
                        'solidityMin', 0.7);

    params.sdog = struct('sigma', 1, ...
                         'minArea', 20, ...
                         'maxArea', 300, ...
                         'eccentricityMax', 0.85, ...
                         'solidityMin', 0.7);

    params.intensityThreshold = 0.15;
    params.maxDistLowBg = 125;
    params.maxDistHighBg = 90;
    params.backgroundIntensityThreshold = 0.1;
end

% Extract red channel and normalize
red = im2double(imgRGB(:,:,1));

% ----------------- 1. DoG Filtering ------------------

redCLAHE = adapthisteq(red, 'ClipLimit', 0.01, 'NumTiles', [8 8]);
background = imopen(redCLAHE, strel('disk', 15));
enhanced = imsubtract(redCLAHE, background);

dog = imgaussfilt(enhanced, params.dog.sigmaSmall) - imgaussfilt(enhanced, params.dog.sigmaLarge);
dog = mat2gray(dog);
thresholdDoG = prctile(dog(:), params.dog.thresholdPercentile);
bwDoG = dog > thresholdDoG;

% Clean and refine
bwDoG = imfill(imclose(bwareaopen(bwDoG, 5), strel('disk', 1)), 'holes');

% Filter by shape
statsDoG = regionprops(bwDoG, 'Area', 'Eccentricity', 'Solidity');
validIdxDoG = find([statsDoG.Area] >= params.dog.minArea & ...
                   [statsDoG.Area] <= params.dog.maxArea & ...
                   [statsDoG.Eccentricity] < params.dog.eccentricityMax & ...
                   [statsDoG.Solidity] > params.dog.solidityMin);
bwDoGFiltered = ismember(bwlabel(bwDoG), validIdxDoG);

bwDoGFiltered = bwDoGFiltered & ~nucMask;

% ----------------- 2. SDOG Filtering ------------------

sdogResp = steerableDoGRed(imgRGB, params.sdog.sigma);

thresholdSDOG = graythresh(sdogResp);
bwSDOG = imbinarize(sdogResp, thresholdSDOG);

% Clean and refine
bwSDOG = imfill(imclose(bwareaopen(bwSDOG, 5), strel('disk', 1)), 'holes');

% Filter by shape
statsSDOG = regionprops(bwSDOG, 'Area', 'Eccentricity', 'Solidity');
validIdxSDOG = find([statsSDOG.Area] >= params.sdog.minArea & ...
                    [statsSDOG.Area] <= params.sdog.maxArea & ...
                    [statsSDOG.Eccentricity] < params.sdog.eccentricityMax & ...
                    [statsSDOG.Solidity] > params.sdog.solidityMin);
bwSDOGFiltered = ismember(bwlabel(bwSDOG), validIdxSDOG);

bwSDOGFiltered = bwSDOGFiltered & ~nucMask;

% ----------------- 3. Mask Combination ------------------

% Combine both methods
maskIntersect = bwDoGFiltered & bwSDOGFiltered;
maskUnionExclusive = xor(bwDoGFiltered, bwSDOGFiltered);

% Filter exclusive objects by intensity
statsUnion = regionprops(maskUnionExclusive, red, 'PixelIdxList', 'MeanIntensity');
validIdx = find([statsUnion.MeanIntensity] > params.intensityThreshold);
maskUnionExclusiveFiltered = false(size(maskUnionExclusive));
for k = 1:numel(validIdx)
    maskUnionExclusiveFiltered(statsUnion(validIdx(k)).PixelIdxList) = true;
end

% Final merged mask
ldCandidatesRed = maskIntersect | maskUnionExclusiveFiltered;

% ----------------- 4. Distance and Background Filtering ------------------

ldCandidatesRed = filterByDistanceAndBackground(ldCandidatesRed, nucMask, red, params);

% ----------------- 5. Debug Visualization ------------------

if debug
    figure('Name','Red LD Detection Debug');
    subplot(3,3,1); imshow(red); title('Original Red Channel');
    subplot(3,3,2); imshow(dog); title('DoG Response');
    subplot(3,3,3); imshow(bwDoGFiltered); title('Filtered DoG');
    subplot(3,3,5); imshow(sdogResp); title('SDOG Response');
    subplot(3,3,6); imshow(bwSDOGFiltered); title('Filtered SDOG');

    subplot(3,3,4);
    imshow(red); hold on;
    visboundaries(bwDoGFiltered, 'Color', 'r');
    visboundaries(bwSDOGFiltered, 'Color', 'g');
    title('Overlay: DoG (red), SDOG (green)'); hold off;

    subplot(3,3,7); imshow(ldCandidatesRed); title('Final Combined Mask');
    subplot(3,3,8); imshow(imgRGB); hold on;
    visboundaries(ldCandidatesRed, 'Color', 'm'); title('Overlay on RGB'); hold off;
end
end

%% ------------------------------------------------------------------------
function sdogResp = steerableDoGRed(imgRGB, sigma)
% steerableDoGRed - Computes steerable DoG response in red channel.
%
% PURPOSE:
%   Enhances edge-like or blob-like structures using gradient and Hessian-derived features.
%
% INPUTS:
%   imgRGB : MxNx3 image (RGB image).
%   sigma  : Gaussian standard deviation (controls the scale of detection).
%
% OUTPUT:
%   sdogResp : MxN matrix, normalized SDOG response combining gradient magnitude and eigenvalues.
%
% NOTES:
%   - Used internally by detectLDsRed.
%   - Inspired by vesselness / blob detection filters.

% Extract red channel
red = im2double(imgRGB(:,:,1));
[x, y] = meshgrid(-ceil(3*sigma):ceil(3*sigma));
G = exp(-(x.^2 + y.^2)/(2*sigma^2)) / (2*pi*sigma^2);

% First-order Gaussian derivatives
Gx = -x .* G / sigma^2;
Gy = -y .* G / sigma^2;

% Second-order Gaussian derivatives
Gxx = (x.^2 - sigma^2) .* G / sigma^4;
Gyy = (y.^2 - sigma^2) .* G / sigma^4;
Gxy = x .* y .* G / sigma^4;

% Compute derivatives (Convolution)
Ix = imfilter(red, Gx, 'replicate');
Iy = imfilter(red, Gy, 'replicate');
Ixx = imfilter(red, Gxx, 'replicate');
Iyy = imfilter(red, Gyy, 'replicate');
Ixy = imfilter(red, Gxy, 'replicate');

% Gradient magnitude
magGrad = sqrt(Ix.^2 + Iy.^2);

% Hessian eigenvalues
traceH = Ixx + Iyy;
detH = Ixx.*Iyy - Ixy.^2;
disc = sqrt(max(0, (traceH.^2)/4 - detH));
lambda1 = traceH/2 + disc;
lambda2 = traceH/2 - disc;
maxEig = max(abs(lambda1), abs(lambda2));

% Combine into steerable DoG response
sdogResp = mat2gray(magGrad .* maxEig);
end

% Teste 2
% function ldCandidatesRed = detectLDsRed(imgRGB, debug, nucMask)
% % detectLDsRed - Deteta candidatos a LDs vermelhos com pré-processamento melhorado
% % Entrada:
% %   - imgRGB: imagem RGB original
% %   - debug: se true, mostra imagens de debug
% %   - nucMask (opcional): máscara binária com núcleos, para evitar sobreposição
% % Saída:
% %   - ldCandidatesRed: imagem binária com LDs candidatos
% 
% % --- Extração e pré-processamento ---
% red = im2double(imgRGB(:,:,1));
% redCLAHE = adapthisteq(red, 'ClipLimit', 0.01, 'NumTiles', [8 8]);
% 
% % Remoção de fundo com top-hat morfológico
% background = imopen(redCLAHE, strel('disk', 15));
% enhanced = imsubtract(redCLAHE, background);
% 
% % Suavização opcional (descomentar se necessário)
% % enhanced = imbilatfilt(enhanced);
% 
% % --- Difference of Gaussians (DoG) ---
% sigmaSmall = 1;
% sigmaLarge = 2; % alterei de 3
% dog = imgaussfilt(enhanced, sigmaSmall) - imgaussfilt(enhanced, sigmaLarge);
% dog = mat2gray(dog);  % normaliza entre 0 e 1
% 
% % --- Binarização robusta por percentil ---
% threshold = prctile(dog(:), 98);  % ajustável entre 98-99.5 conforme imagem
% bw = dog > threshold;
% 
% % --- Pós-processamento morfológico ---
% bw = bwareaopen(bw, 5);  % remover objetos pequenos
% bw = imclose(bw, strel('disk', 1));
% bw = imfill(bw, 'holes');
% 
% % --- Filtragem morfológica adicional (anti-falsos positivos) ---
% stats = regionprops(bw, 'Area', 'Eccentricity', 'Solidity');
% validIdx = find([stats.Area] >= 4 & [stats.Area] <= 300 & ...
%                 [stats.Eccentricity] < 0.75 & [stats.Solidity] > 0.7);
% bwFiltered = ismember(bwlabel(bw), validIdx);
% 
% % --- Remover LDs colidindo ou distantes de núcleos ---
% if nargin > 2 && ~isempty(nucMask)
%     % Remover LDs diretamente sobrepostos
%     bwFiltered = bwFiltered & ~nucMask;
% 
%     % NOVO: Remover LDs distantes dos núcleos
%     maxDist = 90;  % distância máxima em píxeis
%     D = bwdist(nucMask);
%     bwLabel = bwlabel(bwFiltered);
%     props = regionprops(bwLabel, 'PixelIdxList');
%     for k = 1:numel(props)
%         pixDist = D(props(k).PixelIdxList);
%         if all(pixDist > maxDist)
%             bwFiltered(props(k).PixelIdxList) = 0;
%         end
%     end
% end
% 
% ldCandidatesRed = bwFiltered;
% 
% % --- Debug visual ---
% if debug
%     figure;
%     subplot(2,4,1); imshow(red); title('Canal Vermelho Original');
%     subplot(2,4,2); imshow(redCLAHE); title('CLAHE');
%     subplot(2,4,3); imshow(background); title('Fundo (top-hat)');
%     subplot(2,4,4); imshow(enhanced); title('Após subtração do fundo');
%     subplot(2,4,5); imshow(dog); title('DoG');
%     subplot(2,4,6); imshow(bw); title('Binarização inicial');
%     subplot(2,4,7); imshow(bwFiltered); title('Após filtros morfológicos');
%     if nargin > 2
%         subplot(2,4,8); imshowpair(nucMask, bwFiltered); title('LDs vs Núcleos');
%     end
% end
% end

% Teste 1
% function ldCandidatesRed = detectLDsRed(imgRGB, debug, nucMask)
% % detectLDsRed - Detecta candidatos a LDs vermelhos usando DoG + segmentação por círculos
% %
% % Entradas:
% %   - imgRGB: imagem RGB original
% %   - debug: booleano para mostrar figuras de debug
% %   - nucMask (opcional): máscara binária com núcleos, para evitar sobreposição
% %
% % Saída:
% %   - ldCandidatesRed: imagem binária com candidatos a LDs vermelhos
% 
% % --- 1. Pré-processamento ---
% red = im2double(imgRGB(:,:,1));
% redCLAHE = adapthisteq(red, 'ClipLimit', 0.03, 'NumTiles', [8 8]);
% 
% background = imopen(redCLAHE, strel('disk', 15));
% enhanced = imsubtract(redCLAHE, background);
% 
% % --- 2. Difference of Gaussians (DoG) ---
% sigmaSmall = 1.5;
% sigmaLarge = 3.0;
% dog = imgaussfilt(enhanced, sigmaSmall) - imgaussfilt(enhanced, sigmaLarge);
% dog = mat2gray(dog);
% 
% % --- 3. Binarização pelo percentil ---
% threshold = prctile(dog(:), 99);
% bwDoG = dog > threshold;
% 
% % --- 4. Pós-processamento morfológico DoG ---
% bwDoG = bwareaopen(bwDoG, 5);
% bwDoG = imclose(bwDoG, strel('disk', 1));
% bwDoG = imfill(bwDoG, 'holes');
% 
% % --- 5. Segmentação manual por círculos ---
% [BW_circles, ~] = segmentImage(imgRGB);
% 
% % --- 6. Combinar segmentações (interseção) ---
% bwCombined = bwDoG & BW_circles;
% 
% % --- 7. Filtragem morfológica dos blobs combinados ---
% stats = regionprops(bwCombined, 'Area', 'Eccentricity', 'Solidity');
% validIdx = find([stats.Area] >= 4 & [stats.Area] <= 300 & ...
%                 [stats.Eccentricity] < 0.75 & [stats.Solidity] > 0.7);
% bwFiltered = ismember(bwlabel(bwCombined), validIdx);
% 
% % --- 8. Remover blobs sobrepondo núcleos e muito distantes ---
% if nargin > 2 && ~isempty(nucMask)
%     % Remover sobreposição direta
%     bwFiltered = bwFiltered & ~nucMask;
% 
%     % Remover blobs com distância > 60 px a núcleos
%     maxDist = 60;
%     D = bwdist(nucMask);
%     bwLabel = bwlabel(bwFiltered);
%     props = regionprops(bwLabel, 'PixelIdxList');
%     for k = 1:numel(props)
%         pixDist = D(props(k).PixelIdxList);
%         if all(pixDist > maxDist)
%             bwFiltered(props(k).PixelIdxList) = 0;
%         end
%     end
% end
% 
% ldCandidatesRed = bwFiltered;
% 
% % --- 9. Debug visual ---
% if debug
%     figure;
%     subplot(2,4,1); imshow(red); title('Canal Vermelho Original');
%     subplot(2,4,2); imshow(redCLAHE); title('CLAHE');
%     subplot(2,4,3); imshow(background); title('Fundo (top-hat)');
%     subplot(2,4,4); imshow(enhanced); title('Após subtração do fundo');
%     subplot(2,4,5); imshow(dog); title('DoG');
%     subplot(2,4,6); imshow(bwDoG); title('Binarização DoG + Morfologia');
%     subplot(2,4,7); imshow(BW_circles); title('Segmentação por círculos');
%     subplot(2,4,8); imshow(bwFiltered); title('Resultado final filtrado');
%     if nargin > 2 && ~isempty(nucMask)
%         figure;
%         imshowpair(nucMask, bwFiltered);
%         title('LDs finais vs Máscara de Núcleos');
%     end
% end
% 
% end
% 
% % --- Função auxiliar segmentImage ---
% function [BW, maskedImage] = segmentImage(RGB)
% % segmentImage - Segmenta círculos brilhantes via imfindcircles
% [centers,radii,~] = imfindcircles(RGB,[1 8],'ObjectPolarity','bright','Sensitivity',0.90);
% max_num_circles = Inf;
% if max_num_circles < length(radii)
%     centers = centers(1:max_num_circles,:);
%     radii = radii(1:max_num_circles);
% end
% BW = circles2mask(centers,radii,size(RGB,1:2));
% 
% maskedImage = RGB;
% maskedImage(repmat(~BW,[1 1 3])) = 0;
% end
% 
% % --- Função auxiliar circles2mask ---
% function BW = circles2mask(centers, radii, imageSize)
% BW = false(imageSize);
% [xx,yy] = meshgrid(1:imageSize(2), 1:imageSize(1));
% for k = 1:length(radii)
%     BW = BW | ((xx - centers(k,1)).^2 + (yy - centers(k,2)).^2 <= radii(k)^2);
% end
% end
% 
