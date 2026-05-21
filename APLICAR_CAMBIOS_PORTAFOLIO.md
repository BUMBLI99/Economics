# Aplicar cambios al portafolio

Este paquete incorpora una limpieza del sitio público, una configuración Open Graph para mejorar la vista previa en LinkedIn y mejoras metodológicas visibles en los proyectos principales.

## Qué cambia

- `project.render` en `_quarto.yml` ahora restringe el sitio público a las páginas del portafolio.
- Se activan `open-graph` y `twitter-card` en Quarto.
- Se agrega `assets/img/og/portfolio-og.png` como miniatura profesional para LinkedIn.
- La página de proyectos queda separada entre proyectos principales y prototipos en desarrollo.
- La curva de rendimiento queda explícitamente clasificada como prototipo visual/en desarrollo.
- El proyecto IMACEC agrega evaluación pseudo out-of-sample y benchmarks simples: AR(1), promedio móvil 3m y naive estacional t-12.
- El proyecto de transmisión TPM agrega una tabla ejecutiva de pass-through para tasas clave y refuerza cautelas metodológicas.
- El proyecto de estrés financiero explicita el riesgo de look-ahead bias y agrega un pipeline para residuos pseudo out-of-sample con ventana expansiva.
- El proyecto IPoM/IRIS usa un lenguaje público más prudente: "escenario de referencia" en lugar de sugerir una réplica oficial.
- Se corrigen chips/tags visuales de la portada.
- Se refuerza `.gitignore` para no subir archivos locales, cachés ni credenciales.
- Se eliminaron del `docs/` incluido los HTML internos tipo `LEEME`, `HOTFIX`, `INSTRUCCIONES` y `README_*`.

## Pasos recomendados

Después de descomprimir el ZIP encima de tu repositorio, primero limpia las páginas internas antiguas que podrían seguir en `docs/` si existían antes. En Windows:

```bat
scripts\00_clean_public_docs.bat
```

En macOS/Linux/Git Bash:

```bash
bash scripts/00_clean_public_docs.sh
```

Luego, desde la raíz del repositorio, actualiza los outputs que ahora alimentan las nuevas secciones:

```bash
Rscript scripts/01_update_imacec.R
Rscript -e "source('scripts/06_update_estres_financiero.R')"
Rscript scripts/03_build_ipom_outputs.R
```

Notas:

- `scripts/01_update_imacec.R` ahora exporta `data/processed/imacec_oos_metrics.csv`.
- `scripts/06_update_estres_financiero.R` ahora intenta generar `data/processed/estres_financiero/stress_index_chile_oos.csv`.
- `scripts/03_build_ipom_outputs.R` solo es necesario si ya tienes actualizados los CSV exportados desde Matlab/IRIS.

Después renderiza el sitio:

```bash
quarto render
```

Después:

```bash
git status
git add .
git commit -m "Mejora portafolio, Open Graph y evaluación metodológica"
git push
```

## LinkedIn

Después de que GitHub Pages actualice el sitio, abre LinkedIn Post Inspector y pega:

```text
https://mulloav3007.github.io/Economics/
```

Eso fuerza a LinkedIn a refrescar la miniatura cacheada.

## Nota

Este ZIP no incluye `.git/`, `.Renviron`, `.RData`, `.Rhistory`, `.quarto/` ni `_freeze/` para evitar subir archivos locales o sensibles.
