function legendImg = createLDLegendImage()
% CREATELDLEGENDIMAGE - Creates a simple RGB legend image illustrating size-coded colors for Lipid Droplets (LDs).
%
% The legend shows three circles colored by size category: small (blue), medium (green), and large (red),
% with corresponding text labels underneath each circle.
%
% OUTPUT:
%   legendImg - 100x300x3 uint8 RGB image containing the legend.
%
% EXAMPLES:
%   imgLegend = createLDLegendImage();
%   imshow(imgLegend);
%
% NOTES:
%   - If the Image Processing Toolbox is available, the function adds text labels using insertText.
%   - Otherwise, it issues a warning and returns the legend with only colored circles.
%
% AUTHOR:
%   Prepared for scientific use by Ferreira, M., FCUL-IST, 2025.

% Initialize blank RGB image (uint8)
legendImg = uint8(zeros(100, 300, 3));

% Define colors in RGB (8-bit)
colors = {
    [0, 0, 255],   % Blue for small (1x)
    [0, 255, 0],   % Green for medium (2x)
    [255, 0, 0]    % Red for large (3x)
};
labels = {'Small (1x)', 'Medium (2x)', 'Large (3x)'};

% Draw colored circles
for i = 1:3
    x = 50 + (i-1)*100;   % Circle centers: 50, 150, 250 horizontally
    y = 50;               % Vertical center
    radius = 15;

    [xx, yy] = meshgrid(1:size(legendImg, 2), 1:size(legendImg, 1));
    mask = (xx - x).^2 + (yy - y).^2 <= radius^2;
    
    for c = 1:3
        channel = legendImg(:,:,c);
        channel(mask) = colors{i}(c);
        legendImg(:,:,c) = channel;
    end
end

% Add text labels below circles if possible
try
    legendImg = insertText(legendImg, [20, 75; 120, 75; 220, 75], labels, ...
        'FontSize', 14, 'BoxOpacity', 0, 'TextColor', 'white', 'AnchorPoint', 'CenterBottom');
catch
    warning('insertText function not available. Returning legend without text.');
end

end
