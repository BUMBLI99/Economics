# ExchangeReg integrado profesionalmente en el sitio

Este patch reemplaza la integración tipo “pantallazos del PDF” por una página Quarto estructurada como proyecto del portafolio.

## Qué cambia

- `proyectos/exchange.qmd` queda reescrito como página de proyecto, con metodología, dashboard, tablas y selector por país.
- `scripts/exchange/build_exchange_outputs.R` genera los outputs web directamente: CSVs + gráficos desde los modelos, sin depender de renderizar un PDF.
- `render_exchange_site.ps1` queda corregido y simplificado.
- `render_exchange_site.bat` permite ejecutar sin pelear con la política de scripts de PowerShell.
- `assets/css/styles.css` agrega estilos para selector, paneles por país y layout profesional.
- `data/processed/exchange/` queda preparado para las tablas del sitio; al correr el modelo se sobreescribe con datos actualizados.

## Cómo aplicarlo

Desde la raíz del repo `Economics`:

```powershell
Expand-Archive "C:\Users\mullo\Downloads\Economics_EXCHANGE_INTEGRADO_PRO.zip" -DestinationPath . -Force
```

## Cómo renderizar todo

```powershell
.\render_exchange_site.bat
```

Ese comando recalcula el modelo, genera outputs y renderiza Quarto.

## Renderizar solo la página

Si quieres actualizar solo el HTML usando los outputs ya existentes:

```powershell
.\render_exchange_site.bat -NoModel
```

## Después

```powershell
git status
git add .
git commit -m "Improve ExchangeReg project integration"
git push
```

## Credenciales

El modelo usa `.Renviron` local, no versionado:

```text
BCCH_USER=...
BCCH_PASS=...
FRED_API_KEY=...
```

El CPI usa BIS `WS_LONG_CPI` en nivel mensual, base 2010=100, y se interpola log-linealmente a diario.
