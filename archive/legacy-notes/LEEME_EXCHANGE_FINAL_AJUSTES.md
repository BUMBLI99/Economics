# Ajustes finales ExchangeReg

Este patch actualiza la integración web del proyecto ExchangeReg:

- mantiene el modelo FX + 10Y + EMBIG país;
- ajusta los gráficos interactivos para que no queden cortados;
- agrega al final de la página los gráficos de TPM, tasa 10Y y desvíos del modelo por país;
- agrega un botón de descarga del PDF generado por el pipeline;
- elimina de la página pública menciones innecesarias de fuentes/proceso técnico.

Aplicar desde la raíz del repo:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
Expand-Archive "C:\Users\mullo\Downloads\Economics_EXCHANGE_FINAL_AJUSTES_TPM_PDF.zip" -DestinationPath . -Force
.\render_exchange_site.bat

git status
git add .
git commit -m "Finalize ExchangeReg page with TPM dashboards and PDF"
git push
```

No uses `-NoModel` esta vez, porque se genera un CSV nuevo para los gráficos de TPM y el PDF descargable.
