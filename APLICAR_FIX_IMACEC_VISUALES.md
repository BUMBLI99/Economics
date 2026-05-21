# Cambios incluidos en este ZIP

Este paquete aplica tres mejoras principales al portafolio:

1. **IMACEC:** reemplaza la lectura frágil `rjson::fromJSON(file = url)` por una descarga robusta `httr + jsonlite + iconv`, para evitar el error `input string 1 is invalid UTF-8` cuando la API del Banco Central retorna bytes con encoding problemático.
2. **IPoM/IRIS:** deja la versión pública con solo dos escenarios: `Escenario base basado en IPoM` y `Escenario alternativo`. Ya no declara escenarios que no tienes generados en `raw_iris`.
3. **Visuales:** agrega miniaturas visuales a las tarjetas de proyectos, mejora hover de cards, contenedores de gráficos Plotly y presentación de tablas/callouts.

## Ejecutar en Windows

Desde la raíz del repo `Economics`, puedes usar el script automático:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\07_update_portfolio_public.ps1
```

Si prefieres hacerlo manual:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"

$RSCRIPT = Get-ChildItem "C:\Program Files\R" -Recurse -Filter Rscript.exe |
  Sort-Object FullName -Descending |
  Select-Object -First 1 -ExpandProperty FullName

& scripts\00_clean_public_docs.bat
& $RSCRIPT scripts/01_update_imacec.R
& $RSCRIPT -e "source('scripts/06_update_estres_financiero.R')"
& $RSCRIPT scripts/03_build_ipom_outputs.R
quarto render

git status
git add .
git commit -m "Corrige descarga IMACEC y mejora visuales del portafolio"
git push
```

## Nota

Si `scripts/03_build_ipom_outputs.R` avisa que falta algún CSV, revisa que existan estos archivos en `matlab/ipom/outputs/raw_iris/`:

- `fcast_ipom_exact.csv`
- `fcast_alt_escenario.csv`

La versión pública ya no espera los escenarios `riskoff`, `iran_fin_anticipado` ni `base_model`.
