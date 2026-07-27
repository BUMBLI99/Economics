# Corrida especial: TPM 4.5% durante 2026

Solicitud operativa: mantener todo igual al escenario alternativo vigente y cambiar solo la trayectoria de TPM, fijándola en 4.5% durante 2026 y forzando retorno exacto a la trayectoria IPOM/baseline desde 2027Q1.

## Comando MATLAB

```matlab
run_tpm45_2026
```

Con PDF IRIS:

```matlab
IPOM_RUN_REPORT = true;
run_tpm45_2026
```

Si actualizaste `data/raw/Data.csv` desde R y necesitas reconstruir `data/processed/history.csv`:

```matlab
IPOM_REBUILD_HISTORY = true;
run_tpm45_2026
```

## Archivos de salida

- `output/raw/fcast_alt_tpm45_2026.csv`: escenario nuevo con TPM 4.5.
- `output/raw/fcast_alt_escenario.csv`: copia compatible para el normalizador R y los reportes del portafolio.
- `output/reports/Escenario_TPM45_2026.pdf`: si `IPOM_RUN_REPORT = true`.

## Dónde está el cambio

El cambio está en:

`src/matlab/scripts/step02_fcast_alt_tpm45_2026.m`

Bloque:

```matlab
tpm_dates_2026 = qq(2026,1):qq(2026,4);
tpm_target_2026 = 4.5 * ones(1, length(tpm_dates_2026));

tpm_dates_return = qq(2027,1):endfcast;
tpm_target_return = h.TPM(tpm_dates_return);

tpm_dates  = [tpm_dates_2026, tpm_dates_return];
tpm_target = [tpm_target_2026, tpm_target_return];

tpm_add_values = local_level_to_additive( ...
    h, 'TPM', tpm_dates, tpm_target ...
);

tpm_add_path = local_set_path( ...
    tpm_add_path, altRange, tpm_dates, tpm_add_values ...
);
```

Si se quiere respetar 2026Q1 como dato observado y fijar la TPM solo desde 2026Q2, reemplazar la línea `tpm_dates_2026` por:

```matlab
tpm_dates_2026 = qq(2026,2):qq(2026,4);
```
