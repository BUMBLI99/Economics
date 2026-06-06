%% MAKEDATA compatibility wrapper
% En el proyecto ordenado, la versión canónica de makedata es
% step00_build_history_from_data.m. Este archivo existe para que el hábito
% antiguo de ejecutar `makedata` siga funcionando.

cfg = startup_ipom();
run(fullfile(cfg.scriptDir, 'step00_build_history_from_data.m'));
