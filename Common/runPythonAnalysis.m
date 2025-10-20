function runPythonAnalysis(outputDir)
% RUNPYTHONANALYSIS - Executa script Python selecionado pelo utilizador
%
%   Permite ao utilizador escolher manualmente um script `.py` e executá-lo,
%   passando o diretório de resultados como argumento.
%
% AUTHOR:
%   Ferreira, M. - FCUL-IST, 2025

    [file, path] = uigetfile('*.py', 'Seleciona o Script Python de Análise');
    
    if isequal(file, 0)
        disp('❌ Análise cancelada: nenhum script selecionado.');
        return;
    end

    scriptPath = fullfile(path, file);

    if ~endsWith(scriptPath, '.py')
        errordlg('O ficheiro selecionado não é um script Python (*.py).', 'Erro');
        return;
    end

    % Construir comando
    cmd = sprintf('python "%s" "%s"', scriptPath, outputDir);
    disp(['⚙️ A executar: ', cmd]);

    % Executar comando
    [status, cmdout] = system(cmd);

    % Resultado
    if status == 0
        msgbox('✅ Análise estatística concluída com sucesso.', 'Sucesso');
    else
        errordlg(sprintf('❌ Erro ao executar script:\n\n%s', cmdout), 'Erro');
    end
end
