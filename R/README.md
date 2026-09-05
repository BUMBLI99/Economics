# Código R

Esta carpeta contiene módulos analíticos; no contiene la fuente del sitio público.

## Proyectos

- `imacec_*.R`: descarga, calendario, modelos, vintages, evaluación pseudo out-of-sample y exportación del nowcast.
- `transmision_tpm/`: panel mensual, rezagos distribuidos, asimetrías y local projections.
- `sostenibilidad_deuda/`: fuentes fiscales, conciliación contable, dinámica de deuda y sensibilidades.
- `ipom_*.R`: lectura y normalización de salidas Matlab/IRIS.

## Convención de salidas

Los scripts escriben bases consolidadas en `data/processed/`, tablas en `outputs/tables/` y figuras analíticas de respaldo en `assets/img/`. El sitio consume esas salidas mediante `scripts/build_site.py`.

## Raíz y credenciales

Los módulos deben resolver rutas desde el repositorio, no desde una ruta absoluta del computador. Las credenciales se leen desde `.Renviron`, que está ignorado por Git.

```text
BCCH_USER=...
BCCH_PASS=...
FRED_API_KEY=...
```

## Publicación después de una actualización

```bash
python scripts/build_site.py
python scripts/validate_site.py
```

No edites `docs/` manualmente: es un artefacto generado.
