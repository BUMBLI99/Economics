# Ajuste final ExchangeReg

Este patch corrige tres puntos:

1. Los gráficos Plotly quedan contenidos dentro de sus recuadros y centrados en la página.
2. El panel de TPM/tasa 10Y/desvíos se rehace como Plotly nativo de dos paneles, no como `ggplotly` facetado.
3. El pipeline ya no extiende series financieras indefinidamente si una fuente deja de entregar datos recientes. Las interpolaciones solo cubren huecos cortos; si faltan observaciones recientes, el modelo y los gráficos terminan en la última fecha con datos comunes disponibles.

Aplicar desde la raíz del repo:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
Expand-Archive "C:\Users\mullo\Downloads\Economics_EXCHANGE_FIX_LAYOUT_DATOS.zip" -DestinationPath . -Force
.\render_exchange_site.bat

git status
git add .
git commit -m "Fix ExchangeReg chart layout and data endpoints"
git push
```

No usar `-NoModel` en esta pasada, porque hay que regenerar los CSV con la regla nueva de corte de muestra.
