%%%%%%%%%%%%
%% alternatives.m
%% Baseline = último IPOM
%% Escenario alternativo externo tipo risk-off
%%%%%%%%%%%%

close all;
clear all;

%% ============================================================
%% 1. Cargar modelo y baseline
%% ============================================================

[m,p,mss] = readmodel_alternativo(false);

% Baseline resuelto por Forecast.m
h = dbload('fcast_ipom.csv');

% Historia observada / pseudo-historia IPOM
hist_db = dbload('history.csv');

% Copia de trabajo para el alternativo
d = h;

%% 1.b Sincronizar baseline con history.csv donde haya datos válidos

vars_sync = { ...
    'L_GDP','L_GDP_BAR','L_GDP_GAP', ...
    'L_CPI','L_CPIXFE','D4L_CPI','D4L_CPIXFE','DLA_CPI','DLA_CPIXFE','DLA_CPIRES', ...
    'TPM','TPMN1','T_COLOC', ...
    'L_Z','L_Z_GAP', ...
    'CRECSC','FFR','UST10','VIX', ...
    'L_PCU','L_WTI','CPI_US_2020' ...
};

copyRange = qq(2000,1):qq(2029,4);

for i = 1:numel(vars_sync)
    v = vars_sync{i};

    if isfield(hist_db, v) && isfield(h, v)
        x = hist_db.(v)(copyRange);
        ix = ~isnan(x);

        if any(ix)
            h.(v)(copyRange(ix)) = x(ix);
            d.(v)(copyRange(ix)) = x(ix);
        end
    end
end


%% ============================================================
%% 2. Horizonte del escenario alternativo
%% ============================================================

% Ajusta esta fecha si quieres que el alternativo parta antes.
% Actualmente parte en 2026Q3.
startfcast_alt = qq(2026,1);
endfcast       = qq(2027,3);

% Se extiende más allá del horizonte reportado porque la regla de política
% y la Phillips tienen términos forward-looking.
fcastrange = startfcast_alt:(endfcast+8);

shockEnd = min(qq(2027,4), endfcast);
altRange = startfcast_alt:shockEnd;
nAlt     = length(altRange);


%% ============================================================
%% 3. Escenario alternativo externo
%% ============================================================

% Paths definidos como desvíos respecto del baseline IPOM.
% Se recortan automáticamente al largo de altRange.

wti_mult_path   = [1.10, 1.08, 1.06, 1.04, 1.03, 1.02, 1.00];
pcu_mult_path   = [0.96, 0.96, 0.97, 0.98, 0.99, 1.00, 1.00];
vix_add_path    = [2.00, 1.00, 0.80, 0.50, 0.40, 0.25, 0.20];
ffr_add_path    = [0.25, 0.10, 0.10, 0.10, 0.05, 0.00, 0.00];
ust10_add_path  = [0.25, 0.20, 0.15, 0.10, 0.10, 0.05, 0.00];
crec_sub_path   = [0.25, 0.20, 0.15, 0.15, 0.015, 0.00, 0.00];
lz_mult_path    = [1.020, 1.020, 1.015, 1.010, 1.005, 1.005, 1.000];

% Convertir a vector columna
col = @(x) reshape(x(1:nAlt), [], 1);

wti_mult  = col(wti_mult_path);
pcu_mult  = col(pcu_mult_path);
vix_add   = col(vix_add_path);
ffr_add   = col(ffr_add_path);
ust10_add = col(ust10_add_path);
crec_sub  = col(crec_sub_path);
lz_mult   = col(lz_mult_path);


%% ============================================================
%% 4. Aplicar desvíos sobre baseline IPOM
%% ============================================================

base_L_WTI = h.L_WTI(altRange);
base_L_PCU = h.L_PCU(altRange);
base_L_Z   = h.L_Z(altRange);
base_VIX   = h.VIX(altRange);
base_FFR   = h.FFR(altRange);
base_UST10 = h.UST10(altRange);
base_CRESC = h.CRECSC(altRange);

% Shock externo propiamente tal
%d.L_WTI(altRange)  = base_L_WTI + 100*log(wti_mult);
%d.L_PCU(altRange)  = base_L_PCU + 100*log(pcu_mult);
%d.VIX(altRange)    = base_VIX   + vix_add;
%d.FFR(altRange)    = base_FFR   + ffr_add;
%d.UST10(altRange)  = base_UST10 + ust10_add;
%d.CRECSC(altRange) = base_CRESC - crec_sub;
%d.L_Z(altRange)    = base_L_Z   + 100*log(lz_mult);

% Mantener CPI_US_2020 del baseline si existe
if isfield(h,'CPI_US_2020')
    d.CPI_US_2020(altRange) = h.CPI_US_2020(altRange);
end


%% ============================================================
%% 5. Plan de simulación
%% ============================================================

simplan = plan(m, fcastrange);

% Fijamos bloque externo y TCR. 
% Dejamos T_COLOC endógena, salvo que tengas un path propio para ella.
simplan = exogenize(simplan, ...
    {'L_WTI','L_PCU','VIX','FFR','UST10','CRECSC','L_Z'}, ...
    altRange);

simplan = endogenize(simplan, ...
    {'SHK_L_WTI','SHK_L_PCU','SHK_VIX','SHK_FFR','SHK_UST10','SHK_CRECSC','SHK_L_Z'}, ...
    altRange);


%% ============================================================
%% 6. Simular escenario principal
%% ============================================================

s = simulate(m, d, fcastrange, ...
    'plan',       simplan, ...
    'method',     'selective', ...
    'nonlinPer',  30, ...
    'anticipate', false);

d_alt = dbextend(d, s);


%% ============================================================
%% 6.b Contribuciones: diagnóstico opcional
%% ============================================================

doContributions = false;

if doContributions
    s_contrib = simulate(m, d, fcastrange, ...
        'plan',          simplan, ...
        'method',        'selective', ...
        'nonlinPer',     30, ...
        'anticipate',    false, ...
        'contributions', true);

    d_contrib = dbextend(d, s_contrib);
end


%% ============================================================
%% 7. Variables nominales y variables derivadas para gráficos
%% ============================================================

if isfield(h,'CPI_US_2020')
    h.L_PCU_NOM     = exp(h.L_PCU/100)     .* h.CPI_US_2020/100;
    h.L_WTI_NOM     = exp(h.L_WTI/100)     .* h.CPI_US_2020/100;
    d_alt.L_PCU_NOM = exp(d_alt.L_PCU/100) .* d_alt.CPI_US_2020/100;
    d_alt.L_WTI_NOM = exp(d_alt.L_WTI/100) .* d_alt.CPI_US_2020/100;
else
    h.L_PCU_NOM     = exp(h.L_PCU/100);
    h.L_WTI_NOM     = exp(h.L_WTI/100);
    d_alt.L_PCU_NOM = exp(d_alt.L_PCU/100);
    d_alt.L_WTI_NOM = exp(d_alt.L_WTI/100);
end

% TCR en índice
h.L_Z_INDEX     = exp(h.L_Z/100);
d_alt.L_Z_INDEX = exp(d_alt.L_Z/100);

% Brecha headline-core YoY: útil para ver el componente no subyacente anual
h.D4L_CPI_GAP_XFE     = h.D4L_CPI - h.D4L_CPIXFE;
d_alt.D4L_CPI_GAP_XFE = d_alt.D4L_CPI - d_alt.D4L_CPIXFE;


%% ============================================================
%% 8. Guardar resultado
%% ============================================================

dbsave(d_alt, 'fcast_alt_riskoff.csv');


%% ============================================================
%% 9. Rangos de reporte / gráficos
%% ============================================================

Tablerng = qq(2025,1):endfcast;
Plotrng  = qq(2025,1):max(qq(2027,4), endfcast);

ObsRng = qq(2025,1):qq(2025,4);
AltRng = altRange;

country  = 'Chile';
exchange = 'CHL/USA';
altname  = 'Alternative Scenario - Global Risk-Off';

x = report.new(country);

sty = struct();
sty.line.linewidth         = 1.5;
sty.line.linestyle         = {'-';'--'};
sty.axes.box               = 'on';
sty.legend.location        = 'Best';
sty.axes.yticklabelformat  = '%.1f';


%% ============================================================
%% 10. Figura principal
%% ============================================================

x.figure([altname ' - Main Indicators'], ...
    'subplot', [3,2], ...
    'style', sty, ...
    'range', Plotrng, ...
    'dateformat', 'YYYY:P');

x.graph('Policy Rate, % p.a.', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.TPM, d_alt.TPM]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Output Gap, %', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.L_GDP_GAP, d_alt.L_GDP_GAP]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Headline Inflation, % YoY', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.D4L_CPI, d_alt.D4L_CPI]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Core Inflation, % YoY', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.D4L_CPIXFE, d_alt.D4L_CPIXFE]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Oil Price, USD per barrel', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.L_WTI_NOM, d_alt.L_WTI_NOM]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph(['Real Exchange Rate Index - ' exchange], 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.L_Z_INDEX, d_alt.L_Z_INDEX]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.pagebreak();


%% ============================================================
%% 11. Figura de inflación doméstica
%% ============================================================

x.figure([altname ' - Inflation Details'], ...
    'subplot', [2,2], ...
    'style', sty, ...
    'range', Plotrng, ...
    'dateformat', 'YYYY:P');

x.graph('Headline Inflation, % QoQ and YoY', 'legend', true);
x.series({'QoQ Base','YoY Base','QoQ Alt','YoY Alt'}, ...
    [h.DLA_CPI, h.D4L_CPI, d_alt.DLA_CPI, d_alt.D4L_CPI]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Core Inflation, % QoQ and YoY', 'legend', true);
x.series({'QoQ Base','YoY Base','QoQ Alt','YoY Alt'}, ...
    [h.DLA_CPIXFE, h.D4L_CPIXFE, d_alt.DLA_CPIXFE, d_alt.D4L_CPIXFE]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Residual Inflation DLA\_CPIRES, % QoQ annualized', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.DLA_CPIRES, d_alt.DLA_CPIRES]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Headline-Core Gap, pp YoY', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.D4L_CPI_GAP_XFE, d_alt.D4L_CPI_GAP_XFE]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.pagebreak();


%% ============================================================
%% 12. Figura externa
%% ============================================================

x.figure([altname ' - External Block'], ...
    'subplot', [3,2], ...
    'style', sty, ...
    'range', Plotrng, ...
    'dateformat', 'YYYY:P');

x.graph('Oil Price, USD per barrel', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.L_WTI_NOM, d_alt.L_WTI_NOM]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Copper Price, USD per lb', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.L_PCU_NOM, d_alt.L_PCU_NOM]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Foreign Output Growth, %', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.CRECSC, d_alt.CRECSC]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('Federal Funds Rate, %', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.FFR, d_alt.FFR]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('UST 10Y, %', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.UST10, d_alt.UST10]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.graph('VIX', 'legend', true);
x.series({'Baseline IPOM','Alternative'}, [h.VIX, d_alt.VIX]);
x.highlight('', ObsRng);
x.highlight('', AltRng);

x.pagebreak();


%% ============================================================
%% 13. Tabla resumen mejorada
%% ============================================================

TableOptions = {'range', Tablerng, ...
                'vline', qq(2025,4), ...
                'decimal', 2, ...
                'dateformat', 'YYYY:P', ...
                'long', true, ...
                'longfoot', '---continued', ...
                'longfootposition', 'right'};

x.table([altname ' - Summary Table'], TableOptions{:});

x.subheading('Inflation');

x.series('Headline CPI YoY - Baseline',     h.D4L_CPI,                         'units', '%');
x.series('Headline CPI YoY - Alternative',  d_alt.D4L_CPI,                     'units', '%');

x.series('Core CPI YoY - Baseline',         h.D4L_CPIXFE,                      'units', '%');
x.series('Core CPI YoY - Alternative',      d_alt.D4L_CPIXFE,                  'units', '%');

x.series('Headline CPI QoQ - Baseline',      h.DLA_CPI,                        'units', '% ar');
x.series('Headline CPI QoQ - Alternative',   d_alt.DLA_CPI,                    'units', '% ar');
x.series('Core CPI QoQ - Baseline',          h.DLA_CPIXFE,                     'units', '% ar');
x.series('Core CPI QoQ - Alternative',       d_alt.DLA_CPIXFE,                 'units', '% ar');

x.series('Residual DLA_CPIRES - Baseline',   h.DLA_CPIRES,                     'units', '% ar');
x.series('Residual DLA_CPIRES - Alternative',d_alt.DLA_CPIRES,                 'units', '% ar');

x.series('Headline-Core Gap YoY - Baseline',    h.D4L_CPI_GAP_XFE,             'units', 'pp');
x.series('Headline-Core Gap YoY - Alternative', d_alt.D4L_CPI_GAP_XFE,         'units', 'pp');


x.subheading('Activity and Monetary Policy');

x.series('Output Gap - Baseline',           h.L_GDP_GAP,                       'units', '%');
x.series('Output Gap - Alternative',        d_alt.L_GDP_GAP,                   'units', '%');
x.series('Output Gap - Alt minus Base',     d_alt.L_GDP_GAP - h.L_GDP_GAP,     'units', 'pp');

x.series('Policy Rate - Baseline',          h.TPM,                             'units', '%');
x.series('Policy Rate - Alternative',       d_alt.TPM,                         'units', '%');
x.series('Policy Rate - Alt minus Base',    d_alt.TPM - h.TPM,                 'units', 'pp');


x.subheading('External Assumptions and Financial Conditions');

x.series('Oil Price - Baseline',            h.L_WTI_NOM,                       'units', 'USD/bbl');
x.series('Oil Price - Alternative',         d_alt.L_WTI_NOM,                   'units', 'USD/bbl');

x.series('Copper Price - Baseline',         h.L_PCU_NOM,                       'units', 'USD/lb');
x.series('Copper Price - Alternative',      d_alt.L_PCU_NOM,                   'units', 'USD/lb');

x.series('RER Index - Baseline',            h.L_Z_INDEX);
x.series('RER Index - Alternative',         d_alt.L_Z_INDEX);

x.series('Foreign Growth - Baseline',       h.CRECSC,                          'units', '%');
x.series('Foreign Growth - Alternative',    d_alt.CRECSC,                      'units', '%');
x.series('Foreign Growth - Alt minus Base', d_alt.CRECSC - h.CRECSC,           'units', 'pp');

x.series('FFR - Baseline',                  h.FFR,                             'units', '%');
x.series('FFR - Alternative',               d_alt.FFR,                         'units', '%');
x.series('UST10 - Baseline',                h.UST10,                           'units', '%');
x.series('UST10 - Alternative',             d_alt.UST10,                       'units', '%');
x.series('VIX - Baseline',                  h.VIX);
x.series('VIX - Alternative',               d_alt.VIX);


%% ============================================================
%% 14. Contribuciones: solo si doContributions = true
%% ============================================================

if doContributions

    nContrib = size(d_contrib.D4L_CPIXFE(Plotrng), 2);
    fprintf('\nNumero de contribuciones en D4L_CPIXFE: %g\n', nContrib);

    try
        contribLabels = get(d_contrib.D4L_CPIXFE, 'Comment');
    catch
        try
            contribLabels = comment(d_contrib.D4L_CPIXFE);
        catch
            contribLabels = cell(1, nContrib);
            for i = 1:nContrib
                contribLabels{i} = ['Contrib ' num2str(i)];
            end
        end
    end

    x.pagebreak();

    x.figure([altname ' - Contributions'], ...
        'subplot', [2,1], ...
        'style', sty, ...
        'range', Plotrng, ...
        'dateformat', 'YYYY:P');

    x.graph('Core Inflation YoY - Contributions', 'legend', true);
    x.series(contribLabels, d_contrib.D4L_CPIXFE);
    x.highlight('', ObsRng);
    x.highlight('', AltRng);

    x.graph('Output Gap - Contributions', 'legend', true);
    x.series(contribLabels, d_contrib.L_GDP_GAP);
    x.highlight('', ObsRng);
    x.highlight('', AltRng);

end


%% ============================================================
%% 15. Publicar
%% ============================================================

x.publish('AlternativeScenario_GlobalRiskOff', 'display', false);

disp('Done (Alternative Scenario - Global Risk-Off)!');