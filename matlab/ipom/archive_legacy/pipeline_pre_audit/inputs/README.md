# Inputs del motor IRIS

Archivos de entrada mínimos para correr el pipeline Matlab/IRIS.

- `history.csv`: base histórica en formato `dbsave/dbload` de IRIS.
- `Data.csv`: insumo para regenerar `history.csv` con `makedata.m`, si decides reconstruir la historia.
- `ipom_paths.csv`: opcional. Si existe, `identificar_shocks_ipom.m` lo usa para imponer las trayectorias tipo IPoM. Si no existe, usa `history.csv` como pseudo-IPoM.

Los datos originales grandes o desordenados quedan fuera de esta carpeta para mantener el repo limpio.
