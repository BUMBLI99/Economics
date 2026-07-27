function exportar_outputs_quarto(db, fileName)
%EXPORTAR_OUTPUTS_QUARTO Guarda una base IRIS en outputs/raw_iris.
%
% Uso despues de simular en Matlab/IRIS:
%   exportar_outputs_quarto(h, 'fcast_ipom_exact.csv');
%   exportar_outputs_quarto(d_alt, 'fcast_alt_escenario.csv');
%
% Luego actualizar la capa limpia:
%   Rscript scripts/03_build_ipom_outputs.R

    if nargin < 2
        error('Debes entregar una base IRIS y un nombre de archivo CSV.');
    end

    cfg = config_ipom();
    if ~exist(cfg.rawOutputDir, 'dir')
        mkdir(cfg.rawOutputDir);
    end

    outPath = fullfile(cfg.rawOutputDir, fileName);
    dbsave(db, outPath);
    fprintf('Output IRIS guardado para Quarto: %s\n', outPath);
end
