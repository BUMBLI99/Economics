# Economics · Portafolio de economía aplicada

Repositorio y sitio público de **Mauricio Andrés Ulloa Valdivia**. Reúne proyectos de seguimiento macroeconómico, política monetaria, actividad, tasas de interés y macrofinanzas para Chile y América Latina.

**Sitio público:** https://mulloav3007.github.io/Economics/

> Este es un portafolio personal. Los análisis y opiniones no representan posiciones institucionales.

## Proyectos publicados

| Proyecto | Pregunta principal | Pipeline |
|---|---|---|
| Nowcasting IMACEC | ¿Cómo evoluciona la señal para el IMACEC total y no minero desde la EEE hasta los cortes M4/M8P y el dato efectivo? | R |
| Escenarios tipo IPoM | ¿Cómo cambian inflación, TPM y brecha bajo trayectorias condicionales? | Matlab · IRIS · R |
| Transmisión de la TPM | ¿Con qué velocidad y heterogeneidad se transmite la TPM a tasas bancarias? | R |
| FX, tasas 10Y y riesgo LatAm | ¿Qué parte de los movimientos financieros excede lo explicado por factores globales? | R |
| Estrés financiero Chile | ¿Cómo resumir presiones anómalas en USD/CLP y tasa soberana 10Y? | R |
| Curva soberana chilena | ¿Qué muestran nivel, pendiente y compensación inflacionaria de BCP y BCU? | R |

## Arquitectura

El repositorio separa explícitamente cuatro capas:

```text
R/ y matlab/       código analítico
scripts/           actualización, construcción y validación
site/              fuente editorial y visual del sitio
 data/processed/   salidas estables consumidas por la publicación
outputs/           tablas y objetos derivados de los modelos
docs/              sitio estático final que publica GitHub Pages
archive/           material histórico fuera del flujo activo
```

La página pública **no ejecuta R ni Matlab al abrirse**. Consume salidas procesadas y validadas. Así, una descarga fallida o una dependencia local no rompe el sitio ya publicado.

## Construir el sitio

Requiere Python 3.11 o superior.

```bash
python -m pip install -r requirements-site.txt
python scripts/build_site.py
python scripts/validate_site.py
```

En Windows también se puede usar:

```powershell
.\build_site.ps1 -Install
```

El constructor:

1. regenera gráficos web desde los CSV procesados;
2. genera un CV público sin dirección, teléfono ni fecha de nacimiento;
3. limpia completamente `docs/`;
4. construye todas las páginas con diseño común;
5. copia solo las descargas públicas autorizadas;
6. mantiene una redirección para la antigua URL `estres-externo.html`.

## Actualizar análisis

Las credenciales se mantienen exclusivamente en un archivo local `.Renviron`. Copia `.Renviron.example` como `.Renviron` y completa las variables necesarias.

### IMACEC

La publicación usa exclusivamente **M4 · Dinámico** para el corte experimental y
**M8P · INE + IVS real parsimonioso** para el corte INE, estimados por separado
para IMACEC total y no minero. La EEE fechada en `M` se conserva con su fecha de
encuesta y se compara con el IMACEC de `M-1`. Antes de M4 se publica solamente
un AR(1) provisional; al aparecer el dato efectivo, el archivo de vintages permite
comparar EEE, M4 y M8P sin reestimarlos retrospectivamente.

Además de `BCCH_USER` y `BCCH_PASS`, deja el Excel histórico IVS oficial en
`data/raw/series_mensuales_desde_enero_2018_a_la_fecha.xls`, o define
`IMACEC_IVS_URL`. El pipeline usa por defecto el enlace público oficial del INE
compartido para esta serie y acepta tanto `.xls` como `.xlsx`. En GitHub, las
credenciales deben ser Repository Secrets; `IMACEC_IVS_URL` puede usarse como
Repository Variable para reemplazar la URL si el INE la cambia.

```bash
Rscript scripts/01_update_imacec.R
python scripts/build_site.py
python scripts/validate_site.py
```

### IPoM / IRIS

En Matlab, desde `matlab/ipom/`:

```matlab
run_tpm45_2026
```

Luego, desde la raíz:

```bash
Rscript scripts/03_build_ipom_outputs.R
python scripts/build_site.py
python scripts/validate_site.py
```

### Transmisión TPM

```bash
Rscript scripts/05_update_transmision_tpm.R
python scripts/build_site.py
python scripts/validate_site.py
```

### Estrés financiero Chile

```bash
Rscript scripts/06_update_estres_financiero.R
python scripts/build_site.py
python scripts/validate_site.py
```

### Exchange LatAm

```bash
Rscript scripts/exchange/build_exchange_outputs.R
python scripts/build_site.py
python scripts/validate_site.py
```

Para una actualización integrada en Windows existe `scripts/07_update_portfolio_public.ps1`.

## Publicación

El workflow `.github/workflows/pages.yml` construye, valida y despliega `docs/` en cada `push` a `main`. La primera vez se debe seleccionar **GitHub Actions** como fuente en `Settings → Pages`.

Las instrucciones exactas están en [DEPLOY.md](DEPLOY.md).

## Controles de calidad

`scripts/validate_site.py` comprueba:

- páginas esperadas;
- enlaces y recursos internos;
- IDs y anclas duplicadas;
- imágenes sin texto alternativo;
- marcadores de plantilla sin resolver;
- filtración accidental de código fuente a `docs/`.

## Estado de la reconstrucción

La reorganización conserva los pipelines analíticos y sus salidas, reemplaza la antigua capa pública Quarto por un constructor estático determinista y archiva los hotfixes anteriores. La revisión estructural no equivale a reestimar todos los modelos: las corridas de R, Matlab e IRIS requieren sus dependencias y credenciales locales.
