function launchGui(theme,parentFig,assetsPath)
% Choose folders, build imageTable, call guiLD / guiROS
    rootDir = uigetdir(pwd,sprintf('Select folder with %s images',theme));
    if rootDir==0, return; end

    files = dir(fullfile(rootDir,'**','*.tif'));
    imgData = {};
    for k=1:numel(files)
        p = erase(fullfile(files(k).folder,files(k).name),rootDir);
        parts = strsplit(p,filesep);  
        parts = parts(~cellfun('isempty',parts));
        if numel(parts)<6 || ~strcmpi(parts{2},theme), continue; end
    
        imgData(end+1,:) = {fullfile(files(k).folder, files(k).name), parts{1}, parts{3}, parts{4}, parts{5}, strjoin(parts(6:end-1),'_')}; %#ok<AGROW>
    end
    if isempty(imgData), errordlg('No images found.'); return; end
    
    T = cell2table(imgData, 'VariableNames', ...
        {'FullPath','CellLine','IrradiationSource','Nanoparticles','Dose','Objective'});

    outDir = uigetdir(pwd,'Select output folder');  if outDir==0, return; end

    close(parentFig);   % launch chosen GUI
    switch theme
        case 'LDs', guiLD(T,outDir,assetsPath);
        case 'ROS', guiROS(T,outDir,assetsPath);
    end
end
