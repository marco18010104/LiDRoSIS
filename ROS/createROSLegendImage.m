function legendImg = createROSLegendImage()
% CREATEROSELEGENDIMAGE - Creates an RGB image legend for ROS size color coding.
%
% This function generates a simple RGB image that visually explains the color coding used
% to represent ROS object sizes in overlay images. It draws colored circles corresponding
% to size categories with textual labels below each circle.
%
% OUTPUT:
%   legendImg - uint8 RGB image (100x300 pixels) with color-coded circles and labels:
%               - Blue circle: "Pequeno (1x)" (Small)
%               - Green circle: "Médio (2x)" (Medium)
%               - Red circle: "Grande (3x)" (Large)
%
% NOTES:
%   - Colors are specified in 8-bit RGB format ([0 0 255], [0 255 0], [255 0 0]).
%   - Uses `insertText` for adding labels if Image Processing Toolbox is available.
%   - If `insertText` is not available, issues a warning and returns image without text.
%
% EXAMPLES:
%   legendImg = createROSLegendImage();
%   imshow(legendImg);
%
% EXCEPTIONS:
%   - If insertText is unavailable, only graphical circles are drawn.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Initialize blank image (uint8 RGB)
legendImg = uint8(zeros(100, 300, 3));

% Define circle colors (in 8-bit RGB)
colors = {
    [0, 0, 255];   % Blue for Small (1x)
    [0, 255, 0];   % Green for Medium (2x)
    [255, 0, 0];   % Red for Large (3x)
};
labels = {'Pequeno (1x)', 'Médio (2x)', 'Grande (3x)'};

% Draw colored circles centered horizontally with radius 15 pixels
for i = 1:3
    x = 50 + (i-1)*100;  % X position for each circle
    y = 50;              % Y center
    radius = 15;

    % Create meshgrid for pixel coordinates
    [xx, yy] = meshgrid(1:size(legendImg,2), 1:size(legendImg,1));

    % Circle mask
    mask = (xx - x).^2 + (yy - y).^2 <= radius^2;

    % Paint each color channel
    for c = 1:3
        channel = legendImg(:,:,c);
        channel(mask) = colors{i}(c);
        legendImg(:,:,c) = channel;
    end
end

% Add text labels below circles if insertText available
try
    positions = [20, 75; 120, 75; 220, 75];
    legendImg = insertText(legendImg, positions, labels, ...
        'FontSize', 14, 'BoxOpacity', 0, 'TextColor', 'white', 'AnchorPoint', 'LeftBottom');
catch
    warning('insertText not available. Legend will have circles only, no text.');
end

end
