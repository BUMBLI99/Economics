# Economics — ExchangeReg

Sitio GitHub Pages de Mauricio Ulloa, centrado en el proyecto **ExchangeReg**: modelos de tipo de cambio, tasas soberanas 10Y y stress macrofinanciero para Chile, Brasil, México, Perú y Colombia.

## Ejecutar todo

Desde la raíz del repo:

```powershell
.\render_exchange_site.ps1
```

Ese comando hace todo el flujo:

1. Ejecuta `modelos/exchange/Exchange_CPI_BIS.Rmd`.
2. Descarga datos BCCh, FRED y BIS.
3. Construye el CPI desde BIS `WS_LONG_CPI` en nivel mensual, base 2010=100.
4. Genera el PDF del reporte.
5. Genera gráficos en `modelos/exchange/Graficos/`.
6. Copia los outputs a `assets/`.
7. Renderiza el sitio Quarto hacia `docs/`.
8. Elimina de `docs/proyectos/` las páginas públicas antiguas que no deben verse.

Luego subir a GitHub:

```powershell
git status
git add .
git commit -m "Publish ExchangeReg with BIS CPI"
git push
```

## Credenciales locales

Copia `.Renviron.example` como `.Renviron` y completa:

```text
BCCH_USER=tu_usuario_bcch
BCCH_PASS=tu_password_bcch
FRED_API_KEY=tu_api_key_fred
```

No subas `.Renviron` a GitHub.

## Archivos importantes

```text
modelos/exchange/Exchange_CPI_BIS.Rmd      # modelo principal corregido
proyectos/exchange.qmd                     # página web del proyecto
render_exchange_site.ps1                   # pipeline único
assets/img/exchange/                       # gráficos publicados
assets/files/exchange_report.pdf           # PDF publicado
docs/                                      # carpeta que publica GitHub Pages
```

## Nota sobre el CPI

El modelo ya no reconstruye índices de precios desde variaciones mensuales o 12 meses. Usa directamente los índices mensuales de BIS `WS_LONG_CPI`:

```text
M.CL.628  Chile
M.US.628  United States
M.BR.628  Brazil
M.CO.628  Colombia
M.MX.628  Mexico
M.PE.628  Peru
```

Luego convierte esos niveles mensuales a frecuencia diaria mediante interpolación log-lineal y arrastre plano del último dato disponible. Esto evita el patrón artificial de serrucho.
