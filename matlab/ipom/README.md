# IPoM / IRIS · pipeline activo

Subproyecto Matlab/IRIS para identificar un escenario base y construir trayectorias condicionales de TPM, inflación y brecha de actividad.

## Entrada principal

Desde Matlab, abre `matlab/ipom/` y ejecuta:

```matlab
run_project
```

Para el escenario que mantiene la TPM en 4,5% durante 2026 y retorna a la trayectoria base desde 2027:

```matlab
run_tpm45_2026
```

Opciones:

```matlab
IPOM_REBUILD_HISTORY = true;  % reconstruye history.csv desde Data.csv
IPOM_RUN_REPORT = true;       % genera reportes PDF IRIS
run_tpm45_2026
```

## Estructura operativa

```text
config_ipom.m             rutas centralizadas
startup_ipom.m            agrega únicamente el código activo al path
run_project.m             baseline + escenario general
run_tpm45_2026.m          escenario TPM 4,5%
data/raw/                  insumos originales
data/processed/            history.csv utilizado por IRIS
src/matlab/model/          modelo activo
src/matlab/scripts/        pasos ordenados del pipeline
output/raw/                CSV finales de IRIS
output/reports/            reportes opcionales
archive_legacy/            versiones anteriores fuera del path
```

La ruta de IRIS no está codificada en el repositorio. Debe agregarse al path de Matlab antes de ejecutar, según la instalación local.

## Integración con el portafolio

Después de una corrida Matlab:

```bash
Rscript scripts/03_build_ipom_outputs.R
python scripts/build_site.py
python scripts/validate_site.py
```

El paso R transforma los CSV de `matlab/ipom/output/raw/` en bases estandarizadas bajo `data/processed/ipom/`.

## Alcance de la auditoría

La reorganización preservó el modelo y la lógica de forecast. La validación incluida en este repositorio es estructural para Matlab/IRIS; una reestimación completa requiere una instalación compatible de Matlab e IRIS Toolbox.
