function p = getAssetPath(fileName)
    if isdeployed
        ctf = ctfroot;
        trials = { fullfile(ctf,'assets',fileName), ...
                   fullfile(ctf,fileName), ...
                   fullfile(ctf,'LiDRoSIS','assets',fileName) };
        for k = 1:numel(trials)
            if exist(trials{k},'file')==2, p = trials{k}; return; end
        end
        hit = dir(fullfile(ctf,'**',fileName));
        if ~isempty(hit)
            p = fullfile(hit(1).folder,hit(1).name);  return;
        end
    else
        p = fullfile(fileparts(mfilename('fullpath')),'assets',fileName);
        if exist(p,'file')==2, return; end
    end
    error('Asset "%s" not found inside deployment.',fileName);
end
