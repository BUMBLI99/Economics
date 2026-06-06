%% RUN_BUILD_HISTORY
% Regenera data/processed/history.csv desde data/raw/Data.csv.

close all; clearvars; clc;
cfg = startup_ipom();
run(fullfile(cfg.scriptDir, 'step00_build_history_from_data.m'));
