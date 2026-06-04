# ExchangeReg en el sitio Economics

El flujo queda integrado dentro del repo `Economics`. No hace falta mantener una carpeta externa `ExchangeReg`.

## Ejecución normal

Desde la raíz del repo:

```powershell
.\render_exchange_site.bat
```

Ese comando ejecuta PowerShell con `ExecutionPolicy Bypass` solo para esta corrida y hace cuatro cosas:

1. descarga datos y estima los modelos con `scripts/exchange/build_exchange_outputs.R`;
2. genera CSVs en `data/processed/exchange/`;
3. genera gráficos web en `assets/img/exchange/`;
4. renderiza el sitio Quarto en `docs/` y oculta la página pública vieja `estres-externo`.

## Render sin recalcular modelo

Cuando solo quieras volver a construir la página usando outputs ya existentes:

```powershell
.\render_exchange_site.bat -NoModel
```

## Credenciales

Copia `.Renviron.example` como `.Renviron` y completa:

```text
BCCH_USER=tu_usuario
BCCH_PASS=tu_clave
FRED_API_KEY=tu_api_key
```

`.Renviron` está en `.gitignore`; no debe subirse a GitHub.

## CPI

La inflación relativa usa índices BIS `WS_LONG_CPI` en nivel mensual, base 2010=100:

- `M.CL.628`: Chile
- `M.US.628`: Estados Unidos
- `M.BR.628`: Brasil
- `M.CO.628`: Colombia
- `M.MX.628`: México
- `M.PE.628`: Perú

El índice mensual se transforma a frecuencia diaria por interpolación log-lineal y se mantiene plano después del último dato observado. No se reconstruye un CPI desde variaciones mensuales/interanuales.
