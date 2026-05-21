# Aplicar ajustes técnicos y visuales del portafolio

Este paquete incorpora ajustes en las páginas de proyectos y en el CSS:

- IPoM/IRIS: se elimina el recuadro defensivo de “convención de lectura pública” y se agrega una sección de estructura conceptual con ecuaciones en LaTeX.
- Transmisión TPM: se agrega lectura conceptual del canal monetario, expectativas, riesgo, convergencia parcial y cautelas metodológicas reforzadas.
- Estrés financiero: se agrega una sección explícita para interpretar signo, magnitud, z-scores y umbrales del índice.
- IMACEC: se simplifica la tabla pseudo out-of-sample eliminando la columna larga de nota y agregando la advertencia bajo la tabla.
- CSS: se agregan reglas responsivas para cards, tablas, ecuaciones y sidebar/TOC.

## Ejecución recomendada en PowerShell

Desde tu repositorio real:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"

# Opcional, si usas el script existente del repo:
powershell -ExecutionPolicy Bypass -File scripts\07_update_portfolio_public.ps1

# Si prefieres solo renderizar después de copiar estos cambios:
quarto render

git status
git add .
git commit -m "Mejora contenido conceptual y responsive del portafolio"
git push
```

Si el pipeline IMACEC falla por datos externos, puedes renderizar igualmente con los archivos existentes y luego corregir la descarga. Los cambios principales de esta versión están en `.qmd` y `assets/css/styles.css`.
