function openAsset(fileName)
p = getAssetPath(fileName);
if ispc
    system(['start "" "' p '"']);          % Windows
elseif ismac
    system(['open "' p '"']);              % macOS
else
    system(['xdg-open "' p '" &']);        % Linux
end
end
