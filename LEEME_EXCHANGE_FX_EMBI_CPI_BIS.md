# Patch ExchangeReg: FX + 10Y + EMBIG + CPI BIS

Este patch reemplaza la integración anterior del proyecto ExchangeReg por la versión correcta basada en `Exchange_final_corregido_FX_EMBI_v2.Rmd`.

Cambios principales:

- El modelo FX incorpora: precios relativos, WTI, cobre, índice oro/plata, Nasdaq, equity China, VIX, dólar multilateral BIS, CNY/USD y Treasury 10Y.
- El modelo 10Y incorpora: Treasury 10Y, EMBIG país / 100 pbs, VIX, Nasdaq, dólar multilateral BIS, CNY/USD y tendencia.
- La segunda etapa se mantiene como residuo FX vs spread 10Y frente a EE.UU.
- El IPC se obtiene desde BIS `WS_LONG_CPI` en nivel mensual.
- Si falta el último mes de IPC, se extiende con el promedio de las últimas 6 variaciones mensuales observadas por país.
- La página Quarto usa gráficos interactivos desde CSV, no imágenes del PDF.

Aplicar desde la raíz del repo:

```powershell
Expand-Archive "C:\Users\mullo\Downloads\Economics_EXCHANGE_FX_EMBI_CPI_BIS_CORRECT.zip" -DestinationPath . -Force
.ender_exchange_site.bat

git status
git add .
git commit -m "Replace ExchangeReg with FX EMBI model and BIS CPI"
git push
```

No uses `-NoModel` la primera vez: es necesario regenerar los CSV con la especificación correcta.
