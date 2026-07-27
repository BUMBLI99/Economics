# Instalación del parche: estrés financiero Chile

Este ZIP contiene solo archivos nuevos o modificados. Para aplicarlo:

1. Descomprime el ZIP dentro de la raíz de tu repositorio `Economics`.
2. Acepta reemplazar `proyectos.qmd` y `proyectos/estres-externo.qmd`.
3. En RStudio, desde la raíz del repositorio, ejecuta:

```r
source("scripts/06_update_estres_financiero.R")
```

4. Renderiza el sitio:

```bash
quarto render
```

5. Sube los cambios a GitHub:

```bash
git add .
git commit -m "Agrega índice de estrés financiero para Chile"
git push
```

## Qué cambia

- La página `proyectos/estres-externo.qmd` deja de usar datos simulados.
- El proyecto pasa a llamarse `Índice de estrés financiero de mercado para Chile`.
- Se agregan scripts R completos y separados en `R/estres_financiero/`.
- Se agregan datos procesados y gráficos estáticos ya generados.
- No se incluyen credenciales ni claves API.

## Dependencias R

El pipeline requiere:

```r
install.packages(c(
  "readr", "dplyr", "tidyr", "ggplot2", "zoo", "scales",
  "broom", "purrr", "stringr", "tibble", "rlang", "plotly", "knitr"
))
```

`readxl` solo es necesario si quieres volver a importar manualmente el Excel original de `ExchangeReg`.
