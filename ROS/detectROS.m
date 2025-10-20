function candidatesROS = detectROS(imgRGB, debug, nucMask)
% DETECTROS - Detects candidate Reactive Oxygen Species (ROS) regions in an RGB image.
%
% This function applies a multi-step image processing pipeline to identify ROS candidates
% primarily in the green channel of an RGB image. The processing includes:
%   - Contrast enhancement with CLAHE
%   - Background removal via Gaussian smoothing and subtraction
%   - Difference of Gaussian (DoG) filtering with pre-smoothing
%   - Adaptive binarization with threshold adjustment
%   - Morphological cleanup
%   - Filtering by shape descriptors (area, circularity, eccentricity) and local entropy
%   - Optional exclusion based on overlap and distance from nuclei mask
%
% INPUTS:
%   imgRGB    - MxNx3 numeric RGB image (uint8, uint16 or double in [0,1]) where detection
%               is performed mainly on the green channel.
%   debug     - (optional) logical scalar; if true, displays intermediate images for debugging.
%               Default: false.
%   nucMask   - (optional) MxN logical mask of nuclei locations; candidate ROS overlapping nuclei
%               or too far from nuclei can be excluded.
%
% OUTPUT:
%   candidatesROS - MxN logical mask indicating detected ROS candidate regions.
%
% EXCEPTIONS / WARNINGS:
%   - If imgRGB does not have 3 color channels, the function may error or produce unexpected results.
%   - If nucMask is provided, must be logical and size must match imgRGB.
%
% EXAMPLES:
%   img = imread('cells_sample.tif');
%   rosMask = detectROS(img, true); % shows debug figures
%
%   nucleiMask = segmentNuclei(img);
%   rosMask = detectROS(img, false, nucleiMask);
%
% NOTES:
%   - The size and shape thresholds, as well as maximum distance to nuclei, are tunable parameters.
%   - Function designed to work best with biological fluorescence images.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

if nargin < 2
    debug = false;
end

% Validate input image size and channels
if size(imgRGB,3) ~= 3
    error('Input image must be an RGB image with 3 channels.');
end

green = im2double(imgRGB(:,:,2));    % Extract and normalize green channel
green = adapthisteq(green);          % Contrast Limited Adaptive Histogram Equalization

% Background estimation and subtraction
background = imgaussfilt(green, 20);  
enhanced = green - background;
enhanced(enhanced < 0) = 0;          % Clip negatives to zero

% Additional smoothing prior to DoG filtering
preSigma = 1.0;                      % Adjustable smoothing parameter
enhancedSmooth = imgaussfilt(enhanced, preSigma);

% Difference of Gaussian filter for blob enhancement
gauss1 = imgaussfilt(enhancedSmooth, 1);
gauss2 = imgaussfilt(enhancedSmooth, 2);
dog = gauss1 - gauss2;
dog = mat2gray(dog);                 % Normalize to [0,1]

% Binarization with a slightly raised threshold for selectivity
T = graythresh(dog);
bw = imbinarize(dog, T + 0.03);

% Morphological cleanup: remove small objects, close gaps, fill holes
bw = bwareaopen(bw, 5);
bw = imclose(bw, strel('disk', 1));
bw = imfill(bw, 'holes');

% Calculate local entropy and normalize for further filtering
entropy = entropyfilt(green);
entropy = mat2gray(entropy);                 % Normalize to [0,1]

% Filter candidate regions based on shape and entropy criteria
props = regionprops(bw, 'Area', 'Perimeter', 'PixelIdxList', 'Eccentricity');
bwFiltered = false(size(bw));

for i = 1:numel(props)
    A = props(i).Area;
    P = props(i).Perimeter;
    C = 4 * pi * A / (P^2 + eps);     % Circularity metric
    E = props(i).Eccentricity;
    
    pixIdx = props(i).PixelIdxList;
    entVal = mean(entropy(pixIdx));
    
    % Filter criteria: area, circularity, eccentricity, entropy thresholds
    if A >= 30 && A <= 300 && C > 0.5 && E < 0.85 && entVal > 0.2
        bwFiltered(pixIdx) = true;
    end
end

bw = bwFiltered;

% If nuclei mask provided, remove ROS candidates overlapping nuclei and too far from any nucleus
if nargin > 2 && ~isempty(nucMask)
    if ~islogical(nucMask) || ~isequal(size(nucMask), size(bw))
        error('nucMask must be a logical mask of the same size as imgRGB channels.');
    end
    
    bw = bw & ~nucMask;                % Remove ROS overlapping nuclei
    D = bwdist(nucMask);              % Distance transform to nearest nucleus pixel
    maxDist = 90;                    % Maximum allowed distance in pixels
    
    bwLabel = bwlabel(bw);
    props = regionprops(bwLabel, 'PixelIdxList');
    
    for k = 1:numel(props)
        pixDist = D(props(k).PixelIdxList);
        if all(pixDist > maxDist)
            bw(props(k).PixelIdxList) = 0; % Remove objects too far from nuclei
        end
    end
end

candidatesROS = bw;

% Display debug visualizations if requested
if debug
    figure('Name','Debug - ROS Detection Pipeline');
    subplot(2,3,1); imshow(green); title('Green Channel + CLAHE');
    subplot(2,3,2); imshow(background); title('Estimated Background');
    subplot(2,3,3); imshow(enhanced); title('Background Subtracted');
    subplot(2,3,4); imshow(dog); title('Difference of Gaussian');
    subplot(2,3,5); imshow(candidatesROS); title('Final ROS Candidates');
    if nargin > 2 && ~isempty(nucMask)
        subplot(2,3,6); imshow(labeloverlay(green, nucMask | candidatesROS));
        title('Nuclei and ROS Overlay');
    end
end

end
