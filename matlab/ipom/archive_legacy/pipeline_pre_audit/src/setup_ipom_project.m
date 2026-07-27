function cfg = setup_ipom_project()
%SETUP_IPOM_PROJECT Prepara paths, carpetas e IRIS para el bloque IPoM.
%
% Uso recomendado desde MATLAB:
%   cd('D:\Users\mullo\Documents\GitHub\Economics\matlab\ipom\src')
%   setup_ipom_project
%   run_all_ipom
%
% Este setup esta pensado para IRIS Toolbox 2019, que se activa con:
%   addpath C:\IRIS-Toolbox-Release-20191112; irisstartup

    cfg = config_ipom();

    local_ensure_dir(cfg.rawOutputDir);
    local_ensure_dir(cfg.quartoOutputDir);
    local_ensure_dir(cfg.runtimeDir); %#ok<NASGU> % legacy/respaldo

    local_add_path_once(cfg.srcDir);
    local_add_path_once(cfg.modelDir);

    if cfg.startIris
        local_start_iris(cfg);
    end

    if cfg.requireIris
        local_assert_iris_ready();
    end

    fprintf('\n============================================================\n');
    fprintf('Proyecto IPoM/IRIS listo\n');
    fprintf('Repo:        %s\n', cfg.repoDir);
    fprintf('IPoM:        %s\n', cfg.ipomDir);
    fprintf('Modelo:      %s\n', cfg.modelFile);
    fprintf('Inputs:      %s\n', cfg.inputDir);
    fprintf('Raw outputs: %s\n', cfg.rawOutputDir);
    fprintf('IRIS path:   %s\n', cfg.irisPath);
    fprintf('============================================================\n\n');
end

function local_ensure_dir(d)
    if exist(d, 'dir') ~= 7
        mkdir(d);
    end
end

function local_add_path_once(d)
    if exist(d, 'dir') ~= 7
        error('No existe la carpeta requerida: %s', d);
    end

    currentPath = path;
    sep = pathsep;
    if isempty(strfind([sep currentPath sep], [sep d sep])) %#ok<STREMP>
        addpath(d);
    end
end

function local_start_iris(cfg)
    if ~isempty(cfg.irisPath)
        if exist(cfg.irisPath, 'dir') ~= 7
            error(['No existe cfg.irisPath: %s\n' ...
                   'Edita matlab/ipom/src/config_ipom.m o activa IRIS manualmente.'], cfg.irisPath);
        end
        local_add_path_once(cfg.irisPath);
    end

    rehash;

    % IRIS antiguo, incluido Release 20191112.
    if exist('irisstartup', 'file') == 2
        fprintf('Activando IRIS con irisstartup...\n');
        irisstartup;
        return;
    end

    % IRIS mas nuevo.
    try
        if exist('iris', 'class') == 8 || exist('iris.startup', 'file') == 2
            fprintf('Activando IRIS con iris.startup...\n');
            iris.startup;
            return;
        end
    catch ME
        warning('No pude ejecutar iris.startup: %s', ME.message);
    end
end

function local_assert_iris_ready()
    missing = {};
    % Chequeo conservador: algunas funciones de IRIS como simulate pueden
    % existir solo como metodos de clase y no aparecer con exist(...,'file').
    needed = {'qq', 'dbload', 'dbsave', 'model'};

    for i = 1:numel(needed)
        f = needed{i};
        if exist(f, 'file') ~= 2 && exist(f, 'builtin') ~= 5 && exist(f, 'class') ~= 8
            missing{end+1} = f; %#ok<AGROW>
        end
    end

    if ~isempty(missing)
        error(['IRIS no parece estar activo. Faltan funciones/comandos: %s\n' ...
               'Activa IRIS manualmente con:\n' ...
               '  addpath C:\\IRIS-Toolbox-Release-20191112; irisstartup\n' ...
               'o edita cfg.irisPath en config_ipom.m.'], strjoin(missing, ', '));
    end
end
