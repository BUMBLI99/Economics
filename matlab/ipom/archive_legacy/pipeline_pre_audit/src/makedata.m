%MAKEDATA Reconstruye history.csv desde inputs/Data.csv.
%
% Normalmente NO es necesario correrlo si inputs/history.csv ya existe.
% Para activarlo dentro del flujo completo, cambia cfg.runMakeData=true en
% config_ipom.m.

close all;
clearvars -except IPOM_RUN_REPORT;
clc;

cfg_ipom = config_ipom();

dataFile    = fullfile(cfg_ipom.inputDir, 'Data.csv');
historyFile = fullfile(cfg_ipom.inputDir, 'history.csv');

if exist(dataFile, 'file') ~= 2
    error('No existe Data.csv. Se esperaba encontrarlo en: %s', dataFile);
end

%% Load model to take parameters
[m,p,mss] = readmodel_alternativo(false); %#ok<ASGLU>

%% Load quarterly data
d = dbload(dataFile);

%% Growth rate qoq, yoy
exceptions = {''};
list = dbnames(d);

for i = 1:length(list)
    if isempty(strmatch(list{i}, exceptions, 'exact')) %#ok<MATCH2>
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
end

%% Save the database
dbsave(d, historyFile);

fprintf('history.csv actualizado en: %s\n', historyFile);
