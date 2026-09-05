# Estructura del repositorio

## Flujo activo

```text
Economics/
├─ .github/workflows/pages.yml   construcción y despliegue automático
├─ R/                            código analítico reutilizable
│  ├─ sostenibilidad_deuda/
│  └─ transmision_tpm/
├─ matlab/ipom/                  modelo y escenarios Matlab/IRIS
│  ├─ data/                      entradas del flujo auditado
│  ├─ src/matlab/                modelo y pasos activos
│  ├─ output/                    salidas crudas y reportes
│  └─ archive_legacy/            pipeline anterior fuera del path
├─ modelos/exchange/             documentación y Rmd del modelo regional
├─ scripts/                      actualización, build y validación
├─ data/
│  ├─ raw/                       insumos locales o descargados
│  ├─ processed/                 bases consolidadas consumidas por el sitio
│  └─ metadata/                  diccionarios y logs
├─ outputs/                      tablas y objetos de estimación
├─ assets/                       salidas analíticas originales y descargas fuente
├─ site/
│  ├─ content/                   contenido editorial en Markdown/HTML
│  ├─ data/                      metadatos del portafolio
│  ├─ templates/                 plantillas Jinja
│  └─ assets/                    CSS, JS, gráficos, dashboards y CV público
├─ docs/                         artefacto final de GitHub Pages
└─ archive/                      Quarto, hotfixes y notas históricas
```

## Contratos de cada capa

### Código analítico

`R/`, `matlab/` y `modelos/` pueden descargar, transformar y estimar. No escriben directamente HTML público.

### Datos procesados

`data/processed/` y `outputs/tables/` constituyen el contrato entre los modelos y la publicación. Cada página declara fecha de corte y limitaciones.

### Fuente del sitio

`site/` es la única fuente editorial activa. Los textos de proyectos tienen una estructura común: indicadores, pregunta, resultados, método, interpretación, límites y archivos.

Los exploradores se publican desde JSON liviano en `site/assets/data/` y se renderizan con el único motor de `site/assets/js/site.js`. Los SVG siguen siendo el respaldo estático, accesible y descargable; no se mantienen implementaciones JavaScript separadas por proyecto.

Los paneles autocontenidos de mayor complejidad se guardan en `site/assets/dashboards/` como artefactos web compilados. Su página editorial documenta fuentes y límites, mientras el panel permanece disponible a pantalla completa.

### Artefacto público

`docs/` se elimina y reconstruye por completo. Nunca debe editarse a mano porque esos cambios se perderán en el siguiente build.

### Archivo histórico

`archive/` y `matlab/ipom/archive_legacy/` no participan en builds ni estimaciones. Se conservan para trazabilidad, no como documentación operativa.
