# Modelo ExchangeReg

El modelo principal es:

```text
Exchange_CPI_BIS.Rmd
```

Se ejecuta desde la raíz del repo con:

```powershell
.\render_exchange_site.ps1
```

No hace falta mantener una carpeta externa `ExchangeReg`. Este repo queda autocontenido: el modelo, la página web, los gráficos y el PDF viven dentro de `Economics`.

## CPI

La inflación relativa se construye usando índices de precios al consumidor de BIS `WS_LONG_CPI`, no variaciones mensuales del BCCh transformadas artificialmente a frecuencia diaria.
