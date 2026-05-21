# Economics

Sitio personal y portafolio técnico de economía aplicada, macroeconomía, política monetaria y econometría.

Construido con Quarto y publicado en GitHub Pages desde la carpeta `docs/`.

## Estructura principal

- `index.qmd`: página principal.
- `proyectos.qmd`: resumen curado de proyectos principales y prototipos.
- `proyectos/`: páginas individuales de proyectos.
- `R/`: funciones reutilizables para gráficos, datos y tablas.
- `scripts/`: scripts de actualización y render.
- `matlab/ipom/`: motor Matlab/IRIS del proyecto de escenarios tipo IPoM.
- `data/processed/`: bases limpias usadas por las páginas Quarto.
- `assets/css/styles.css`: estilo visual del sitio.
- `assets/img/og/portfolio-og.png`: imagen Open Graph para LinkedIn y redes.
- `docs/`: sitio renderizado que publica GitHub Pages.

## Proyectos principales

- Nowcasting de actividad económica en Chile.
- Escenarios macroeconómicos inspirados en IPoM con Matlab/IRIS.
- Transmisión de la TPM a tasas de mercado.
- Índice de estrés financiero de mercado para Chile.

## Prototipos en desarrollo

- Curva de rendimiento chilena interactiva.

## Render general

```bash
quarto render
```

## Publicación en GitHub Pages

Configurar GitHub Pages desde `main / docs`. El archivo `_quarto.yml` restringe explícitamente el render público a las páginas del portafolio para evitar publicar documentos internos, notas de instalación o archivos de hotfix.

## Open Graph / LinkedIn

La portada usa `assets/img/og/portfolio-og.png` como imagen Open Graph. Después de publicar cambios en GitHub Pages, conviene actualizar la vista previa con LinkedIn Post Inspector para limpiar el caché del link.

## Actualizar proyecto IPoM / IRIS

Si ya tienes nuevos outputs `fcast_*.csv` exportados desde Matlab/IRIS en `matlab/ipom/outputs/`, ejecuta:

```bash
Rscript scripts/03_build_ipom_outputs.R
quarto render
```

En Windows, si quieres partir desde Matlab:

```powershell
.\scripts_run_ipom_matlab.ps1
Rscript scripts/03_build_ipom_outputs.R
quarto render
```

## Seguridad

No guardar claves, usuarios, contraseñas ni archivos brutos privados en el repositorio. Usa `.Renviron` local y deja solo `.Renviron.example` como plantilla pública. Archivos como `.Renviron`, `.RData`, `.Rhistory`, `.quarto/`, `_freeze/` y temporales de Matlab no deben subirse.
