%% RUN_PROJECT
% Ejecuta el pipeline final del proyecto IPOM/IRIS:
% 0) opcionalmente regenera history.csv desde Data.csv;
% 1) identifica el baseline IPOM exacto;
% 2) simula el escenario alternativo final.
%
% Uso normal:
%   run_project
%
% Para regenerar data/processed/history.csv desde data/raw/Data.csv:
%   IPOM_REBUILD_HISTORY = true;
%   run_project
%
% Para generar también PDFs IRIS:
%   IPOM_RUN_REPORT = true;
%   run_project

close all; clearvars -except IPOM_RUN_REPORT IPOM_REBUILD_HISTORY; clc;

cfg = startup_ipom();

if exist('dbload', 'file') ~= 2 || exist('model', 'file') ~= 2
    warning(['No encuentro funciones IRIS Toolbox en el path. ', ...
             'Abre MATLAB con IRIS instalado/agregado al path antes de correr el pipeline.']);
end

if ~exist('IPOM_RUN_REPORT', 'var')
    IPOM_RUN_REPORT = false;
end
if ~exist('IPOM_REBUILD_HISTORY', 'var')
    IPOM_REBUILD_HISTORY = false;
end

fprintf('\n============================================================\n');
fprintf('PIPELINE FINAL IPOM/IRIS\n');
fprintf('Regenerar history.csv: %d\n', IPOM_REBUILD_HISTORY);
fprintf('Reportes IRIS: %d\n', IPOM_RUN_REPORT);
fprintf('============================================================\n');

if IPOM_REBUILD_HISTORY || exist(cfg.historyFile, 'file') ~= 2
    fprintf('\nRegenerando history.csv desde Data.csv...\n');
    run(fullfile(cfg.scriptDir, 'step00_build_history_from_data.m'));

    % step00 limpia el workspace; recuperar config y flags.
    cfg = startup_ipom();
    if ~exist('IPOM_RUN_REPORT', 'var')
        IPOM_RUN_REPORT = false;
    end
    if ~exist('IPOM_REBUILD_HISTORY', 'var')
        IPOM_REBUILD_HISTORY = false;
    end
end

run(fullfile(cfg.scriptDir, 'step01_identificar_shocks_ipom.m'));

% step01 limpia el workspace por diseño heredado; se reinicializa ruta/config.
cfg = startup_ipom();
if ~exist('IPOM_RUN_REPORT', 'var')
    IPOM_RUN_REPORT = false;
end
run(fullfile(cfg.scriptDir, 'step02_fcast_alt_ipom.m'));

% step02 también limpia el workspace; se reinicializa config antes del resumen.
cfg = startup_ipom();

fprintf('\nPipeline terminado. Archivos principales:\n');
fprintf(' - %s\n', cfg.historyFile);
fprintf(' - %s\n', cfg.baselineFile);
fprintf(' - %s\n', cfg.baselineShocksFile);
fprintf(' - %s\n', cfg.altScenarioFile);
fprintf(' - %s\n', cfg.altScenarioGenericFile);
