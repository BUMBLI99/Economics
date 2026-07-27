function run_all_ipom()
%RUN_ALL_IPOM Punto de entrada ordenado para el bloque Matlab/IRIS del IPoM.
%
% Uso recomendado desde MATLAB:
%   cd('D:\Users\mullo\Documents\GitHub\Economics\matlab\ipom\src')
%   run_all_ipom
%
% Este wrapper:
%   1. Activa IRIS usando setup_ipom_project().
%   2. Ejecuta identificar_shocks_ipom.m si cfg.runBaseline=true.
%   3. Ejecuta fcast_alt_ipom.m si cfg.runAlternative=true.
%   4. Guarda outputs crudos en matlab/ipom/outputs/raw_iris/.
%
% No copia scripts a runtime. Los scripts usan rutas absolutas desde
% config_ipom(), para evitar errores por directorio actual (pwd).

    close all; clc;

    cfg = setup_ipom_project();

    fprintf('\n============================================================\n');
    fprintf('Ejecucion IPoM/IRIS\n');
    fprintf('runMakeData:    %d\n', cfg.runMakeData);
    fprintf('runBaseline:    %d\n', cfg.runBaseline);
    fprintf('runAlternative: %d\n', cfg.runAlternative);
    fprintf('PDF reports:    %d\n', cfg.runIrisPdfReports);
    fprintf('============================================================\n\n');

    if cfg.runMakeData
        fprintf('\n>>> Reconstruyendo history.csv desde Data.csv...\n');
        local_run_script(fullfile(cfg.srcDir, 'makedata.m'), cfg.runIrisPdfReports);
    end

    if cfg.runBaseline
        fprintf('\n>>> Ejecutando baseline IPoM identificado...\n');
        local_run_script(fullfile(cfg.srcDir, 'identificar_shocks_ipom.m'), cfg.runIrisPdfReports);
    else
        fprintf('\n>>> Baseline omitido por configuracion.\n');
    end

    if cfg.runAlternative
        fprintf('\n>>> Ejecutando escenario alternativo editable...\n');
        local_run_script(fullfile(cfg.srcDir, 'fcast_alt_ipom.m'), cfg.runIrisPdfReports);
    else
        fprintf('\n>>> Escenario alternativo omitido por configuracion.\n');
    end

    fprintf('\nListo: outputs IRIS disponibles en:\n  %s\n', cfg.rawOutputDir);
    fprintf('Siguiente paso desde la raiz del repo:\n');
    fprintf('  & "C:\Program Files\R\R-4.3.2\bin\x64\Rscript.exe" scripts\03_build_ipom_outputs.R\n');
    fprintf('  quarto render proyectos \ ipom-iris.qmd\n');
end

function local_run_script(scriptFile, runReport)
    if exist(scriptFile, 'file') ~= 2
        error('No existe el script requerido: %s', scriptFile);
    end

    % Los scripts usan clearvars -except IPOM_RUN_REPORT. Al ejecutarlos
    % dentro de esta subfuncion, ese clearvars no borra las variables del
    % wrapper principal.
    IPOM_RUN_REPORT = runReport; %#ok<NASGU>
    run(scriptFile);
end
