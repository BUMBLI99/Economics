function cfg = startup_ipom()
%STARTUP_IPOM  Agrega al path las carpetas necesarias para correr el proyecto.

    root = fileparts(mfilename('fullpath'));
    addpath(root);
    addpath(fullfile(root, 'src', 'matlab', 'model'));
    addpath(fullfile(root, 'src', 'matlab', 'scripts'));
    cfg = config_ipom();

    fprintf('\nProyecto IPOM/IRIS inicializado.\n');
    fprintf('Raiz: %s\n', cfg.projectRoot);
end
