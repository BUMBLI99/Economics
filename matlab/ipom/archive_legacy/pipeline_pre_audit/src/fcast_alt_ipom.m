%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 02_alternativa_escenario_simple.m
%
%% Regla operativa:
%% - Variables en 100*log(nivel): usar multiplicadores.
%   Ejemplo:
%      L_WTI_alt = L_WTI_base + 100*log(wti_mult)
%
%% - Variables en nivel, tasas, brechas o inflación: usar aditivos.
%   Ejemplo:
%      VIX_alt = VIX_base + vix_add
%
%% Punto clave:
%% - Multiplicador = 1  => no se impone la variable en ese período.
% - Aditivo = 0        => no se impone la variable en ese período.
%% - Si pones un shock solo en 2026Q3, solo se exogeniza 2026Q3.
% - Los períodos siguientes quedan endógenos y los resuelve el modelo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all;
clearvars -except IPOM_RUN_REPORT;
clc;

%% ============================================================
%% 0. Configuración principal
%% ============================================================

% Rutas robustas del proyecto
if exist('config_ipom', 'file') == 2
    cfg_ipom = config_ipom();
    if exist(cfg_ipom.rawOutputDir, 'dir') ~= 7
        mkdir(cfg_ipom.rawOutputDir);
    end
    baselineFile = fullfile(cfg_ipom.rawOutputDir, 'fcast_ipom_exact.csv');
    outputFile   = fullfile(cfg_ipom.rawOutputDir, 'fcast_alt_petroleo_gap.csv');
    outputFileGeneric = fullfile(cfg_ipom.rawOutputDir, 'fcast_alt_escenario.csv');
else
    baselineFile = 'fcast_ipom_exact.csv';
    outputFile   = 'fcast_alt_petroleo_gap.csv';
    outputFileGeneric = 'fcast_alt_escenario.csv';
end

startfcast_alt = qq(2026,1);
endfcast       = qq(2027,4);

bufferPeriods  = 8;
fcastrange     = startfcast_alt:(endfcast + bufferPeriods);

altRange       = startfcast_alt:endfcast;
nAlt           = length(altRange);

Plotrng        = qq(2025,1):endfcast;
Tablerng       = qq(2025,1):endfcast;
ObsRng         = qq(2025,1):qq(2025,4);
AltRng         = altRange;

altname        = 'Escenario petroleo alto y gap mas negativo';
country        = 'Chile';
exchange       = 'CHL/USA';

reportName     = 'Escenario_Petroleo_Gap';

% Por defecto el pipeline ordenado no genera PDF, porque Quarto usa CSV.
% Para forzar reportes IRIS, define IPOM_RUN_REPORT = true antes de ejecutar.
if exist('IPOM_RUN_REPORT','var')
    runReport = IPOM_RUN_REPORT;
else
    runReport = false;
end

fprintf('\n============================================================\n');
fprintf('Escenario alternativo\n');
fprintf('Rango alternativo: %s a %s\n', ...
    local_dat2char(startfcast_alt), local_dat2char(endfcast));
fprintf('============================================================\n\n');


%% ============================================================
%% 1. Cargar modelo y baseline IPOM exacto
% ============================================================

[m,p,mss] = readmodel_alternativo(false);

if exist(baselineFile,'file') ~= 2
    error('No existe %s. Primero corre 01_identificar_shocks_ipom.m', baselineFile);
end

h = dbload(baselineFile);

% Copia de trabajo. Mantiene todos los shocks y juicios del baseline.
d = h;


%% ============================================================
%% 2. BLOQUE DE MANIPULACIÓN DEL ESCENARIO
% ============================================================
%   one_path  para multiplicadores neutros.
%   zero_path para aditivos neutros.
% Para shock puntual:
%   pcu_mult_path = local_set_path(pcu_mult_path, altRange, qq(2026,3), 1.10);
% Para shock de varios trimestres:
%   vix_add_path = local_set_path(vix_add_path, altRange, qq(2026,2):qq(2026,4), [5 3 1]);
% Si una variable queda en 1 o 0 en todos los períodos, NO se exogeniza.

one_path  = ones(1, nAlt);
zero_path = zeros(1, nAlt);

% ------------------------------------------------------------
%% 2.1 Multiplicadores: variables en 100*log(nivel)
% ------------------------------------------------------------

wti_mult_path      = one_path;   % L_WTI
pcu_mult_path      = one_path;   % L_PCU
lz_mult_path       = one_path;   % L_Z

lcpi_mult_path     = one_path;   % L_CPI
lcpixfe_mult_path  = one_path;   % L_CPIXFE
lcpif_mult_path    = one_path;   % L_CPIF, si existe
lcpie_mult_path    = one_path;   % L_CPIE, si existe

lgdp_mult_path     = one_path;   % L_GDP, si existe
lgdp_bar_mult_path = one_path;   % L_GDP_BAR, si existe


%% ------------------------------------------------------------
%% 2.2 Aditivos: niveles, tasas, brechas e inflación
%% ------------------------------------------------------------

vix_add_path       = zero_path;  % VIX
ffr_add_path       = zero_path;  % FFR
ust10_add_path     = zero_path;  % UST10
crec_add_path      = zero_path;  % CRECSC

gap_add_path       = zero_path;  % L_GDP_GAP
tpm_add_path       = zero_path;  % TPM
rs_unc_add_path    = zero_path;  % RS_UNC

dla_cpi_add_path    = zero_path; % DLA_CPI
dla_cpixfe_add_path = zero_path; % DLA_CPIXFE
dla_cpires_add_path = zero_path; % DLA_CPIRES

d4lcpi_add_path     = zero_path; % D4L_CPI, si existe shock
d4lcpixfe_add_path  = zero_path; % D4L_CPIXFE, si existe shock
d4lcpi_tar_add_path = zero_path; % D4L_CPI_TAR


% ------------------------------------------------------------
%% 2.3 Escenario activo: petroleo alto + gap mas negativo
% ------------------------------------------------------------
% Esta es la unica parte que normalmente deberias tocar.
%
% Escenario segun minuta:
% - Petroleo nominal WTI: 100 en 2026Q2 y 2026Q3;
%   90 en 2026Q4; 85 desde 2027Q1 hasta 2027Q4.
% - Cobre: igual al baseline.
% - Tipo de cambio real: igual al baseline.
% - Output gap: -0.5 en 2026Q1 y 2026Q2; luego libre.
% - TPM: libre, no se impone.
% - Inflacion efectiva 2026Q1: opcional; idealmente debe entrar
%   por history.csv/ipom_paths.csv antes de identificar shocks.
%
% Nota tecnica:
% - L_WTI esta en 100*log(.), pero el escenario viene en nivel nominal.
%   Por eso se convierte el objetivo nominal a multiplicador relativo al
%   baseline usando local_nominal_level_to_multiplier().
% - L_GDP_GAP esta en nivel, por lo que imponer -0.5 se traduce a un
%   aditivo target - baseline usando local_level_to_additive().

% Reset explicito para no arrastrar ningun shock de ejemplos anteriores
wti_mult_path      = one_path;
pcu_mult_path      = one_path;
lz_mult_path       = one_path;

lcpi_mult_path     = one_path;
lcpixfe_mult_path  = one_path;
lcpif_mult_path    = one_path;
lcpie_mult_path    = one_path;

lgdp_mult_path     = one_path;
lgdp_bar_mult_path = one_path;

vix_add_path       = zero_path;
ffr_add_path       = zero_path;
ust10_add_path     = zero_path;
crec_add_path      = zero_path;

gap_add_path       = zero_path;
tpm_add_path       = zero_path;
rs_unc_add_path    = zero_path;

dla_cpi_add_path    = zero_path;
dla_cpixfe_add_path = zero_path;
dla_cpires_add_path = zero_path;

d4lcpi_add_path     = zero_path;
d4lcpixfe_add_path  = zero_path;
d4lcpi_tar_add_path = zero_path;


%% ------------------------------------------------------------
%% A. Petroleo nominal impuesto
%% ------------------------------------------------------------
% El objetivo esta expresado en dolares nominales por barril.
% El helper convierte ese objetivo a multiplicadores sobre L_WTI.

wti_dates = qq(2026,2):qq(2027,4);

wti_nominal_target = [ ...
    100, ... % 2026Q2
    100, ... % 2026Q3
     90, ... % 2026Q4
     85, ... % 2027Q1
     85, ... % 2027Q2
     85, ... % 2027Q3
     85  ... % 2027Q4
];

wti_mult_values = local_nominal_level_to_multiplier( ...
    h, 'L_WTI', wti_dates, wti_nominal_target ...
);

wti_mult_path = local_set_path( ...
    wti_mult_path, altRange, wti_dates, wti_mult_values ...
);


%% ------------------------------------------------------------
%% B. Cobre igual al baseline
%% ------------------------------------------------------------
% No se toca L_PCU: pcu_mult_path queda en one_path.


%% ------------------------------------------------------------
%% C. Tipo de cambio real igual al baseline
%% ------------------------------------------------------------
% No se toca L_Z: lz_mult_path queda en one_path.


%% ------------------------------------------------------------
%% D. Output gap: -0.5 en 2026Q1 y 2026Q2
%% ------------------------------------------------------------
% Como L_GDP_GAP es una brecha en nivel, se impone como diferencia
% respecto del baseline:
%   gap_add = target - baseline

gap_dates  = qq(2026,1):qq(2026,2);
gap_target = [-0.5, -0.5];

gap_add_values = local_level_to_additive( ...
    h, 'L_GDP_GAP', gap_dates, gap_target ...
);

gap_add_path = local_set_path( ...
    gap_add_path, altRange, gap_dates, gap_add_values ...
);


%% ------------------------------------------------------------
%% E. Inflacion efectiva 2026Q1, opcional
%% ------------------------------------------------------------
% Recomendacion: no usar esta seccion salvo para prueba rapida.
% Lo mas limpio es actualizar history.csv/ipom_paths.csv y volver a correr
% identificar_shocks_ipom.m para que el baseline ya incorpore el dato.
%
% Si de todas formas quieres imponer el dato observado dentro del escenario,
% reemplaza NaN por el dato trimestral anualizado efectivo.
%
% Ejemplo:
d4lcpi_2026q1_actual    = 2.6611;
d4lcpixfe_2026q1_actual = 3.3998;

d4lcpi_add_values = local_level_to_additive( ...
    h, 'D4L_CPI', qq(2026,1), d4lcpi_2026q1_actual ...
);

d4lcpi_add_path = local_set_path( ...
    d4lcpi_add_path, altRange, qq(2026,1), d4lcpi_add_values ...
);

d4lcpixfe_add_values = local_level_to_additive( ...
    h, 'D4L_CPIXFE', qq(2026,1), d4lcpixfe_2026q1_actual ...
);

d4lcpixfe_add_path = local_set_path( ...
    d4lcpixfe_add_path, altRange, qq(2026,1), d4lcpixfe_add_values ...
);

%% ------------------------------------------------------------
%% F. TPM libre
%% ------------------------------------------------------------
% No imponer TPM ni RS_UNC.
% La pregunta de interes es si la regla del modelo sube la TPM en 2026Q3.


%% ============================================================
%% 3. Catálogo de variables del escenario
%% ============================================================
%
% Formato:
%   variable, shock, tipo, path
%
% tipo = 'mult' para variables en 100*log(.)
% tipo = 'add'  para variables en niveles/tasas/brechas/inflación

catalog = cell(0,4);

% Multiplicadores
catalog = local_add_to_catalog(catalog, 'L_WTI',     'SHK_L_WTI',     'mult', wti_mult_path);
catalog = local_add_to_catalog(catalog, 'L_PCU',     'SHK_L_PCU',     'mult', pcu_mult_path);
catalog = local_add_to_catalog(catalog, 'L_Z',       'SHK_L_Z',       'mult', lz_mult_path);

catalog = local_add_to_catalog(catalog, 'L_CPI',     'SHK_L_CPI',     'mult', lcpi_mult_path);
catalog = local_add_to_catalog(catalog, 'L_CPIXFE',  'SHK_L_CPIXFE',  'mult', lcpixfe_mult_path);
catalog = local_add_to_catalog(catalog, 'L_CPIF',    'SHK_L_CPIF',    'mult', lcpif_mult_path);
catalog = local_add_to_catalog(catalog, 'L_CPIE',    'SHK_L_CPIE',    'mult', lcpie_mult_path);

catalog = local_add_to_catalog(catalog, 'L_GDP',     'SHK_L_GDP',     'mult', lgdp_mult_path);
catalog = local_add_to_catalog(catalog, 'L_GDP_BAR', 'SHK_L_GDP_BAR', 'mult', lgdp_bar_mult_path);

% Aditivos externos/financieros
catalog = local_add_to_catalog(catalog, 'VIX',       'SHK_VIX',       'add', vix_add_path);
catalog = local_add_to_catalog(catalog, 'FFR',       'SHK_FFR',       'add', ffr_add_path);
catalog = local_add_to_catalog(catalog, 'UST10',     'SHK_UST10',     'add', ust10_add_path);
catalog = local_add_to_catalog(catalog, 'CRECSC',    'SHK_CRECSC',    'add', crec_add_path);

% Aditivos domésticos
catalog = local_add_to_catalog(catalog, 'L_GDP_GAP', 'SHK_L_GDP_GAP', 'add', gap_add_path);
catalog = local_add_to_catalog(catalog, 'TPM',       'SHK_TPM',       'add', tpm_add_path);
catalog = local_add_to_catalog(catalog, 'RS_UNC',    'SHK_RS_UNC',    'add', rs_unc_add_path);

catalog = local_add_to_catalog(catalog, 'DLA_CPI',     'SHK_DLA_CPI',     'add', dla_cpi_add_path);
catalog = local_add_to_catalog(catalog, 'DLA_CPIXFE',  'SHK_DLA_CPIXFE',  'add', dla_cpixfe_add_path);
catalog = local_add_to_catalog(catalog, 'DLA_CPIRES',  'SHK_DLA_CPIRES',  'add', dla_cpires_add_path);

catalog = local_add_to_catalog(catalog, 'D4L_CPI',     'SHK_D4L_CPI',     'add', d4lcpi_add_path);
catalog = local_add_to_catalog(catalog, 'D4L_CPIXFE',  'SHK_D4L_CPIXFE',  'add', d4lcpixfe_add_path);
catalog = local_add_to_catalog(catalog, 'D4L_CPI_TAR', 'SHK_D4L_CPI_TAR', 'add', d4lcpi_tar_add_path);


%% ============================================================
%% 4. Aplicar escenario y construir plan
%% ============================================================

[d, planItems] = local_apply_scenario(h, d, catalog, altRange);

% Mantener CPI_US_2020 del baseline si existe
if isfield(h,'CPI_US_2020')
    d.CPI_US_2020(altRange) = h.CPI_US_2020(altRange);
end

simplan = local_build_plan(m, fcastrange, planItems);


%% ============================================================
%% 5. Simular escenario alternativo
%% ============================================================

fprintf('\nSimulando escenario alternativo...\n');

s_alt = simulate(m, d, fcastrange, ...
    'plan',       simplan, ...
    'method',     'selective', ...
    'nonlinPer',  30, ...
    'anticipate', false);

d_alt = dbextend(d, s_alt);


%% ============================================================
%% 6. Variables derivadas
%% ============================================================

h     = local_add_derived_variables(h);
d_alt = local_add_derived_variables(d_alt);


%% ============================================================
%% 7. Guardar resultado
%% ============================================================

dbsave(d_alt, outputFile);

% Copia de compatibilidad: mantiene el nombre generico que ya lee el
% pipeline R/Quarto si todavia no has agregado este escenario al catalogo.
if exist('outputFileGeneric','var') && ~strcmp(outputFileGeneric, outputFile)
    dbsave(d_alt, outputFileGeneric);
end

fprintf('\nEscenario alternativo guardado en:\n');
fprintf(' - %s\n', outputFile);
if exist('outputFileGeneric','var') && ~strcmp(outputFileGeneric, outputFile)
    fprintf(' - %s  [copia compatible para Quarto]\n', outputFileGeneric);
end


%% ============================================================
%% 8. Diagnóstico
%% ============================================================

diagVars = { ...
    'D4L_CPI', ...
    'D4L_CPIXFE', ...
    'DLA_CPI', ...
    'DLA_CPIXFE', ...
    'DLA_CPIRES', ...
    'L_CPI', ...
    'L_CPIXFE', ...
    'L_GDP_GAP', ...
    'L_GDP', ...
    'L_GDP_BAR', ...
    'TPM', ...
    'RS_UNC', ...
    'L_WTI', ...
    'L_PCU', ...
    'L_Z', ...
    'VIX', ...
    'FFR', ...
    'UST10', ...
    'CRECSC' ...
};

local_print_diagnostics(h, d_alt, altRange, diagVars);


%% ============================================================
%% 9. Reporte
%% ============================================================

if runReport
    local_make_report( ...
        h, d_alt, planItems, ...
        country, altname, exchange, reportName, ...
        Plotrng, Tablerng, ObsRng, AltRng ...
    );
end

fprintf('\nDone: escenario alternativo.\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FUNCIONES LOCALES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function catalog = local_add_to_catalog(catalog, varName, shockName, typeName, path)
    catalog(end+1,:) = {varName, shockName, typeName, reshape(path, [], 1)};
end


function path = local_set_path(path, fullRange, dates, values)

    path  = reshape(path, 1, []);
    dates = reshape(dates, 1, []);

    if isscalar(values)
        values = repmat(values, 1, numel(dates));
    else
        values = reshape(values, 1, []);
    end

    if numel(values) ~= numel(dates)
        error('local_set_path: largo de values debe coincidir con largo de dates.');
    end

    for k = 1:numel(dates)
        idx = find(fullRange == dates(k), 1);

        if isempty(idx)
            error('local_set_path: la fecha %s no está dentro de altRange.', local_dat2char(dates(k)));
        end

        path(idx) = values(k);
    end
end



function multValues = local_nominal_level_to_multiplier(h, varName, dates, targetNominal)
% Convierte un nivel nominal objetivo a multiplicador relativo al baseline.
%
% Caso tipico:
%   L_WTI esta en 100*log(.).
%   El escenario dice "WTI nominal = 100".
%
% Si existe CPI_US_2020, se usa la misma convencion que en
% local_add_derived_variables():
%   nominal = exp(L_WTI/100) * CPI_US_2020/100
%
% Entonces:
%   multiplicador = targetNominal / baselineNominal

    if ~isfield(h, varName)
        error('No existe %s en el baseline.', varName);
    end

    targetNominal = reshape(targetNominal, 1, []);
    dates         = reshape(dates, 1, []);

    baseLevel   = h.(varName)(dates);
    baseNominal = exp(baseLevel/100);

    if isfield(h, 'CPI_US_2020')
        baseNominal = baseNominal .* h.CPI_US_2020(dates)/100;
    end

    baseNominal = reshape(baseNominal, 1, []);

    if numel(baseNominal) ~= numel(targetNominal)
        error('local_nominal_level_to_multiplier: targetNominal no coincide con dates.');
    end

    if any(baseNominal == 0 | isnan(baseNominal))
        error('local_nominal_level_to_multiplier: baseline nominal invalido para %s.', varName);
    end

    multValues = targetNominal ./ baseNominal;
end


function addValues = local_level_to_additive(h, varName, dates, targetLevel)
% Convierte un nivel objetivo a aditivo respecto del baseline.
%
% Ejemplo:
%   targetLevel = -0.5 para L_GDP_GAP.
%   addValue    = -0.5 - baseline.

    if ~isfield(h, varName)
        error('No existe %s en el baseline.', varName);
    end

    targetLevel = reshape(targetLevel, 1, []);
    dates       = reshape(dates, 1, []);

    baseLevel = h.(varName)(dates);
    baseLevel = reshape(baseLevel, 1, []);

    if isscalar(targetLevel) && numel(baseLevel) > 1
        targetLevel = repmat(targetLevel, 1, numel(baseLevel));
    end

    if numel(baseLevel) ~= numel(targetLevel)
        error('local_level_to_additive: targetLevel no coincide con dates.');
    end

    addValues = targetLevel - baseLevel;
end


function out = local_take_path(path, n)

    path = reshape(path, [], 1);

    if isempty(path)
        error('local_take_path: path vacío.');
    end

    if length(path) >= n
        out = path(1:n);
    else
        out = [path; repmat(path(end), n - length(path), 1)];
    end
end


function [d, planItems] = local_apply_scenario(h, d, catalog, altRange)

    tolNeutral = 1e-12;
    nAlt       = length(altRange);

    planItems = struct('var', {}, 'shock', {}, 'dates', {}, 'type', {});

    fprintf('\n============================================================\n');
    fprintf('Aplicando escenario\n');
    fprintf('============================================================\n');

    for i = 1:size(catalog,1)

        v  = catalog{i,1};
        sh = catalog{i,2};
        tp = lower(catalog{i,3});
        pp = local_take_path(catalog{i,4}, nAlt);

        if ~isfield(h, v)
            fprintf('[OMITIDO] %-14s no existe en baseline.\n', v);
            continue
        end

        switch tp
            case 'mult'
                activeIdx = find(abs(pp - 1) > tolNeutral);

            case 'add'
                activeIdx = find(abs(pp) > tolNeutral);

            otherwise
                error('Tipo no reconocido para %s: %s', v, tp);
        end

        if isempty(activeIdx)
            fprintf('[NEUTRO]  %-14s queda endógena.\n', v);
            continue
        end

        if ~(isfield(h, sh) || isfield(d, sh))
            fprintf('[AVISO]   %-14s tiene path activo, pero no encuentro shock %-18s. No se impone.\n', v, sh);
            continue
        end

        activeDates = altRange(activeIdx);
        base_v      = h.(v)(activeDates);

        switch tp
            case 'mult'
                delta = 100 * log(pp(activeIdx));

            case 'add'
                delta = pp(activeIdx);
        end

        delta = reshape(delta, size(base_v));

        d.(v)(activeDates) = base_v + delta;

        planItems(end+1).var   = v;           %#ok<AGROW>
        planItems(end).shock   = sh;
        planItems(end).dates   = activeDates;
        planItems(end).type    = tp;

        fprintf('[ACTIVO]  %-14s con %-18s | %s a %s | n = %d\n', ...
            v, sh, local_dat2char(activeDates(1)), ...
            local_dat2char(activeDates(end)), length(activeDates));
    end
end


function simplan = local_build_plan(m, fcastrange, planItems)

    simplan = plan(m, fcastrange);

    fprintf('\n============================================================\n');
    fprintf('Plan de simulación\n');
    fprintf('============================================================\n');

    if isempty(planItems)
        warning('No hay variables exogenizadas. El escenario será igual al baseline salvo cambios externos ya cargados.');
        return
    end

    for i = 1:numel(planItems)

        v  = planItems(i).var;
        sh = planItems(i).shock;
        rr = planItems(i).dates;

        fprintf('Exogenize %-14s | Endogenize %-18s | %s a %s | n = %d\n', ...
            v, sh, local_dat2char(rr(1)), local_dat2char(rr(end)), length(rr));

        simplan = exogenize(simplan, v,  rr);
        simplan = endogenize(simplan, sh, rr);
    end
end


function local_print_diagnostics(h, d_alt, altRange, diagVars)

    fprintf('\n============================================================\n');
    fprintf('Diferencias Alt - Baseline en rango alternativo\n');
    fprintf('============================================================\n');

    for i = 1:numel(diagVars)

        v = diagVars{i};

        if ~(isfield(h, v) && isfield(d_alt, v))
            continue
        end

        try
            diffv = d_alt.(v)(altRange) - h.(v)(altRange);
            diffv = diffv(~isnan(diffv));

            if isempty(diffv)
                continue
            end

            fprintf('%-14s | mean diff = %+9.4f | max abs diff = %+9.4f\n', ...
                v, mean(diffv), max(abs(diffv)));
        catch
        end
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


function local_make_report(h, d_alt, planItems, country, altname, exchange, reportName, Plotrng, Tablerng, ObsRng, AltRng)

    x = report.new(country);

    sty = struct();
    sty.line.linewidth         = 1.5;
    sty.line.linestyle         = {'-';'--'};
    sty.axes.box               = 'on';
    sty.legend.location        = 'Best';
    sty.axes.yticklabelformat  = '%.1f';


    %% ========================================================
    %% Figura principal
    %% ========================================================

    x.figure([altname ' - Main Indicators'], ...
        'subplot', [3,2], ...
        'style', sty, ...
        'range', Plotrng, ...
        'dateformat', 'YYYY:P');

    local_graph_two(x, 'Policy Rate, % p.a.', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'TPM', ObsRng, AltRng);

    local_graph_two(x, 'Output Gap, %', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'L_GDP_GAP', ObsRng, AltRng);

    local_graph_two(x, 'Headline Inflation, % YoY', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'D4L_CPI', ObsRng, AltRng);

    local_graph_two(x, 'Core Inflation, % YoY', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'D4L_CPIXFE', ObsRng, AltRng);

    local_graph_two(x, 'Oil Price, USD per barrel', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'L_WTI_NOM', ObsRng, AltRng);

    local_graph_two(x, ['Real Exchange Rate Index - ' exchange], ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'L_Z_INDEX', ObsRng, AltRng);

    x.pagebreak();


    %% ========================================================
    %% Inflación doméstica
    %% ========================================================

    x.figure([altname ' - Inflation Details'], ...
        'subplot', [2,2], ...
        'style', sty, ...
        'range', Plotrng, ...
        'dateformat', 'YYYY:P');

    if local_has_fields(h, d_alt, {'DLA_CPI','D4L_CPI'})
        x.graph('Headline Inflation, % QoQ annualized and YoY', 'legend', true);
        x.series({'QoQ Base','YoY Base','QoQ Alt','YoY Alt'}, ...
            [h.DLA_CPI, h.D4L_CPI, d_alt.DLA_CPI, d_alt.D4L_CPI]);
        x.highlight('', ObsRng);
        x.highlight('', AltRng);
    end

    if local_has_fields(h, d_alt, {'DLA_CPIXFE','D4L_CPIXFE'})
        x.graph('Core Inflation, % QoQ annualized and YoY', 'legend', true);
        x.series({'QoQ Base','YoY Base','QoQ Alt','YoY Alt'}, ...
            [h.DLA_CPIXFE, h.D4L_CPIXFE, d_alt.DLA_CPIXFE, d_alt.D4L_CPIXFE]);
        x.highlight('', ObsRng);
        x.highlight('', AltRng);
    end

    local_graph_two(x, 'Residual Inflation DLA\_CPIRES, % QoQ annualized', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'DLA_CPIRES', ObsRng, AltRng);

    local_graph_two(x, 'Headline-Core Gap, pp YoY', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'D4L_CPI_GAP_XFE', ObsRng, AltRng);

    x.pagebreak();


    %% ========================================================
    %% Bloque externo
    %% ========================================================

    x.figure([altname ' - External Block'], ...
        'subplot', [3,2], ...
        'style', sty, ...
        'range', Plotrng, ...
        'dateformat', 'YYYY:P');

    local_graph_two(x, 'Oil Price, USD per barrel', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'L_WTI_NOM', ObsRng, AltRng);

    local_graph_two(x, 'Copper Price, USD per lb', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'L_PCU_NOM', ObsRng, AltRng);

    local_graph_two(x, 'Foreign Output Growth, %', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'CRECSC', ObsRng, AltRng);

    local_graph_two(x, 'Federal Funds Rate, %', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'FFR', ObsRng, AltRng);

    local_graph_two(x, 'UST 10Y, %', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'UST10', ObsRng, AltRng);

    local_graph_two(x, 'VIX', ...
        {'Baseline IPOM','Alternative'}, h, d_alt, 'VIX', ObsRng, AltRng);

    x.pagebreak();


    %% ========================================================
    %% Shocks efectivamente activados
    %% ========================================================

    if ~isempty(planItems)

        shockNames = unique({planItems.shock}, 'stable');
        nShock     = min(numel(shockNames), 6);

        x.figure([altname ' - Active Shocks'], ...
            'subplot', [ceil(nShock/2), 2], ...
            'style', sty, ...
            'range', AltRng, ...
            'dateformat', 'YYYY:P');

        for i = 1:nShock
            sh = shockNames{i};

            if isfield(h, sh) && isfield(d_alt, sh)
                graphTitle = strrep(sh, '_', '\_');
                x.graph(graphTitle, 'legend', true);
                x.series({'Baseline','Alternative'}, [h.(sh), d_alt.(sh)]);
            end
        end

        x.pagebreak();
    end


    %% ========================================================
    %% Tabla resumen
    %% ========================================================

    TableOptions = {'range', Tablerng, ...
                    'vline', qq(2025,4), ...
                    'decimal', 2, ...
                    'dateformat', 'YYYY:P', ...
                    'long', true, ...
                    'longfoot', '---continued', ...
                    'longfootposition', 'right'};

    x.table([altname ' - Summary Table'], TableOptions{:});

    x.subheading('Inflation');

    local_table_two(x, h, d_alt, 'D4L_CPI',    'Headline CPI YoY', '%');
    local_table_two(x, h, d_alt, 'D4L_CPIXFE', 'Core CPI YoY', '%');
    local_table_two(x, h, d_alt, 'D4L_CPI_GAP_XFE', 'Headline-Core Gap YoY', 'pp');

    x.subheading('Activity and Monetary Policy');

    local_table_two(x, h, d_alt, 'L_GDP_GAP', 'Output Gap', '%');
    local_table_two(x, h, d_alt, 'TPM',       'Policy Rate', '%');

    x.subheading('External Assumptions and Financial Conditions');

    local_table_two(x, h, d_alt, 'L_WTI_NOM', 'Oil Price', 'USD/bbl');
    local_table_two(x, h, d_alt, 'L_PCU_NOM', 'Copper Price', 'USD/lb');
    local_table_two(x, h, d_alt, 'CRECSC',    'Foreign Growth', '%');
    local_table_two(x, h, d_alt, 'FFR',       'FFR', '%');
    local_table_two(x, h, d_alt, 'UST10',     'UST10', '%');
    local_table_two(x, h, d_alt, 'VIX',       'VIX', '');

    x.publish(reportName, 'display', false);

    fprintf('\nReporte generado: %s.pdf\n', reportName);
end


function local_graph_two(x, graphTitle, legendNames, h, d_alt, varName, ObsRng, AltRng)

    if ~(isfield(h, varName) && isfield(d_alt, varName))
        x.graph([graphTitle ' - missing'], 'legend', false);
        return
    end

    x.graph(graphTitle, 'legend', true);
    x.series(legendNames, [h.(varName), d_alt.(varName)]);
    x.highlight('', ObsRng);
    x.highlight('', AltRng);
end


function local_table_two(x, h, d_alt, varName, label, units)

    if ~(isfield(h, varName) && isfield(d_alt, varName))
        return
    end

    x.series([label ' - Baseline'],    h.(varName),     'units', units);
    x.series([label ' - Alternative'], d_alt.(varName), 'units', units);
end


function tf = local_has_fields(h, d_alt, vars)

    tf = true;

    for i = 1:numel(vars)
        v = vars{i};

        if ~(isfield(h, v) && isfield(d_alt, v))
            tf = false;
            return
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