# Proyecto: Transmisión de la TPM a tasas de mercado

Este parche integra al sitio Quarto `Economics` un proyecto de investigación en desarrollo sobre pass-through de política monetaria en Chile.

## Qué agrega

- Página Quarto: `proyectos/transmision-tpm.qmd`.
- Pipeline R: `R/transmision_tpm/`.
- Script de actualización: `scripts/05_update_transmision_tpm.R`.
- Datos procesados iniciales: `data/processed/transmision_tpm/`.
- Tablas: `outputs/tables/transmision_tpm/`.
- Figuras de respaldo: `assets/img/transmision_tpm/`.
- Metadatos de descarga: `data/metadata/transmision_tpm/`.

## Cómo actualizar

Desde la raíz del repositorio `Economics`:

```powershell
& "C:\Program Files\R\R-4.3.2\bin\x64\Rscript.exe" "scripts\05_update_transmision_tpm.R"
quarto render --execute
git add .
git commit -m "Actualiza proyecto transmision TPM"
git push
```

## Credenciales

El script requiere la API BDE del BCCh. Debes tener en `.Renviron`:

```text
BCCH_USER=tu_usuario
BCCH_PASS=tu_password
```

No subas `.Renviron` a GitHub.

## Interpretación

La versión actual es un monitor de pass-through dinámico. No debe presentarse como identificación causal plena de shocks monetarios. Para ese salto metodológico se recomienda incorporar sorpresas de política monetaria, expectativas de TPM, microdatos bancarios o una estrategia externa de identificación.
