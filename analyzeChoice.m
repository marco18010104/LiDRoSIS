% function analyzeChoice()
% % ANALYZECHOICE - GUI launcher for the LiDRoS platform (Lipid Droplets & ROS).
% %
% %   Provides a graphical entry point for selecting the type of image analysis.
% %   Based on user selection, it loads either the LD or ROS analysis GUI.
% %
% %   AUTHOR:
% %       Prepared for scientific use by Ferreira, M., FCUL-IST, 2025
% 
% % --------------------- RESOLVE ROOT PATH ---------------------
% if isdeployed
%     rootPath = ctfroot;  % Runtime path for compiled apps
% else
%     rootPath = fileparts(mfilename('fullpath'));  % Script location
% end
% assetsPath = fullfile(rootPath, 'assets');  % Path to logos and splash
% 
% % --------------------- CREATE MAIN WINDOW ---------------------
% fig = figure('Name', 'LiDRoS Analysis Launcher', ...
%              'NumberTitle', 'off', ...
%              'Color', 'k', ...
%              'MenuBar', 'none', ...
%              'ToolBar', 'none', ...
%              'Resize', 'off', ...
%              'Position', [600, 400, 600, 400]);
% movegui(fig, 'center');
% 
% % --------------------- BACKGROUND GRADIENT ---------------------
% bgAx = axes('Parent', fig, 'Units', 'normalized', 'Position', [0 0 1 1]);
% [x, y] = meshgrid(linspace(0, 1, 600), linspace(0, 1, 400));
% gradientImg = cat(3, ...
%     0.1 + 0.4 * y, ... % Red gradient
%     0.1 + 0.4 * y, ... % Green gradient
%     0.1 + 0.6 * y);    % Blue gradient
% image(bgAx, gradientImg); axis off;
% uistack(bgAx, 'bottom');
% 
% % --------------------- LOGOS ---------------------
% placeLogo(fig, 'logo_fcul.png', [20, 330, 80, 50]);
% placeLogo(fig, 'logo_ist.png', [500, 330, 80, 50]);
% placeLogo(fig, 'appSplashScreen.jpeg', [230, 280, 140, 100]);
% 
% 
% % --------------------- TITLE ---------------------
% uicontrol('Style', 'text', ...
%     'Parent', fig, ...
%     'String', 'Select Type of Analysis', ...
%     'ForegroundColor', 'w', ...
%     'BackgroundColor', 'none', ...
%     'FontSize', 16, ...
%     'FontWeight', 'bold', ...
%     'Position', [180, 230, 240, 30]);
% 
% % --------------------- MAIN BUTTONS ---------------------
% uicontrol('Style', 'pushbutton', ...
%     'String', 'For Lipid Droplets (LDs)', ...
%     'Position', [160, 180, 280, 40], ...
%     'FontSize', 12, ...
%     'Callback', @(~, ~) launchGui('LDs', fig));
% 
% uicontrol('Style', 'pushbutton', ...
%     'String', 'For Reactive Oxygen Species (ROS)', ...
%     'Position', [160, 120, 280, 40], ...
%     'FontSize', 12, ...
%     'Callback', @(~, ~) launchGui('ROS', fig));
% 
% uicontrol('Style', 'pushbutton', ...
%     'String', 'Exit', ...
%     'Position', [160, 60, 280, 40], ...
%     'FontSize', 12, ...
%     'Callback', @(~, ~) close(fig));
% end
% 
% 
% % ----------------------------------------------------------------------
% % AUXILIAR FUNCTIONS
% 
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
% 
% 
% 
% % ----------------------------------------------------------------------
% function launchGui(theme, parentFig)
% % Opens file dialog, prepares imageTable and launches specific GUI.
% 
%     rootDir = uigetdir(pwd, sprintf('Select folder with %s images', theme));
%     if isequal(rootDir, 0)
%         disp('No input folder selected.');
%         return;
%     end
% 
%     % Recursively search for .tif images and extract metadata from folder structure
%     files = dir(fullfile(rootDir, '**', '*.tif'));
%     imageData = {};
%     for k = 1:numel(files)
%         fullPath = fullfile(files(k).folder, files(k).name);
%         relPath = erase(fullPath, rootDir);
%         parts = strsplit(relPath, filesep);
%         parts = parts(~cellfun('isempty', parts));
%         if numel(parts) < 6, continue; end
%         if ~strcmp(parts{2}, theme), continue; end
% 
%         % Extract metadata
%         cellLine  = parts{1};
%         source    = parts{3};
%         np        = parts{4};
%         dose      = parts{5};
%         objective = strjoin(parts(6:end-1), '_');
% 
%         imageData(end+1, :) = {fullPath, cellLine, source, np, dose, objective}; %#ok<AGROW>
%     end
% 
%     if isempty(imageData)
%         errordlg(sprintf('No .tif images found for theme "%s".', theme), 'No Images Found');
%         return;
%     end
% 
%     imageTable = cell2table(imageData, 'VariableNames', ...
%         {'FullPath','CellLine','IrradiationSource','Nanoparticles','Dose','Objective'});
% 
%     outputDir = uigetdir(pwd, 'Select folder to save results');
%     if isequal(outputDir, 0)
%         disp('No output folder selected.');
%         return;
%     end
% 
%     close(parentFig);  % Close launcher
% 
%     % Launch specific GUI
%     switch theme
%         case 'LDs'
%             guiLD(imageTable, outputDir);
%         case 'ROS'
%             guiROS(imageTable, outputDir);
%     end
% end
% 

% function analyzeChoice()
% % ANALYZECHOICE  Launcher GUI for the LiDRoS platform.
% %
% %   Lets the user pick LD or ROS analysis, opens the corresponding GUI,
% %   and handles asset paths seamlessly in both MATLAB and compiled apps.
% %
% %   AUTHOR:
% %       Prepared for scientific use by Ferreira, M., FCUL-IST, 2025
% 
% %% ── Resolve root & assets paths ────────────────────────────────────────
% if isdeployed
%     rootPath   = ctfroot;            % Path inside the CTF archive
% else
%     rootPath   = fileparts(mfilename('fullpath'));
% end
% assetsPath = fullfile(rootPath, 'assets');  % logos, splash, help.pdf
% 
% %% ── Create main window ────────────────────────────────────────────────
% scr   = get(0,'ScreenSize');
% figW  = 640;  figH = 440;
% figX  = (scr(3)-figW)/2;  figY = (scr(4)-figH)/2;
% 
% fig = figure( ...
%     'Name', 'LiDRoS Analysis Launcher', ...
%     'NumberTitle','off', ...
%     'Color',      [0.05 0.05 0.05], ...
%     'MenuBar',    'none', ...
%     'ToolBar',    'none', ...
%     'Resize',     'off', ...
%     'Position',   [figX figY figW figH]);
% 
% %% ── Background gradient ───────────────────────────────────────────────
% bgAx = axes('Parent',fig,'Position',[0 0 1 1],'Units','normalized');
% [x,y] = meshgrid(linspace(0,1,figW), linspace(0,1,figH));
% bg    = cat(3, 0.1+0.4*y, 0.1+0.4*y, 0.1+0.6*y);
% image(bgAx,bg);  axis(bgAx,'off');  uistack(bgAx,'bottom');
% 
% %% ── Logos & splash ────────────────────────────────────────────────────
% placeLogo(fig,'logo_fcul.png',         [20  360 80 60]);
% placeLogo(fig,'logo_ist.png',          [540 360 80 60]);
% placeLogo(fig,'appSplashScreen.jpeg',  [250 300 140 90]);
% 
% %% ── Title label ───────────────────────────────────────────────────────
% uicontrol('Style','text','Parent',fig, ...
%     'String','Select Type of Analysis', ...
%     'FontSize',18,'FontWeight','bold','FontName','Segoe UI', ...
%     'ForegroundColor','w','BackgroundColor','none', ...
%     'Position',[180 245 280 35]);
% 
% %% ── Main buttons  ─────────────────────────────────────────────────────
% btnOpts = {'Parent',fig,'FontSize',13,'FontName','Segoe UI',...
%            'ForegroundColor','w','BackgroundColor',[0.2 0.6 0.4]};
% uicontrol(btnOpts{:}, ...
%     'String','For Lipid Droplets (LDs)', ...
%     'Position',[180 190 280 45], ...
%     'TooltipString','Analyse Nile‑Red lipid‑droplet images', ...
%     'Callback',@(~,~) launchGui('LDs',fig,assetsPath));
% 
% uicontrol(btnOpts{:}, ...
%     'String','For Reactive Oxygen Species (ROS)', ...
%     'Position',[180 130 280 45], ...
%     'BackgroundColor',[0.4 0.4 0.8], ...
%     'TooltipString','Analyse ROS microscopy images', ...
%     'Callback',@(~,~) launchGui('ROS',fig,assetsPath));
% 
% uicontrol(btnOpts{:}, ...
%     'String','📖  Help Manual', ...
%     'BackgroundColor',[0.25 0.25 0.25], ...
%     'FontSize',12, ...
%     'Position',[70  70 160 40], ...
%     'Callback',@(~,~) open(fullfile(assetsPath,'help.pdf')));
% 
% uicontrol(btnOpts{:}, ...
%     'String','Exit', ...
%     'BackgroundColor',[0.55 0.2 0.2], ...
%     'Position',[410 70 160 40], ...
%     'Callback',@(~,~) close(fig));
% end
% 
% function analyzeChoice()
% % ANALYZECHOICE  Fullscreen GUI launcher for the LiDRoS platform.
% %
% %   Allows selection between LDs and ROS analysis with styled background
% %   and transparent overlay highlighting the app splash.
% %
% %   AUTHOR:
% %       Prepared for scientific use by Ferreira, M., FCUL-IST, 2025
% 
% %% ── Resolve root path and assets ─────────────────────────────────────
% if isdeployed
%     rootPath = ctfroot;
% else
%     rootPath = fileparts(mfilename('fullpath'));
% end
% assetsPath = fullfile(rootPath, 'assets');
% 
% if isdeployed
%     disp('--- CONTENTS OF ctfroot ---------------------------');
%     disp(ctfroot);
%     disp(ls(ctfroot));                 % top‑level
%     if exist(fullfile(ctfroot,'assets'),'dir')
%         disp('--- CONTENTS OF ctfroot\assets ------------------');
%         disp(ls(fullfile(ctfroot,'assets')));
%     end
%     disp('---------------------------------------------------');
% end
% 
% %% ── Create fullscreen figure (not true full screen, but maximized window) ─
% scr = get(0, 'ScreenSize');  % [left bottom width height]
% fig = figure('Name','LiDRoSIS Analysis Launcher', ...
%     'NumberTitle','off', ...
%     'MenuBar','none', ...
%     'ToolBar','none', ...
%     'Color','k', ...
%     'Units','pixels', ...
%     'Position', scr, ...
%     'Resize','off');
% 
% %% ── Load background image (optional) ──────────────────────────────────
% bgImgPath = fullfile(assetsPath, 'backgroundInitialScreen.jpg');  % change as needed
% if exist(bgImgPath, 'file')
%     bg = imread(bgImgPath);
%     axBG = axes('Parent', fig, 'Units', 'normalized', 'Position', [0 0 1 1]);
%     imshow(bg, 'Parent', axBG);
%     axis(axBG, 'off');
%     uistack(axBG, 'bottom');
% end
% 
% %% ── Overlay transparency layer to darken background ──────────────────
% overlayAx = axes('Parent', fig, 'Position', [0 0 0 0], 'Units','normalized');
% alphaLayer = cat(3, ones(scr(4), scr(3)) * 0.1, ...
%                     ones(scr(4), scr(3)) * 0.1, ...
%                     ones(scr(4), scr(3)) * 0.1);  % dark gray filter
% image(overlayAx, alphaLayer);
% set(overlayAx, 'XTick', [], 'YTick', []);
% uistack(overlayAx, 'top');
% set(overlayAx, 'HitTest','off');  % let buttons be clickable
% set(get(overlayAx,'Children'), 'AlphaData', 0.6);  % transparency
% uistack(overlayAx, 'bottom');  % just above background
% 
% %% ── Place logos and splash screen ─────────────────────────────────────
% placeLogo(fig,'logo_fcul.png',        [40,            scr(4)-160, 200, 90]);
% placeLogo(fig,'logo_ist.png',         [scr(3)-240,    scr(4)-160, 200, 90]);
% splashW = 200;
% splashH = 160;  % Increased height for better aspect ratio
% splashX = scr(3)/2 - splashW/2;
% splashY = scr(4) - 190 - (splashH - 120);  % Shift down by +40
% 
% placeLogo(fig, 'appSplashScreen.jpeg', [splashX, splashY, splashW, splashH]);
% 
% %% ── Title text ───────────────────────────────────────────────────────
% uicontrol('Style','text','Parent',fig, ...
%     'String','Select Type of Analysis', ...
%     'FontSize', 18, ...
%     'FontWeight','bold', ...
%     'ForegroundColor','b', ...
%     'BackgroundColor','w', ...
%     'Position',[scr(3)/2 - 160, scr(4)-280, 320, 40]);
% 
% %% ── Main buttons ─────────────────────────────────────────────────────
% btnW = 320;  btnH = 60;
% baseY = scr(4)/2 - btnH;
% baseX = scr(3)/2 - btnW/2;
% btnOpts = {'Parent', fig, 'FontSize', 12, 'FontName', 'Segoe UI', ...
%     'ForegroundColor', 'w', 'FontWeight', 'bold'};
% 
% uicontrol(btnOpts{:}, ...
%     'Style','pushbutton', ...
%     'String','Analyze Lipid Droplets (LDs)', ...
%     'BackgroundColor',[0.1 0.6 0.4], ...
%     'Position',[baseX, baseY+80, btnW, btnH], ...
%     'Callback', @(~,~) launchGui('LDs', fig, assetsPath));
% 
% uicontrol(btnOpts{:}, ...
%     'Style','pushbutton', ...
%     'String','Analyze Reactive Oxygen Species (ROS)', ...
%     'BackgroundColor',[0.4 0.4 0.8], ...
%     'Position',[baseX, baseY, btnW, btnH], ...
%     'Callback', @(~,~) launchGui('ROS', fig, assetsPath));
% 
% uicontrol(btnOpts{:}, ...
%     'Style','pushbutton', ...
%     'String','Help Manual', ...
%     'BackgroundColor',[0.0 0.0 0.0], ...
%     'Position',[baseX, baseY-100, 160, 50], ...
%     'Callback', @(~,~) open(fullfile(assetsPath,'help.pdf')));
% 
% uicontrol(btnOpts{:}, ...
%     'Style','pushbutton', ...
%     'String','Exit', ...
%     'BackgroundColor',[1.0 0.0 0.0], ...
%     'Position',[baseX+btnW-160, baseY-100, 160, 50], ...
%     'Callback', @(~,~) close(fig));
% 
% %% ── Footer text ──────────────────────────────────────────────────────
% uicontrol('Style','text','Parent',fig, ...
%     'String','LiDRoSIS 1.0', ...
%     'FontSize', 10, ...
%     'FontWeight','bold', ...
%     'ForegroundColor','w', ...
%     'BackgroundColor','none', ...
%     'HorizontalAlignment','left', ...
%     'Position',[20, 10, 160, 20]);
% 
% uicontrol('Style','text','Parent',fig, ...
%     'String','App developed by: Marco Ferreira • fc60327@alunos.fc.ul.pt', ...
%     'FontSize', 10, ...
%     'ForegroundColor','w', ...
%     'BackgroundColor','none', ...
%     'HorizontalAlignment','right', ...
%     'Position',[scr(3)-500, 0, 500, 20]);
% 
% end

function analyzeChoice()
% ANALYZECHOICE  Full‑screen GUI launcher for the LiDRoS platform.
%
%   AUTHOR:
%       Prepared for scientific use by Ferreira, M., FCUL‑IST, 2025

% ── Resolve root & asset root ──────────────────────────────────────────
if isdeployed
    rootPath = ctfroot;          % runtime temp folder
else
    rootPath = fileparts(mfilename('fullpath'));
end

assetsPath = fullfile(rootPath, 'assets');

% --- debug listing -----------------------------------------------------
if isdeployed
    disp('--- CONTENTS OF ctfroot -----------------------------------');
    disp(ctfroot);  disp(ls(ctfroot));
    hit = dir(fullfile(ctfroot,'**','backgroundInitialScreen.jpg'));
    fprintf('backgroundInitialScreen.jpg found? %d file(s)\n',numel(hit));
    disp('-----------------------------------------------------------');
end
% -----------------------------------------------------------------------

%% ── GUI Figure (maximised window) ─────────────────────────────────────
scr = get(0,'ScreenSize');               % [left bottom w h]
fig = figure('Name','LiDRoSIS Analysis Launcher', ...
    'NumberTitle','off','MenuBar','none','ToolBar','none', ...
    'Color','k','Units','pixels','Position',scr,'Resize','off');

%% ── Load background image ─────────────────────────────────────────────
try
    bg = imread(getAssetPath('backgroundInitialScreen.jpg'));

    axBG = axes('Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [0 0 1 1], ...
        'Visible', 'off', ...
        'XTick', [], 'YTick', [], 'Box', 'off');

    imshow(bg, 'Parent', axBG);

    set(axBG, 'Visible', 'off', ...
        'XColor', 'none', 'YColor', 'none', ...
        'XTick', [], 'YTick', [], 'Box', 'off');

    uistack(axBG, 'bottom');  % send behind all controls
catch ME
    warning('%s', 'Could not show background image: %s', ME.message);
end

%% ── Semi‑transparent dark overlay ────────────────────────────────────
overlayAx = axes('Parent',fig,'Units','normalized','Position',[0 0 1 1], ...
                 'Visible','off','HitTest','off');
alphaLayer = repmat(0.1,[scr(4) scr(3) 3]);   % dark gray
hAlpha = image(alphaLayer,'Parent',overlayAx);
hAlpha.AlphaData = 0.6;   % 60 % opacity
uistack(overlayAx,'bottom');  % just above background

%% ── Logos & splash ───────────────────────────────────────────────────
placeLogo(fig,'logo_fcul.png',[40 scr(4)-160 200 90]);
placeLogo(fig,'logo_ist.png', [scr(3)-240 scr(4)-160 200 90]);

splashW = 200;  splashH = 160;
splashX = scr(3)/2 - splashW/2;
splashY = scr(4)   - 190 - (splashH-120);   % shift down 40 px
placeLogo(fig,'appSplashScreen.jpeg',[splashX splashY splashW splashH]);

%% ── Title ────────────────────────────────────────────────────────────
uicontrol('Style','text','Parent',fig, ...
    'String','Select Type of Analysis', ...
    'FontSize',18,'FontWeight','bold', ...
    'ForegroundColor','w','BackgroundColor','none', ...
    'Position',[scr(3)/2-160 scr(4)-280 320 40]);

%% ── Main buttons ─────────────────────────────────────────────────────
btnW = 320; btnH = 60;
baseY = scr(4)/2 - btnH;
baseX = scr(3)/2 - btnW/2;
btnStyle = {'Parent',fig,'FontSize',12,'FontName','Segoe UI', ...
            'ForegroundColor','w','FontWeight','bold'};

uicontrol(btnStyle{:},'Style','pushbutton', ...
    'String','Analyze Lipid Droplets (LDs)', ...
    'BackgroundColor',[0.1 0.6 0.4], ...
    'Position',[baseX baseY+80 btnW btnH], ...
    'Callback',@(~,~) launchGui('LDs',fig, assetsPath));

uicontrol(btnStyle{:},'Style','pushbutton', ...
    'String','Analyze Reactive Oxygen Species (ROS)', ...
    'BackgroundColor',[0.4 0.4 0.8], ...
    'Position',[baseX baseY btnW btnH], ...
    'Callback',@(~,~) launchGui('ROS',fig, assetsPath));

uicontrol(btnStyle{:},'Style','pushbutton', ...
    'String','Help Manual', ...
    'BackgroundColor',[0.2 0.2 0.2], ...
    'Position',[baseX baseY-100 160 50], ...
    'Callback',@(~,~) openAsset('help.pdf'));

uicontrol(btnStyle{:},'Style','pushbutton', ...
    'String','Exit', ...
    'BackgroundColor',[0.55 0.20 0.20], ...
    'Position',[baseX+btnW-160 baseY-100 160 50], ...
    'Callback',@(~,~) close(fig));

%% ── Footer ───────────────────────────────────────────────────────────
uicontrol('Style','text','Parent',fig, ...
    'String','LiDRoSIS 1.0', ...
    'FontSize',10,'FontWeight','bold', ...
    'ForegroundColor','w','BackgroundColor','none', ...
    'HorizontalAlignment','left','Position',[20 10 160 20]);

uicontrol('Style','text','Parent',fig, ...
    'String','App developed by: Marco Ferreira · fc60327@alunos.fc.ul.pt', ...
    'FontSize',10,'ForegroundColor','w','BackgroundColor','none', ...
    'HorizontalAlignment','right', ...
    'Position',[scr(3)-500 10 500 20]);
end
