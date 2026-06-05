# ExchangeReg integrado como dashboard Quarto/Plotly

Este patch corrige la integración del proyecto ExchangeReg para que la página no use capturas ni imágenes estáticas del PDF.

Cambios principales:

- `proyectos/exchange.qmd` ahora construye gráficos interactivos directamente desde `data/processed/exchange/*.csv`.
- Se elimina de la página la sección pública sobre la corrección del IPC.
- Se elimina la sección de reproducibilidad.
- Se agregan ecuaciones conceptuales del modelo FX, del modelo 10Y, de la normalización y de la segunda etapa.
- Se agregan tablas de ajuste, coeficientes traducidos a nombres económicos y segunda etapa.
- El selector por país ahora usa pestañas nativas de Quarto, que son más robustas que HTML/JS manual.
- `scripts/exchange/build_exchange_outputs.R` deja de generar imágenes estáticas por defecto. Su salida principal son CSVs para la web.

## Flujo recomendado

Desde la raíz del repo:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
Expand-Archive "C:\Users\mullo\Downloads\Economics_EXCHANGE_INTERACTIVE_NO_PDF_IMAGES.zip" -DestinationPath . -Force
.\render_exchange_site.bat

git status
git add .
git commit -m "Integrate ExchangeReg with interactive web charts"
git push
```

Importante: esta versión necesita correr el modelo al menos una vez para generar:

```text
data/processed/exchange/residuals_long.csv
data/processed/exchange/second_stage_data.csv
data/processed/exchange/model_fit_summary.csv
data/processed/exchange/model_coefficients.csv
data/processed/exchange/second_stage_summary.csv
```

Si corres `-NoModel` sin que esos CSV existan, la página renderiza, pero mostrará tarjetas indicando que faltan datos. Eso es intencional: no vuelve a usar capturas del PDF como fallback.

## Imágenes estáticas

Las imágenes antiguas pueden seguir existiendo en el repo, pero esta página ya no las referencia. El script solo vuelve a generarlas si defines:

```powershell
$env:EXCHANGE_WRITE_STATIC_PNG="TRUE"
.\render_exchange_site.bat
```

Por defecto no se generan.
