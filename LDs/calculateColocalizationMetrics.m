% function colocMetrics = calculateColocalizationMetrics(imgRed, imgGreen, mask, debug)
% % Calcula métricas de colocalização entre canais vermelho e verde
% 
% if nargin < 4
%     debug = false;
% end
% 
% % Normalizar canais (0–1)
% imgRed = double(imgRed); imgRed = imgRed / max(imgRed(:));
% imgGreen = double(imgGreen); imgGreen = imgGreen / max(imgGreen(:));
% 
% % Aplicar máscara
% r = imgRed(mask);
% g = imgGreen(mask);
% 
% % Pearson correlation coefficient
% pearsonCoeff = corr(r(:), g(:));
% 
% % Manders coefficients
% M1 = sum(r .* (g > 0)) / sum(r + eps);
% M2 = sum(g .* (r > 0)) / sum(g + eps);
% 
% % Overlap coefficient (K1)
% overlapCoeff = sum(r .* g) / sqrt(sum(r.^2) * sum(g.^2) + eps);
% 
% % Costes' randomization (opcional simplificado)
% numPerms = 100;
% costesP = 1.0;  % default to 1.0
% permuted = zeros(numPerms, 1);
% 
% for i = 1:numPerms
%     g_perm = g(randperm(length(g)));  % randomizar green
%     permuted(i) = corr(r(:), g_perm(:), 'Rows', 'complete');
% end
% 
% costesP = sum(permuted >= pearsonCoeff) / numPerms;
% 
% % Debug plots
% if debug
%     figure;
%     subplot(1,2,1);
%     scatter(r, g, 5, 'filled');
%     xlabel('Red intensity'); ylabel('Green intensity'); title('Scatter');
%     subplot(1,2,2);
%     histogram(permuted, 20); hold on;
%     xline(pearsonCoeff, 'r', 'LineWidth', 2);
%     title(sprintf('Costes test (p = %.3f)', costesP));
% end
% 
% % Output struct
% colocMetrics = struct( ...
%     'Pearson', pearsonCoeff, ...
%     'Manders_M1', M1, ...
%     'Manders_M2', M2, ...
%     'Overlap', overlapCoeff, ...
%     'CostesPValue', costesP ...
% );
% end

function colocMetrics = calculateColocalizationMetrics(imgRed, imgGreen, mask, debug)
% CALCULATECOLOCALIZATIONMETRICS - Computes colocalization metrics between red and green channels.
%
%   This function quantifies the degree of colocalization between two fluorescence channels
%   (typically red and green), restricted to a binary mask. It returns common metrics used in
%   biological image analysis, including Pearson’s correlation, Manders’ coefficients, the overlap
%   coefficient, and Costes' randomization p-value.
%
% INPUTS:
%   imgRed   : (MxN uint8/double array)
%       Red fluorescence channel image. Can be raw or preprocessed.
%
%   imgGreen : (MxN uint8/double array)
%       Green fluorescence channel image. Must be the same size as imgRed.
%
%   mask     : (MxN logical array)
%       Binary mask specifying the pixels to include in the analysis.
%       Typically derived from segmented lipid droplets or regions of interest.
%
%   debug    : (logical, optional, default = false)
%       If true, displays debug plots: scatter plot of intensities and histogram of permutations.
%
% OUTPUT:
%   colocMetrics : (struct)
%       Struct containing the following fields:
%         - Pearson       : Pearson's correlation coefficient (r)
%         - Manders_M1    : Manders' coefficient M1 (fraction of red overlapping green)
%         - Manders_M2    : Manders' coefficient M2 (fraction of green overlapping red)
%         - Overlap       : Overlap coefficient (K1)
%         - CostesPValue  : p-value from Costes’ significance test (based on random permutations)
%
% EXAMPLE USAGE:
%   img = imread('fluorescence_image.tif');
%   imgRed = img(:,:,1);
%   imgGreen = img(:,:,2);
%   mask = segmentedRegion > 0;
%   metrics = calculateColocalizationMetrics(imgRed, imgGreen, mask, true);
%   disp(metrics);
%
% DEPENDENCIES:
%   - Statistics and Machine Learning Toolbox (for corr)
%
% EXCEPTIONS:
%   - If mask is empty or contains no true values, all metrics are returned as NaN.
%
% REFERENCES:
%   - Manders et al., 1993
%   - Costes et al., Biophysical Journal, 2004
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

if nargin < 4
    debug = false;
end

% Check for valid mask
if isempty(mask) || nnz(mask) == 0
    warning('Empty or invalid mask. Returning NaN metrics.');
    colocMetrics = struct( ...
        'Pearson', NaN, ...
        'Manders_M1', NaN, ...
        'Manders_M2', NaN, ...
        'Overlap', NaN, ...
        'CostesPValue', NaN ...
    );
    return;
end

% Normalize input images to [0, 1]
imgRed = double(imgRed);
imgRed = imgRed / max(imgRed(:) + eps);
imgGreen = double(imgGreen);
imgGreen = imgGreen / max(imgGreen(:) + eps);

% Extract masked pixels
r = imgRed(mask);
g = imgGreen(mask);

% Pearson correlation coefficient (r)
pearsonCoeff = corr(r(:), g(:), 'Rows', 'complete');

% Manders’ coefficients (M1: red overlapping green, M2: green overlapping red)
M1 = sum(r .* (g > 0)) / (sum(r) + eps);
M2 = sum(g .* (r > 0)) / (sum(g) + eps);

% Overlap coefficient (K1)
overlapCoeff = sum(r .* g) / sqrt(sum(r.^2) * sum(g.^2) + eps);

% Costes’ significance test (permutation test)
numPerms = 100;
permuted = zeros(numPerms, 1);
for i = 1:numPerms
    g_perm = g(randperm(length(g)));
    permuted(i) = corr(r(:), g_perm(:), 'Rows', 'complete');
end
costesP = sum(permuted >= pearsonCoeff) / numPerms;

% Optional debug visualizations
if debug
    figure('Name', 'Colocalization Debug');
    subplot(1,2,1);
    scatter(r, g, 5, 'filled');
    xlabel('Red intensity'); ylabel('Green intensity'); title('Red vs Green');
    grid on;

    subplot(1,2,2);
    histogram(permuted, 20); hold on;
    xline(pearsonCoeff, 'r', 'LineWidth', 2);
    title(sprintf("Costes test (p = %.3f)", costesP));
    xlabel('Randomized Pearson r'); ylabel('Frequency');
    grid on;
end

% Output struct
colocMetrics = struct( ...
    'Pearson', pearsonCoeff, ...
    'Manders_M1', M1, ...
    'Manders_M2', M2, ...
    'Overlap', overlapCoeff, ...
    'CostesPValue', costesP ...
);

end
