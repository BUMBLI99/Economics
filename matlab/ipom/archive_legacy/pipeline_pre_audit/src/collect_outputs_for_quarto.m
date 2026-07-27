function collect_outputs_for_quarto()
%COLLECT_OUTPUTS_FOR_QUARTO Copia processed/ipom a matlab/ipom/outputs/quarto.
%
% Normalmente lo hace scripts/03_build_ipom_outputs.R desde R. Esta funcion
% queda como utilidad Matlab para documentar la separacion entre outputs IRIS
% crudos y outputs limpios para Quarto.

    cfg = setup_ipom_project();
    processedDir = fullfile(cfg.repoDir, 'data', 'processed', 'ipom');

    if ~exist(processedDir, 'dir')
        error('No existe %s. Ejecuta primero Rscript scripts/03_build_ipom_outputs.R', processedDir);
    end

    if ~exist(cfg.quartoOutputDir, 'dir')
        mkdir(cfg.quartoOutputDir);
    end

    files = dir(fullfile(processedDir, '*.csv'));
    for i = 1:numel(files)
        copyfile(fullfile(files(i).folder, files(i).name), fullfile(cfg.quartoOutputDir, files(i).name));
    end

    fprintf('Outputs limpios copiados a: %s\n', cfg.quartoOutputDir);
end
