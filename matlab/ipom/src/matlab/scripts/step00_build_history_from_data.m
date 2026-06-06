%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP00_BUILD_HISTORY_FROM_DATA
%%
%% Regenera data/processed/history.csv desde data/raw/Data.csv.
%% Normalmente NO es necesario correrlo si solo quieres reproducir el
%% forecast final, porque history.csv ya viene incluido en data/processed.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clearvars -except IPOM_RUN_REPORT IPOM_REBUILD_HISTORY; clc;

cfg = config_ipom();

if exist(cfg.dataFile, 'file') ~= 2
    error('No existe Data.csv en: %s', cfg.dataFile);
end

[m,p,mss] = readmodel_alternativo(false); %#ok<ASGLU>

d = dbload(cfg.dataFile);

exceptions = {''};
list = dbnames(d);

for i = 1:length(list)
    if isempty(strmatch(list{i}, exceptions, 'exact')) %#ok<STMATCH>
        if length(list{i}) > 1
            if strcmp('L_', list{i}(1:2))
                d.(['DLA_' list{i}(3:end)])  = 4*(d.(list{i}) - d.(list{i}){-1});
                d.(['D4L_' list{i}(3:end)]) = d.(list{i}) - d.(list{i}){-4};
            end
        end
    end
end

if isfield(d, 'DLA_CPI') && isfield(d, 'DLA_CPIXFE')
    d.DLA_CPIRES = d.DLA_CPI - d.DLA_CPIXFE;
else
    warning('No pude construir DLA_CPIRES porque falta DLA_CPI o DLA_CPIXFE.');
end

dbsave(d, cfg.historyFile);
fprintf('\nhistory.csv guardado en: %s\n', cfg.historyFile);
