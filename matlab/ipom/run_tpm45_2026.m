%% RUN_TPM45_2026
% Ejecuta una corrida alternativa manteniendo todo igual al escenario vigente
% y fijando la TPM en 4.5% durante 2026.
%
% Uso normal:
%   run_tpm45_2026
%
% Si cambiaste data/raw/Data.csv y quieres reconstruir history.csv:
%   IPOM_REBUILD_HISTORY = true;
%   run_tpm45_2026
%
% Si quieres generar PDF IRIS:
%   IPOM_RUN_REPORT = true;
%   run_tpm45_2026

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
fprintf('ESCENARIO TPM 4.5 EN 2026 Y RETORNO IPOM DESDE 2027\n');
fprintf('Regenerar history.csv: %d\n', IPOM_REBUILD_HISTORY);
fprintf('Reportes IRIS: %d\n', IPOM_RUN_REPORT);
fprintf('============================================================\n');

if IPOM_REBUILD_HISTORY || exist(cfg.historyFile, 'file') ~= 2
    fprintf('\nRegenerando history.csv desde Data.csv...\n');
    run(fullfile(cfg.scriptDir, 'step00_build_history_from_data.m'));
    cfg = startup_ipom();
end

% Siempre rehacer baseline antes del escenario, para asegurar consistencia.
run(fullfile(cfg.scriptDir, 'step01_identificar_shocks_ipom.m'));

% step01 limpia workspace; recuperar config y flags.
cfg = startup_ipom();
if ~exist('IPOM_RUN_REPORT', 'var')
    IPOM_RUN_REPORT = false;
end

run(fullfile(cfg.scriptDir, 'step02_fcast_alt_tpm45_2026.m'));

cfg = startup_ipom();

fprintf('\nCorrida TPM 4.5 con retorno IPOM terminada. Archivos principales:\n');
fprintf(' - %s\n', cfg.baselineFile);
fprintf(' - %s\n', fullfile(cfg.rawOutputDir, 'fcast_alt_tpm45_2026.csv'));
fprintf(' - %s  [copia compatible]\n', cfg.altScenarioGenericFile);
fprintf(' - %s\n', fullfile(cfg.reportDir, 'Escenario_TPM45_2026.pdf'));
