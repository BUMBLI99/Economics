function cfg = config_ipom()
%CONFIG_IPOM Configuracion central del subproyecto IPoM/IRIS.
%
% Este archivo es el unico lugar donde deberias editar rutas globales.
% Las ecuaciones del modelo estan en ../model/minimep0.model y NO se tocan
% desde este archivo.

    thisFile = mfilename('fullpath');
    srcDir   = fileparts(thisFile);
    ipomDir  = fileparts(srcDir);
    repoDir  = fileparts(fileparts(ipomDir));

    cfg.repoDir          = repoDir;
    cfg.ipomDir          = ipomDir;
    cfg.srcDir           = srcDir;
    cfg.modelDir         = fullfile(ipomDir, 'model');
    cfg.inputDir         = fullfile(ipomDir, 'inputs');
    cfg.rawOutputDir     = fullfile(ipomDir, 'outputs', 'raw_iris');
    cfg.quartoOutputDir  = fullfile(ipomDir, 'outputs', 'quarto');
    cfg.runtimeDir       = fullfile(ipomDir, 'runtime');       % queda solo como respaldo/legacy
    cfg.legacyDir        = fullfile(ipomDir, 'legacy_original');

    cfg.modelFile        = fullfile(cfg.modelDir, 'minimep0.model');

    % ------------------------------------------------------------------
    % IRIS Toolbox
    % ------------------------------------------------------------------
    % Tu instalacion actual. Si en otro computador cambia la ruta, edita
    % solamente esta linea.
    cfg.irisPath = 'C:\IRIS-Toolbox-Release-20191112';

    % IRIS 2019 normalmente se activa con:
    %   addpath C:\IRIS-Toolbox-Release-20191112; irisstartup
    % setup_ipom_project.m hace exactamente eso si startIris=true.
    cfg.startIris  = true;
    cfg.requireIris = true;

    % ------------------------------------------------------------------
    % Control operativo
    % ------------------------------------------------------------------
    % El flujo nuevo NO copia scripts a runtime. Cada script usa rutas
    % absolutas derivadas desde config_ipom(). Esto evita errores por pwd.
    cfg.useRuntime = false;

    % Normalmente history.csv ya viene preparado. Activa esto solo si quieres
    % reconstruir history.csv desde inputs/Data.csv usando makedata.m.
    cfg.runMakeData = false;

    % Flujo principal
    cfg.runBaseline       = true;
    cfg.runAlternative    = true;
    cfg.runIrisPdfReports = false;  % Quarto usa CSV; los PDF IRIS son opcionales.

    % Scripts activos del flujo nuevo.
    cfg.activeScripts = { ...
        'readmodel_alternativo.m', ...
        'identificar_shocks_ipom.m', ...
        'fcast_alt_ipom.m' ...
    };

    % Entradas minimas.
    cfg.inputFiles = { ...
        'history.csv', ...
        'Data.csv', ...
        'ipom_paths.csv' ... % opcional; si no existe se omite.
    };

    % Outputs crudos que procesa R/Quarto.
    cfg.outputFiles = { ...
        'history.csv', ...
        'fcast_ipom_exact.csv', ...
        'fcast_ipom_with_shocks.csv', ...
        'fcast_alt_escenario.csv', ...
        'fcast_alt_iran_fin_anticipado.csv', ...
        'fcast_alt_riskoff.csv', ...
        'fcast_base_model.csv' ...
    };
end
