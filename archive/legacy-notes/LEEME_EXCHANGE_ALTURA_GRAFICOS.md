# Ajuste de altura para gráficos ExchangeReg

Este patch aumenta la altura del panel **TPM, tasa 10Y y desvíos del modelo** y evita que el gráfico quede cortado dentro de las pestañas.

Aplicar desde la raíz del repo:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
Expand-Archive "C:\Users\mullo\Downloads\Economics_EXCHANGE_ALTURA_GRAFICOS.zip" -DestinationPath . -Force
.\render_exchange_site.bat -NoModel

git status
git add .
git commit -m "Increase ExchangeReg policy dashboard height"
git push
```

No es necesario recalcular el modelo, porque este patch solo cambia presentación de la página.
