function cfg = config_ipom()
%CONFIG_IPOM  Centraliza rutas del proyecto IPOM/IRIS.
%
% La función no depende del directorio actual. Puede llamarse desde cualquier
% script siempre que la raíz del proyecto esté en el path de MATLAB.

    thisFile = mfilename('fullpath');
    cfg.projectRoot = fileparts(thisFile);

    cfg.srcDir          = fullfile(cfg.projectRoot, 'src');
    cfg.matlabDir       = fullfile(cfg.srcDir, 'matlab');
    cfg.modelDir        = fullfile(cfg.matlabDir, 'model');
    cfg.scriptDir       = fullfile(cfg.matlabDir, 'scripts');

    cfg.dataDir         = fullfile(cfg.projectRoot, 'data');
    cfg.dataRawDir      = fullfile(cfg.dataDir, 'raw');
    cfg.dataProcessedDir= fullfile(cfg.dataDir, 'processed');

    cfg.outputDir       = fullfile(cfg.projectRoot, 'output');
    cfg.rawOutputDir    = fullfile(cfg.outputDir, 'raw');
    cfg.reportDir       = fullfile(cfg.outputDir, 'reports');
    cfg.tableDir        = fullfile(cfg.outputDir, 'tables');

    cfg.modelFile       = fullfile(cfg.modelDir, 'minimep0.model');
    cfg.dataFile        = fullfile(cfg.dataRawDir, 'Data.csv');
    cfg.historyFile     = fullfile(cfg.dataProcessedDir, 'history.csv');
    cfg.ipomPathsFile   = fullfile(cfg.dataProcessedDir, 'ipom_paths.csv');

    cfg.baselineFile    = fullfile(cfg.rawOutputDir, 'fcast_ipom_exact.csv');
    cfg.baselineShocksFile = fullfile(cfg.rawOutputDir, 'fcast_ipom_with_shocks.csv');
    cfg.altScenarioFile = fullfile(cfg.rawOutputDir, 'fcast_alt_petroleo_gap.csv');
    cfg.altScenarioGenericFile = fullfile(cfg.rawOutputDir, 'fcast_alt_escenario.csv');

    dirs = {cfg.dataRawDir, cfg.dataProcessedDir, cfg.rawOutputDir, cfg.reportDir, cfg.tableDir};
    for i = 1:numel(dirs)
        if exist(dirs{i}, 'dir') ~= 7
            mkdir(dirs{i});
        end
    end
end
