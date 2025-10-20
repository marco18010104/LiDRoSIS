% function placeLogo(fig, fileName, position)
% % PLACELOGO - Loads and displays a logo with transparency support.
% % Works both in development and compiled (deployed) mode.
% 
%     % Resolve assets folder path
%     if isdeployed
%         assetsPath = fullfile(ctfroot, 'assets');
%     else
%         assetsPath = fullfile(fileparts(mfilename('fullpath')), 'assets');
%     end
% 
%     % Compose full path to file
%     filePath = fullfile(assetsPath, fileName);
% 
%     % Use "which" to check inside compiled CTF archive
%     resolvedPath = which(filePath);
%     if isempty(resolvedPath)
%         resolvedPath = filePath;  % Try regular path
%     end
% 
%     if exist(resolvedPath, 'file') == 2
%         [img, ~, alpha] = imread(resolvedPath);
%         ax = axes('Parent', fig, 'Units', 'pixels', 'Position', position);
%         axes(ax);
%         if ~isempty(alpha)
%             hImg = image(img, 'Parent', ax);
%             set(hImg, 'AlphaData', double(alpha)/255);
%         else
%             image(img, 'Parent', ax);
%         end
%         axis(ax, 'off');
%     else
%         warning('Logo not found: %s', resolvedPath);
%     end
% end

% function placeLogo(fig, fileName, pos, mode)
% % pos = [x y w h];  mode 'norm' or 'pixel'
%     if nargin<4, mode='pixel'; end
%     if isdeployed, assetsPath=fullfile(ctfroot,'assets');
%     else, assetsPath=fullfile(fileparts(mfilename('fullpath')),'assets'); end
%     fp = fullfile(assetsPath,fileName);
%     if exist(fp,'file')~=2, warning('Logo missing: %s',fp); return; end
%     [im,~,alpha] = imread(fp);
% 
%     ax = axes('Parent',fig,'Units',mode,'Position',pos);
%     if ~isempty(alpha)
%         image(im,'Parent',ax,'AlphaData',double(alpha)/255);
%     else
%         image(im,'Parent',ax);
%     end
%     axis(ax,'off');
% end

% function placeLogo(fig, fileName, position)
%     try
%         p = getAssetPath(fileName);          % <‑‑ new resolver
%         [im,~,alpha] = imread(p);
% 
%         ax = axes('Parent',fig,'Units','pixels','Position',position);
%         axis(ax,'off');
%         if ~isempty(alpha)
%             h = image(im, 'Parent', ax);
%             h.AlphaData = double(alpha)/255;
%         else
%             image(im,'Parent',ax);
%         end
%     catch ME
%         warning('Logo "%s" could not be shown (%s).', fileName, ME.message);
%     end
% end

% function placeLogo(fig,fileName,pos)
% % Render PNG/JPG with alpha onto a tiny axes.
% 
% try
%     p = getAssetPath(fileName);
%     [im,~,alpha] = imread(p);
%     ax = axes('Parent',fig,'Units','pixels','Position',pos,'Visible','off');
%     if ~isempty(alpha)
%         h = image(im,'Parent',ax);  h.AlphaData = double(alpha)/255;
%     else
%         image(im,'Parent',ax);
%     end
% catch ME
%     warning('Logo "%s" could not be shown (%s).',fileName,ME.message);
% end
% end

% function placeLogo(fig,fileName,pos)
% % Render PNG/JPG with alpha onto a tiny axes.
% 
% try
%     p = getAssetPath(fileName);
%     [im,~,alpha] = imread(p);
%     ax = axes('Parent',fig,'Units','pixels','Position',pos, ...
%               'Visible','off', 'XColor','none', 'YColor','none');
%     axis(ax, 'off');  % full cleanup of ticks and frame
%     if ~isempty(alpha)
%         h = image(im,'Parent',ax);  
%         h.AlphaData = double(alpha)/255;
%     else
%         image(im,'Parent',ax);
%     end
% catch ME
%     warning('Logo "%s" could not be shown (%s).',fileName,ME.message);
% end
% end

function placeLogo(fig, fileName, pos)
% placeLogo - Show image without axis artifacts, works in deployed apps

try
    imgPath = getAssetPath(fileName);
    [img, ~, alpha] = imread(imgPath);
    
    ax = axes('Parent', fig, 'Units', 'pixels', 'Position', pos, ...
        'Visible', 'off', 'XTick', [], 'YTick', [], 'Box', 'off');
    
    if ~isempty(alpha)
        h = image(img, 'Parent', ax);
        h.AlphaData = double(alpha)/255;
    else
        image(img, 'Parent', ax);
    end

    set(ax, 'Visible', 'off', ...
        'XColor', 'none', 'YColor', 'none', ...
        'XTick', [], 'YTick', [], 'Box', 'off');
    
    uistack(ax, 'top');
catch ME
    warning('Logo "%s" could not be shown (%s).', fileName, ME.message);
end
end

