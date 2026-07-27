
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_model_condicionado_externo_2026.m
%
% Objetivo:
%   Generar un diagnostico interno de lo que proyecta el modelo desde 2026Q1
%   dejando libres las variables domesticas clave, pero condicionando el
%   bloque externo con las trayectorias de un escenario ya generado.
%
% Pregunta que responde:
%   Que pasa con inflacion, TPM y brecha si impongo el bloque externo
%   petroleo/cobre/VIX/FFR/UST10/crecimiento externo/TCR, pero NO impongo
%   IPC, TPM ni output gap?
%
% Variables que se condicionan/exogenizan:
%   L_WTI, L_PCU, VIX, FFR, UST10, CRECSC, L_Z
%
% Variables que quedan libres/endogenas:
%   D4L_CPI, D4L_CPIXFE, DLA_CPI, DLA_CPIXFE, DLA_CPIRES,
%   TPM, RS_UNC, L_GDP_GAP, L_GDP, L_GDP_BAR
%
% Uso desde MATLAB:
%   cd('D:\Users\mullo\Documents\GitHub\Economics\matlab\ipom\src')
%   plot_model_condicionado_externo_2026
%
% Salidas:
%   matlab/ipom/diagnostics/fcast_model_cond_external_2026.csv
%   matlab/ipom/diagnostics/Forecast_Condicionado_Externo_2026.pdf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all;
clearvars -except IPOM_RUN_REPORT;
clc;

%% ============================================================
%% 0. Configuracion
%% ============================================================

cfg_ipom = setup_ipom_project();

% Horizonte del diagnostico.
startfcast = qq(2026,1);
endfcast   = qq(2028,4);

% Buffer para resolver la dinamica del modelo. El bloque externo solo se
% condiciona hasta endfcast; despues queda libre para cierre terminal.
bufferPeriods = 8;
fcastrange    = startfcast:(endfcast + bufferPeriods);
condRange     = startfcast:endfcast;

Plotrng = qq(2025,1):endfcast;
Histrng = qq(2025,1):qq(2025,4);
CondRng = condRange;

country  = 'Chile';
exchange = 'CHL/USA';

historyFile = fullfile(cfg_ipom.inputDir, 'history.csv');

% Fuente del bloque externo. Por defecto usa el escenario alternativo
% generico. Si existe el escenario petroleo-gap con nombre propio, lo usa.
conditioningFile = fullfile(cfg_ipom.rawOutputDir, 'fcast_alt_escenario.csv');
petroleoGapFile  = fullfile(cfg_ipom.rawOutputDir, 'fcast_alt_petroleo_gap.csv');

if exist(petroleoGapFile, 'file') == 2
    conditioningFile = petroleoGapFile;
end

baselineFile = fullfile(cfg_ipom.rawOutputDir, 'fcast_ipom_exact.csv');

if exist(historyFile, 'file') ~= 2
    error('No existe history.csv en: %s', historyFile);
end

if exist(conditioningFile, 'file') ~= 2
    error(['No existe el archivo de condicionamiento externo: %s\n' ...
           'Primero corre run_all_ipom o fcast_alt_ipom.m.'], conditioningFile);
end

% Carpeta privada de diagnosticos. No es usada por Quarto.
diagDir = fullfile(cfg_ipom.ipomDir, 'diagnostics');
if exist(diagDir, 'dir') ~= 7
    mkdir(diagDir);
end

outputCsv = fullfile(diagDir, 'fcast_model_cond_external_2026.csv');
outputPdf = fullfile(diagDir, 'Forecast_Condicionado_Externo_2026');

fprintf('\n============================================================\n');
fprintf('Forecast condicionado al bloque externo\n');
fprintf('Historia:             %s\n', historyFile);
fprintf('Condicion externo:    %s\n', conditioningFile);
fprintf('Rango condicionado:   %s a %s\n', local_dat2char(condRange(1)), local_dat2char(condRange(end)));
fprintf('Diagnosticos:         %s\n', diagDir);
fprintf('============================================================\n\n');


%% ============================================================
%% 1. Cargar modelo
%% ============================================================

oldDir = pwd;
cleanupObj = onCleanup(@() cd(oldDir));

% Algunas versiones del loader esperan estar cerca del .model.
cd(cfg_ipom.modelDir);
[m, p, mss] = readmodel_alternativo(false); %#ok<ASGLU>
cd(oldDir);


%% ============================================================
%% 2. Cargar historia y escenario de condicionamiento
%% ============================================================

d = dbload(historyFile);
d = local_fill_quarter_dummies(d, fcastrange);

d_ext = dbload(conditioningFile);
d_ext = local_add_derived_variables(d_ext);

hasBaseline = false;
h_base = struct();
if exist(baselineFile, 'file') == 2
    h_base = dbload(baselineFile);
    h_base = local_add_derived_variables(h_base);
    hasBaseline = true;
end

% Copiar deterministicas relevantes si existen en el archivo de condicion.
% No se exogenizan con shocks; solo se entregan al database para que no
% queden NaN hacia delante.
d = local_copy_if_available(d, d_ext, 'CPI_US_2020', fcastrange, false);
d = local_copy_if_available(d, d_ext, 'D4L_CPI_TAR', fcastrange, false);


%% ============================================================
%% 3. Imponer solo bloque externo y construir plan
%% ============================================================

externalCatalog = { ...
    'L_WTI',  'SHK_L_WTI';  ...
    'L_PCU',  'SHK_L_PCU';  ...
    'VIX',    'SHK_VIX';    ...
    'FFR',    'SHK_FFR';    ...
    'UST10',  'SHK_UST10';  ...
    'CRECSC', 'SHK_CRECSC'; ...
    'L_Z',    'SHK_L_Z'     ...
};

[d, planItems] = local_apply_external_conditioning(d, d_ext, externalCatalog, condRange);

simplan = plan(m, fcastrange);

fprintf('\n============================================================\n');
fprintf('Plan de simulacion: variables externas condicionadas\n');
fprintf('============================================================\n');

for i = 1:numel(planItems)
    v  = planItems(i).var;
    sh = planItems(i).shock;
    rr = planItems(i).dates;

    fprintf('Exogenize %-12s | Endogenize %-16s | %s a %s | n = %d\n', ...
        v, sh, local_dat2char(rr(1)), local_dat2char(rr(end)), numel(rr));

    simplan = exogenize(simplan, v, rr);
    simplan = endogenize(simplan, sh, rr);
end


%% ============================================================
%% 4. Simular forecast condicionado externo
%% ============================================================

fprintf('\nSimulando modelo con bloque externo condicionado y domesticas libres...\n');

s_cond = simulate(m, d, fcastrange, ...
    'plan',       simplan, ...
    'method',     'selective', ...
    'nonlinPer',  30, ...
    'anticipate', false);

d_cond = dbextend(d, s_cond);
d_cond = local_add_derived_variables(d_cond);

% Guardar resultado para inspeccion propia.
dbsave(d_cond, outputCsv);
fprintf('CSV guardado: %s\n', outputCsv);


%% ============================================================
%% 5. Reporte PDF interno
%% ============================================================

fprintf('Generando PDF de diagnostico...\n');

x = report.new(country);

sty = struct();
sty.line.linewidth        = 1.4;
sty.line.linestyle        = {'-';'--';':'};
sty.axes.box              = 'on';
sty.legend.location       = 'Best';
sty.axes.yticklabelformat = '%.1f';

%% Figura 1: domesticas libres
x.figure('Condicionado externo desde 2026 - Domesticas libres', ...
    'subplot', [3,2], ...
    'style', sty, ...
    'range', Plotrng, ...
    'dateformat', 'YYYY:P');

local_graph_compare(x, 'TPM, %', ...
    'TPM', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Output gap, %', ...
    'L_GDP_GAP', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Inflacion total, % YoY', ...
    'D4L_CPI', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Inflacion sin volatiles, % YoY', ...
    'D4L_CPIXFE', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Inflacion total, % QoQ anualizada', ...
    'DLA_CPI', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Inflacion sin volatiles, % QoQ anualizada', ...
    'DLA_CPIXFE', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

x.pagebreak();

%% Figura 2: actividad y politica
x.figure('Condicionado externo desde 2026 - Actividad y politica', ...
    'subplot', [3,2], ...
    'style', sty, ...
    'range', Plotrng, ...
    'dateformat', 'YYYY:P');

local_graph_compare(x, 'PIB real, log x100', ...
    'L_GDP', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'PIB potencial, log x100', ...
    'L_GDP_BAR', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Crecimiento PIB, % QoQ anualizado', ...
    'DLA_GDP', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Crecimiento PIB, % YoY', ...
    'D4L_GDP', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'TPM neutral, %', ...
    'TPMN1', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Tasa colocaciones, %', ...
    'T_COLOC', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

x.pagebreak();

%% Figura 3: bloque externo impuesto
x.figure('Condicionado externo desde 2026 - Bloque externo impuesto', ...
    'subplot', [3,2], ...
    'style', sty, ...
    'range', Plotrng, ...
    'dateformat', 'YYYY:P');

local_graph_compare(x, 'WTI nominal, USD/bbl', ...
    'L_WTI_NOM', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Cobre nominal, USD/lb', ...
    'L_PCU_NOM', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Crecimiento internacional, %', ...
    'CRECSC', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'VIX', ...
    'VIX', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'FFR, %', ...
    'FFR', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'UST10, %', ...
    'UST10', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

x.pagebreak();

%% Figura 4: precios relativos y brechas
x.figure('Condicionado externo desde 2026 - Precios relativos', ...
    'subplot', [2,2], ...
    'style', sty, ...
    'range', Plotrng, ...
    'dateformat', 'YYYY:P');

local_graph_compare(x, ['TCR indice - ' exchange], ...
    'L_Z_INDEX', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'WTI real, exp(L_WTI/100)', ...
    'L_WTI_REAL', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Cobre real, exp(L_PCU/100)', ...
    'L_PCU_REAL', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

local_graph_compare(x, 'Brecha headline-core, pp YoY', ...
    'D4L_CPI_GAP_XFE', d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng);

%% Publicar en carpeta diagnostics
oldDir2 = pwd;
cd(diagDir);
x.publish('Forecast_Condicionado_Externo_2026', 'display', false);
cd(oldDir2);

fprintf('PDF guardado: %s.pdf\n', outputPdf);
fprintf('\nDone: forecast condicionado al bloque externo.\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FUNCIONES LOCALES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [d, planItems] = local_apply_external_conditioning(d, d_ext, catalog, condRange)

    planItems = struct('var', {}, 'shock', {}, 'dates', {});

    fprintf('\n============================================================\n');
    fprintf('Aplicando condicionamiento externo\n');
    fprintf('============================================================\n');

    for i = 1:size(catalog,1)
        v  = catalog{i,1};
        sh = catalog{i,2};

        if ~isfield(d_ext, v)
            fprintf('[OMITIDO] %-12s no existe en archivo de condicionamiento.\n', v);
            continue
        end

        if ~(isfield(d, sh) || isfield(d_ext, sh))
            fprintf('[OMITIDO] %-12s existe, pero no encuentro shock %-16s.\n', v, sh);
            continue
        end

        try
            vals = d_ext.(v)(condRange);
        catch
            fprintf('[OMITIDO] %-12s no acepta el rango de condicionamiento.\n', v);
            continue
        end

        vals = reshape(vals, 1, []);
        valid = ~isnan(vals);

        if ~any(valid)
            fprintf('[OMITIDO] %-12s no tiene datos validos en el rango.\n', v);
            continue
        end

        rr = condRange(valid);
        d.(v)(rr) = d_ext.(v)(rr);

        planItems(end+1).var   = v; %#ok<AGROW>
        planItems(end).shock   = sh;
        planItems(end).dates   = rr;

        fprintf('[ACTIVO]  %-12s con %-16s | %s a %s | n = %d\n', ...
            v, sh, local_dat2char(rr(1)), local_dat2char(rr(end)), numel(rr));
    end
end


function db = local_copy_if_available(db, sourceDb, varName, rng, verbose)
    if nargin < 5
        verbose = true;
    end

    if ~isfield(sourceDb, varName)
        return
    end

    try
        vals = sourceDb.(varName)(rng);
    catch
        return
    end

    vals = reshape(vals, 1, []);
    valid = ~isnan(vals);

    if ~any(valid)
        return
    end

    rr = rng(valid);
    db.(varName)(rr) = sourceDb.(varName)(rr);

    if verbose
        fprintf('[COPY]    %-12s copiado desde condicionamiento | %s a %s\n', ...
            varName, local_dat2char(rr(1)), local_dat2char(rr(end)));
    end
end


function db = local_fill_quarter_dummies(db, rng)
    for q = 1:4
        varName = sprintf('Q%d', q);
        if isfield(db, varName)
            try
                db.(varName)(rng) = 0;
            catch
            end
        end
    end

    for t = reshape(rng, 1, [])
        q = local_quarter_from_date(t);
        varName = sprintf('Q%d', q);
        if isfield(db, varName)
            try
                db.(varName)(t) = 1;
            catch
            end
        end
    end
end


function q = local_quarter_from_date(d)
    s = local_dat2char(d);
    tok = regexp(s, 'Q([1-4])', 'tokens', 'once');
    if isempty(tok)
        tok = regexp(s, ':([1-4])', 'tokens', 'once');
    end
    if isempty(tok)
        error('No pude inferir trimestre desde fecha IRIS: %s', s);
    end
    q = str2double(tok{1});
end


function db = local_add_derived_variables(db)
    if isfield(db, 'L_PCU')
        db.L_PCU_REAL = exp(db.L_PCU/100);
    end

    if isfield(db, 'L_WTI')
        db.L_WTI_REAL = exp(db.L_WTI/100);
    end

    if isfield(db, 'CPI_US_2020')
        if isfield(db, 'L_PCU')
            db.L_PCU_NOM = exp(db.L_PCU/100) .* db.CPI_US_2020/100;
        end
        if isfield(db, 'L_WTI')
            db.L_WTI_NOM = exp(db.L_WTI/100) .* db.CPI_US_2020/100;
        end
    else
        if isfield(db, 'L_PCU')
            db.L_PCU_NOM = exp(db.L_PCU/100);
        end
        if isfield(db, 'L_WTI')
            db.L_WTI_NOM = exp(db.L_WTI/100);
        end
    end

    if isfield(db, 'L_Z')
        db.L_Z_INDEX = exp(db.L_Z/100);
    end

    if isfield(db, 'D4L_CPI') && isfield(db, 'D4L_CPIXFE')
        db.D4L_CPI_GAP_XFE = db.D4L_CPI - db.D4L_CPIXFE;
    end
end


function local_graph_compare(x, graphTitle, varName, d_cond, d_ext, hasBaseline, h_base, Histrng, CondRng)
    series = {};
    names  = {};

    if isfield(d_cond, varName)
        series{end+1} = d_cond.(varName); %#ok<AGROW>
        names{end+1}  = 'Modelo: externo impuesto'; %#ok<AGROW>
    end

    if isfield(d_ext, varName)
        series{end+1} = d_ext.(varName); %#ok<AGROW>
        names{end+1}  = 'Escenario completo'; %#ok<AGROW>
    end

    if hasBaseline && isfield(h_base, varName)
        series{end+1} = h_base.(varName); %#ok<AGROW>
        names{end+1}  = 'Baseline IPoM'; %#ok<AGROW>
    end

    if isempty(series)
        x.graph([graphTitle ' - missing'], 'legend', false);
        return
    end

    data = series{1};
    for k = 2:numel(series)
        data = [data, series{k}]; %#ok<AGROW>
    end

    x.graph(graphTitle, 'legend', true);
    x.series(names, data);
    x.highlight('', Histrng);
    x.highlight('', CondRng);
end


function s = local_dat2char(d)
    s = dat2str(d);
    if iscell(s)
        s = s{1};
    end
    if isstring(s)
        s = char(s);
    end
end
