# Exchange LatAm

Modelos diarios de tipo de cambio, tasas soberanas a 10 años y riesgo para Chile, Brasil, México, Perú y Colombia.

## Pipeline activo

Desde la raíz del repositorio:

```bash
Rscript scripts/exchange/build_exchange_outputs.R
```

El script:

1. descarga y alinea series BCCh, FRED y BIS;
2. construye inflación relativa desde índices BIS en nivel;
3. estima los bloques FX y 10Y por país;
4. normaliza residuos para comparación regional;
5. estima la asociación de segunda etapa con spreads soberanos;
6. exporta CSV, gráficos analíticos y un libro de salidas.

## Credenciales

Copia `.Renviron.example` como `.Renviron` y completa:

```text
BCCH_USER=...
BCCH_PASS=...
FRED_API_KEY=...
```

## Salidas

```text
data/processed/exchange/       bases y diagnósticos consolidados
assets/img/exchange/           gráficos del pipeline R
assets/files/                  reportes y libro de resultados
```

La página pública usa una capa gráfica estandarizada generada por Python desde esos CSV. Después de actualizar el modelo:

```bash
python scripts/build_site.py
python scripts/validate_site.py
```

## Nota metodológica

Los residuos representan movimientos no explicados por la especificación observada; no son una medida estructural pura ni prueban causalidad. Los z-scores permiten comparar intensidad relativa entre mercados, pero no eliminan diferencias institucionales o de liquidez.
