# Hotfix: ajuste de gráficos del proyecto de estrés financiero

Este parche corrige el problema de gráficos "apretados" y textos/leyendas solapadas.

## Archivos a reemplazar

- `proyectos/estres-externo.qmd`
- `R/estres_financiero/00_setup.R`
- `R/estres_financiero/03_plots.R`

## Qué cambia

1. **Más espacio vertical** en los gráficos interactivos (`fig-height` mayor).
2. **Leyendas movidas abajo** para que no se superpongan con el título.
3. **Márgenes de Plotly más amplios**.
4. **Tema ggplot más holgado** para mejorar títulos, subtítulos y leyendas.
5. **PNGs exportados más grandes** cuando corras el pipeline.

## Cómo aplicarlo

Descomprime este ZIP en la raíz del repo `Economics` y acepta reemplazar archivos.

Luego, para regenerar datos y PNG:

```r
source("scripts/06_update_estres_financiero.R")
```

Y finalmente renderiza el sitio:

```bash
quarto render
```
