# Aplicar cambios al portafolio

Este paquete incorpora una limpieza del sitio público y una configuración Open Graph para mejorar la vista previa en LinkedIn.

## Qué cambia

- `project.render` en `_quarto.yml` ahora restringe el sitio público a las páginas del portafolio.
- Se activan `open-graph` y `twitter-card` en Quarto.
- Se agrega `assets/img/og/portfolio-og.png` como miniatura profesional para LinkedIn.
- La página de proyectos queda separada entre proyectos principales y prototipos en desarrollo.
- La curva de rendimiento queda explícitamente clasificada como prototipo visual.
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

Luego, desde la raíz del repositorio, si tienes Quarto y R configurados:

```bash
quarto render
```

Después:

```bash
git status
git add _quarto.yml index.qmd proyectos.qmd proyectos/*.qmd assets/img/og/portfolio-og.png assets/css/styles.css README.md .gitignore docs scripts/00_clean_public_docs.bat scripts/00_clean_public_docs.sh APLICAR_CAMBIOS_PORTAFOLIO.md
git commit -m "Mejora portafolio y Open Graph para LinkedIn"
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
