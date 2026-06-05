# ExchangeReg — ajustes visuales y de presentación

Este patch corrige la integración web del proyecto ExchangeReg sin volver a usar imágenes del PDF.

Cambios principales:

- Los gráficos Plotly de las pestañas por país dejan de quedar cortados.
- Las tarjetas de gráficos evitan el doble contenedor generado por Quarto.
- Las leyendas y márgenes de los gráficos tienen más espacio vertical.
- Las tablas de coeficientes pasan a formato matricial: variables en filas y países en columnas.
- Se eliminan textos de reproducibilidad, notas técnicas sobre CSV/render y frases de desarrollo que no aportaban a la lectura pública.
- Se mantiene la página basada en datos del modelo y gráficos interactivos.

Aplicación rápida:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
Expand-Archive "C:\Users\mullo\Downloads\Economics_EXCHANGE_REFINEMENTS_TABLES_CHARTS.zip" -DestinationPath . -Force
.\render_exchange_site.bat -NoModel
git status
git add .
git commit -m "Refine ExchangeReg charts and coefficient tables"
git push
```

Si quieres recalcular el modelo antes de renderizar:

```powershell
.\render_exchange_site.bat
```
