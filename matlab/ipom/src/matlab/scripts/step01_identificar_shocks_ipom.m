%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% step01_identificar_shocks_ipom.m
%%
%% Objetivo:
%% Construir un baseline IPOM exacto mediante simulación condicional.
%%
%% El script:
%% 1. Carga el modelo.
%% 2. Carga historia observada.
%% 3. Carga paths IPOM si existe ipom_paths.csv.
%%    Si no existe, usa history.csv como fuente de pseudo-historia/IPOM.
%% 4. Exogeniza variables del IPOM.
%% 5. Endogeniza shocks correspondientes.
%% 6. Guarda fcast_ipom_exact.csv con variables y shocks identificados.
%%
%% Requiere:
%% - readmodel_alternativo.m
%% - minimep0.model
%% - history.csv
%% - opcional: ipom_paths.csv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all;
clearvars -except IPOM_RUN_REPORT;
clc;

%% ============================================================
%% 0. Configuración principal
%% ============================================================

% Horizonte observado real e IPOM
histStart  = qq(2000,1);
histEnd    = qq(2025,4);

startfcast = qq(2026,1);
endfcast   = qq(2027,4);

% Extensión necesaria por términos forward-looking de regla y Phillips
bufferPeriods = 8;
fcastrange    = startfcast:(endfcast + bufferPeriods);
ipomRange     = startfcast:endfcast;
fullRange     = histStart:(endfcast + bufferPeriods);

% Flags
matchHeadlineExactly = true;   % Si true, intenta hacer calzar inflación total exacta.
% Rutas robustas del proyecto
if exist('config_ipom', 'file') == 2
    cfg_ipom = config_ipom();
    historyFile   = cfg_ipom.historyFile;
    ipomPathsFile = cfg_ipom.ipomPathsFile;
    outBaseline   = cfg_ipom.baselineFile;
    outShocks     = cfg_ipom.baselineShocksFile;
    baselineReportName = fullfile(cfg_ipom.reportDir, 'Baseline_IPOM_Identificado');
else
    historyFile   = 'history.csv';
    ipomPathsFile = 'ipom_paths.csv';
    outBaseline   = 'fcast_ipom_exact.csv';
    outShocks     = 'fcast_ipom_with_shocks.csv';
    baselineReportName = 'Baseline_IPOM_Identificado';
end

useIpomPathsFile     = exist(ipomPathsFile,'file') == 2;

% Archivos de salida definidos por config_ipom.m

fprintf('\n============================================================\n');
fprintf('Identificando shocks del baseline IPOM\n');
fprintf('Rango IPOM: %s a %s\n', local_dat2char(startfcast), local_dat2char(endfcast));
fprintf('============================================================\n\n');


%% ============================================================
%% 1. Cargar modelo
%% ============================================================

[m,p,mss] = readmodel_alternativo(false);


%% ============================================================
%% 2. Cargar bases
%% ============================================================

if exist(historyFile, 'file') ~= 2
    error('No existe history.csv en: %s. Corre step00_build_history_from_data.m o revisa data/processed.', historyFile);
end

hist_db = dbload(historyFile);

if useIpomPathsFile
    fprintf('Usando ipom_paths.csv como fuente de trayectorias IPOM: %s\n', ipomPathsFile);
    ipom_db = dbload(ipomPathsFile);
else
    fprintf('ADVERTENCIA: No se encontró ipom_paths.csv en data/processed.\n');
    fprintf('Se usará history.csv también como fuente de trayectorias IPOM.\n');
    ipom_db = hist_db;
end

% Base de trabajo
d = hist_db;


%% ============================================================
%% 3. Copiar trayectorias IPOM a base de trabajo
%% ============================================================

vars_copy = { ...
    'L_GDP','L_GDP_BAR','L_GDP_GAP','DLA_GDP','D4L_GDP','DLA_GDP_BAR', ...
    'L_CPI','L_CPIXFE','DLA_CPI','D4L_CPI','DLA_CPIXFE','D4L_CPIXFE','DLA_CPIRES', ...
    'TPM','TPMN1','T_COLOC', ...
    'L_Z','L_Z_GAP', ...
    'CRECSC','FFR','UST10','VIX', ...
    'L_PCU','L_WTI','L_Food', ...
    'CPI_US_2020', ...
    'Q1','Q2','Q3','Q4' ...
};

for i = 1:numel(vars_copy)
    v = vars_copy{i};

    if isfield(ipom_db, v)
        try
            x = ipom_db.(v)(ipomRange);
            ix = ~isnan(x);

            if any(ix)
                d.(v)(ipomRange(ix)) = x(ix);
                fprintf('Copiado IPOM: %s\n', v);
            end
        catch
            fprintf('No se pudo copiar %s desde ipom_db.\n', v);
        end
    end
end


%% ============================================================
%% 4. Construir DLA_CPIRES si no viene en la base
%% ============================================================

hasDlaCpires = local_has_data(d, 'DLA_CPIRES', ipomRange);

if ~hasDlaCpires
    if local_has_data(d, 'DLA_CPI', ipomRange) && local_has_data(d, 'DLA_CPIXFE', ipomRange)
        fprintf('\nDLA_CPIRES no existe o está vacío en IPOM.\n');
        fprintf('Se construye como DLA_CPI - DLA_CPIXFE.\n');

        d.DLA_CPIRES(ipomRange) = d.DLA_CPI(ipomRange) - d.DLA_CPIXFE(ipomRange);
    else
        fprintf('\nADVERTENCIA: No se puede construir DLA_CPIRES.\n');
        fprintf('Faltan DLA_CPI o DLA_CPIXFE.\n');
    end
end


%% ============================================================
%% 5. Definir variables a imponer y shocks que absorben diferencias
%% ============================================================

exogVars   = {};
endogShocks = {};

%% 5.1 Bloque externo
externalVars = { ...
    'L_WTI', ...
    'L_PCU', ...
    'FFR', ...
    'UST10', ...
    'VIX', ...
    'CRECSC', ...
    'L_Z', ...
    'L_Food' ...
};

externalShocks = { ...
    'SHK_L_WTI', ...
    'SHK_L_PCU', ...
    'SHK_FFR', ...
    'SHK_UST10', ...
    'SHK_VIX', ...
    'SHK_CRECSC', ...
    'SHK_L_Z', ...
    'SHK_L_Food' ...
};

[varsTmp, shocksTmp] = local_pick_pairs_with_data(d, externalVars, externalShocks, ipomRange);
exogVars    = [exogVars, varsTmp];
endogShocks = [endogShocks, shocksTmp];


%% 5.2 Actividad, TPM y otros domésticos
domesticVars = { ...
    'L_GDP_GAP', ...
    'TPM', ...
    'TPMN1', ...
    'T_COLOC', ...
    'DLA_GDP_BAR' ...
};

domesticShocks = { ...
    'SHK_L_GDP_GAP', ...
    'SHK_TPM', ...
    'SHK_TPMN1', ...
    'SHK_T_COLOC', ...
    'SHK_DLA_GDP_BAR' ...
};

[varsTmp, shocksTmp] = local_pick_pairs_with_data(d, domesticVars, domesticShocks, ipomRange);
exogVars    = [exogVars, varsTmp];
endogShocks = [endogShocks, shocksTmp];


%% 5.3 Inflación subyacente
% Preferencia:
% 1. DLA_CPIXFE, porque es la variable de la Phillips.
% 2. D4L_CPIXFE, si solo tienes YoY.
% 3. L_CPIXFE, si tienes nivel 100*log.

coreTarget = local_choose_first_available(d, ...
    {'DLA_CPIXFE','D4L_CPIXFE','L_CPIXFE'}, ...
    ipomRange);

if ~isempty(coreTarget)
    exogVars{end+1}     = coreTarget;
    endogShocks{end+1}  = 'SHK_DLA_CPIXFE';
    fprintf('Target core inflation: %s -> SHK_DLA_CPIXFE\n', coreTarget);
else
    fprintf('ADVERTENCIA: No se encontró target para inflación subyacente.\n');
end


%% 5.4 Inflación residual / volátil
residualTarget = local_choose_first_available(d, ...
    {'DLA_CPIRES'}, ...
    ipomRange);

if ~isempty(residualTarget)
    exogVars{end+1}     = residualTarget;
    endogShocks{end+1}  = 'SHK_DLA_CPIRES';
    fprintf('Target residual inflation: %s -> SHK_DLA_CPIRES\n', residualTarget);
else
    fprintf('ADVERTENCIA: No se encontró target para inflación residual.\n');
end


%% 5.5 Inflación headline total
% Este bloque permite cerrar exactamente el IPC total.
% Si prefieres no usar SHK_DLA_CPI como ajuste técnico, cambia
% matchHeadlineExactly = false.

if matchHeadlineExactly
    headlineTarget = local_choose_first_available(d, ...
        {'DLA_CPI','D4L_CPI','L_CPI'}, ...
        ipomRange);

    if ~isempty(headlineTarget)
        exogVars{end+1}     = headlineTarget;
        endogShocks{end+1}  = 'SHK_DLA_CPI';
        fprintf('Target headline inflation: %s -> SHK_DLA_CPI\n', headlineTarget);
    else
        fprintf('ADVERTENCIA: No se encontró target para inflación headline.\n');
    end
end


%% ============================================================
%% 6. Limpiar duplicados
%% ============================================================

[exogVars, endogShocks] = local_remove_duplicate_pairs(exogVars, endogShocks);

fprintf('\nVariables exogenizadas:\n');
disp(exogVars');

fprintf('Shocks endogenizados:\n');
disp(endogShocks');

if numel(exogVars) ~= numel(endogShocks)
    error('Número de variables exogenizadas distinto al número de shocks endogenizados.');
end


%% ============================================================
%% 7. Crear plan IPOM
%% ============================================================

plan_ipom = plan(m, fcastrange);

if ~isempty(exogVars)
    plan_ipom = exogenize(plan_ipom, exogVars, ipomRange);
    plan_ipom = endogenize(plan_ipom, endogShocks, ipomRange);
else
    error('No hay variables con datos IPOM para exogenizar.');
end


%% ============================================================
%% 8. Simular baseline condicionado IPOM
%% ============================================================

fprintf('\nSimulando baseline IPOM condicionado...\n');

s_ipom = simulate(m, d, fcastrange, ...
    'plan',       plan_ipom, ...
    'method',     'selective', ...
    'nonlinPer',  30, ...
    'anticipate', false);

d_ipom = dbextend(d, s_ipom);


%% ============================================================
%% 9. Variables derivadas útiles
%% ============================================================

d_ipom = local_add_derived_variables(d_ipom);


%% ============================================================
%% 10. Guardar baseline exacto
%% ============================================================

dbsave(d_ipom, outBaseline);
dbsave(d_ipom, outShocks);

fprintf('\nBaseline IPOM exacto guardado en:\n');
fprintf(' - %s\n', outBaseline);
fprintf(' - %s\n', outShocks);


%% ============================================================
%% 11. Diagnóstico rápido de shocks
%% ============================================================

shockDiagVars = { ...
    'SHK_L_GDP_GAP', ...
    'SHK_DLA_CPIXFE', ...
    'SHK_DLA_CPIRES', ...
    'SHK_DLA_CPI', ...
    'SHK_TPM', ...
    'SHK_L_WTI', ...
    'SHK_L_Z', ...
    'SHK_CRECSC', ...
    'SHK_FFR', ...
    'SHK_VIX', ...
    'SHK_UST10' ...
};

fprintf('\nDiagnóstico simple de shocks en IPOM range:\n');

for i = 1:numel(shockDiagVars)
    v = shockDiagVars{i};

    if isfield(d_ipom, v)
        try
            x = d_ipom.(v)(ipomRange);
            if any(~isnan(x))
                fprintf('%-18s | mean = %+8.4f | max abs = %+8.4f\n', ...
                    v, mean(x(~isnan(x))), max(abs(x(~isnan(x)))));
            end
        catch
        end
    end
end


%% ============================================================
%% 12. Reporte simple del baseline
%% ============================================================

try
    Plotrng = qq(2025,1):endfcast;
    ObsRng  = qq(2025,1):qq(2025,4);
    IpomRng = ipomRange;

    country = 'Chile - Baseline IPOM Identificado';
    x = report.new(country);

    sty = struct();
    sty.line.linewidth         = 1.5;
    sty.axes.box               = 'on';
    sty.legend.location        = 'Best';
    sty.axes.yticklabelformat  = '%.1f';

    x.figure('Baseline IPOM identificado - principales variables', ...
        'subplot', [3,2], ...
        'style', sty, ...
        'range', Plotrng, ...
        'dateformat', 'YYYY:P');

    if isfield(d_ipom,'TPM')
        x.graph('TPM, %', 'legend', true);
        x.series({'Baseline IPOM exacto'}, d_ipom.TPM);
        x.highlight('', ObsRng);
        x.highlight('', IpomRng);
    end

    if isfield(d_ipom,'L_GDP_GAP')
        x.graph('Brecha del producto, %', 'legend', true);
        x.series({'Baseline IPOM exacto'}, d_ipom.L_GDP_GAP);
        x.highlight('', ObsRng);
        x.highlight('', IpomRng);
    end

    if isfield(d_ipom,'D4L_CPI')
        x.graph('Inflación total, % a/a', 'legend', true);
        x.series({'Baseline IPOM exacto'}, d_ipom.D4L_CPI);
        x.highlight('', ObsRng);
        x.highlight('', IpomRng);
    end

    if isfield(d_ipom,'D4L_CPIXFE')
        x.graph('Inflación subyacente, % a/a', 'legend', true);
        x.series({'Baseline IPOM exacto'}, d_ipom.D4L_CPIXFE);
        x.highlight('', ObsRng);
        x.highlight('', IpomRng);
    end

    if isfield(d_ipom,'L_WTI_NOM')
        x.graph('WTI nominal', 'legend', true);
        x.series({'Baseline IPOM exacto'}, d_ipom.L_WTI_NOM);
        x.highlight('', ObsRng);
        x.highlight('', IpomRng);
    end

    if isfield(d_ipom,'L_Z_INDEX')
        x.graph('TCR índice', 'legend', true);
        x.series({'Baseline IPOM exacto'}, d_ipom.L_Z_INDEX);
        x.highlight('', ObsRng);
        x.highlight('', IpomRng);
    end

    x.pagebreak();

    x.figure('Shocks identificados del baseline IPOM', ...
        'subplot', [3,2], ...
        'style', sty, ...
        'range', ipomRange, ...
        'dateformat', 'YYYY:P');

    if isfield(d_ipom,'SHK_L_GDP_GAP')
        x.graph('SHK\_L\_GDP\_GAP', 'legend', true);
        x.series({'Shock'}, d_ipom.SHK_L_GDP_GAP);
    end

    if isfield(d_ipom,'SHK_DLA_CPIXFE')
        x.graph('SHK\_DLA\_CPIXFE', 'legend', true);
        x.series({'Shock'}, d_ipom.SHK_DLA_CPIXFE);
    end

    if isfield(d_ipom,'SHK_DLA_CPIRES')
        x.graph('SHK\_DLA\_CPIRES', 'legend', true);
        x.series({'Shock'}, d_ipom.SHK_DLA_CPIRES);
    end

    if isfield(d_ipom,'SHK_TPM')
        x.graph('SHK\_TPM', 'legend', true);
        x.series({'Shock'}, d_ipom.SHK_TPM);
    end

    if isfield(d_ipom,'SHK_L_WTI')
        x.graph('SHK\_L\_WTI', 'legend', true);
        x.series({'Shock'}, d_ipom.SHK_L_WTI);
    end

    if isfield(d_ipom,'SHK_L_Z')
        x.graph('SHK\_L\_Z', 'legend', true);
        x.series({'Shock'}, d_ipom.SHK_L_Z);
    end

    x.publish(baselineReportName, 'display', false);

    fprintf('\nReporte generado: %s.pdf\n', baselineReportName);

catch ME
    fprintf('\nNo se pudo generar el reporte automático.\n');
    fprintf('Mensaje: %s\n', ME.message);
end

fprintf('\nDone: baseline IPOM identificado.\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FUNCIONES LOCALES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tf = local_has_data(db, varname, rng)
    tf = false;

    if ~isfield(db, varname)
        return;
    end

    try
        x = db.(varname)(rng);
        tf = any(~isnan(x));
    catch
        tf = false;
    end
end


function [varsOut, shocksOut] = local_pick_pairs_with_data(db, varsIn, shocksIn, rng)
    varsOut   = {};
    shocksOut = {};

    for j = 1:numel(varsIn)
        v = varsIn{j};

        if local_has_data(db, v, rng)
            varsOut{end+1}   = varsIn{j};
            shocksOut{end+1} = shocksIn{j};
            fprintf('Target activo: %s -> %s\n', varsIn{j}, shocksIn{j});
        else
            fprintf('Sin datos IPOM suficientes: %s\n', varsIn{j});
        end
    end
end


function chosen = local_choose_first_available(db, candidates, rng)
    chosen = '';

    for j = 1:numel(candidates)
        v = candidates{j};

        if local_has_data(db, v, rng)
            chosen = v;
            return;
        end
    end
end


function [varsOut, shocksOut] = local_remove_duplicate_pairs(varsIn, shocksIn)
    varsOut   = {};
    shocksOut = {};

    for j = 1:numel(varsIn)
        v = varsIn{j};
        s = shocksIn{j};

        already = false;

        for k = 1:numel(varsOut)
            if strcmp(varsOut{k}, v)
                already = true;
                break;
            end
        end

        if ~already
            varsOut{end+1}   = v;
            shocksOut{end+1} = s;
        end
    end
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

function db = local_add_derived_variables(db)

    if isfield(db,'CPI_US_2020')
        if isfield(db,'L_PCU')
            db.L_PCU_NOM = exp(db.L_PCU/100) .* db.CPI_US_2020/100;
        end

        if isfield(db,'L_WTI')
            db.L_WTI_NOM = exp(db.L_WTI/100) .* db.CPI_US_2020/100;
        end
    else
        if isfield(db,'L_PCU')
            db.L_PCU_NOM = exp(db.L_PCU/100);
        end

        if isfield(db,'L_WTI')
            db.L_WTI_NOM = exp(db.L_WTI/100);
        end
    end

    if isfield(db,'L_Z')
        db.L_Z_INDEX = exp(db.L_Z/100);
    end

    if isfield(db,'D4L_CPI') && isfield(db,'D4L_CPIXFE')
        db.D4L_CPI_GAP_XFE = db.D4L_CPI - db.D4L_CPIXFE;
    end
end