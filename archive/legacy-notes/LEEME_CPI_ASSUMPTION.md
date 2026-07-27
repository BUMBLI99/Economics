# Patch ExchangeReg: supuesto para IPC no publicado

Este patch cambia solo la forma en que se extiende el IPC mensual cuando BIS aún no tiene publicado el último mes necesario para la muestra diaria.

Cambios:
- `scripts/exchange/build_exchange_outputs.R`: extiende cada IPC con una inflación mensual igual al promedio de las últimas 6 variaciones mensuales observadas del país.
- Genera `data/processed/exchange/cpi_extension_summary.csv` con el supuesto aplicado por país.
- `proyectos/exchange.qmd`: agrega un recuadro metodológico breve y actualiza la notación del dólar multilateral como `EER_US` en las ecuaciones.
- `modelos/exchange/Exchange_CPI_BIS.Rmd`: actualiza la descripción técnica opcional.
- `assets/css/styles.css`: estilo del recuadro de supuesto.

Uso recomendado:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
Expand-Archive "C:\Users\mullo\Downloads\Economics_EXCHANGE_CPI_ASSUMPTION_PATCH.zip" -DestinationPath . -Force
.\render_exchange_site.bat

git status
git add .
git commit -m "Add CPI extension assumption to ExchangeReg"
git push
```

No uses `-NoModel` para esta actualización, porque el modelo debe regenerar los CSV con el supuesto nuevo.
