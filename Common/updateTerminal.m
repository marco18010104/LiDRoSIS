function updateTerminal(txtHandle, newText)
    oldText = get(txtHandle, 'String');
    if ischar(oldText)
        oldText = cellstr(oldText);
    end
    newText = cellstr(newText);
    combinedText = [oldText; newText];
    % Limita número de linhas para evitar overflow
    maxLines = 1000;
    if numel(combinedText) > maxLines
        combinedText = combinedText(end-maxLines+1:end);
    end
    set(txtHandle, 'String', combinedText);
    drawnow;
end