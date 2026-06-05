# Fix ExchangeReg: integración web profesional

Este patch corrige la página `proyectos/exchange.qmd` para que el proyecto ExchangeReg quede integrado como página Quarto y no como capturas del PDF.

Cambios principales:

- Se elimina la sección explícita de corrección de CPI; el CPI relativo queda incorporado solo dentro de la especificación del modelo.
- Se agregan ecuaciones conceptuales de primera etapa FX, primera etapa 10Y y segunda etapa FX-spread 10Y.
- Se reemplazan los gráficos interactivos mal dimensionados por gráficos estáticos web, panorámicos y consistentes con el resto del portafolio.
- El selector por país ahora se genera desde un chunk R con `results='asis'`, evitando que Quarto escape el HTML como texto.
- Se elimina la sección de reproducibilidad de la página pública.
- El script `scripts/exchange/build_exchange_outputs.R` ahora genera gráficos más panorámicos y un archivo adicional `model_coefficients.csv` para futuras tablas de coeficientes.

Aplicación:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
Expand-Archive "C:\Users\mullo\Downloads\Economics_EXCHANGE_FIX_VISUAL_SELECTOR.zip" -DestinationPath . -Force
.\render_exchange_site.bat -NoModel

git status
git add .
git commit -m "Refine ExchangeReg web integration"
git push
```

Para recalcular modelos y regenerar gráficos nuevos:

```powershell
.\render_exchange_site.bat
```

Si no quieres depender de recalcular datos ahora, `-NoModel` basta para corregir la página con los outputs existentes.
