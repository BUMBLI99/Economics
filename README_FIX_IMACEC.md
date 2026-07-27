# Corrección IMACEC: recuperación y lógica de fuente activa

Este parche corrige el problema de publicación del proyecto IMACEC.

## Cambios principales

1. **No se publica el modelo INE si el mes objetivo no tiene indicadores sectoriales INE efectivos.**
   El modelo INE puede estimarse históricamente, pero solo queda como fuente activa si `mineria`, `manufactura`, `comercio` y `electricidad` existen para el mes objetivo.

2. **Se incorpora EEE como fuente temprana.**
   Si aún no existen indicadores sectoriales INE para el mes objetivo y la EEE pública tiene el dato de "IMACEC un mes atrás", el nowcast activo pasa a ser la EEE.

3. **Se mantiene el modelo con estadísticas experimentales.**
   No se elimina. Queda como modelo de comparación y posible fuente activa si tiene información contemporánea suficiente y no hay EEE.

4. **Se corrige el bloque visual de resultado principal.**
   Se elimina el callout mal cerrado y se deja una ficha simple con mes proyectado, fuente/modelo activo y fecha de actualización.

5. **Se elimina la sección pública "Código".**
   La página ya no termina con una sección innecesaria de scripts.

6. **Se desactiva `code-tools` en Quarto.**
   Evita el botón/sección de código en la página pública.

7. **Se mejora el zoom de los gráficos.**
   El eje Y usa marcas cada 5 puntos y se reajusta al zoom horizontal. El zoom horizontal queda limitado al rango mostrado.

## Archivos reemplazados

- `_quarto.yml`
- `R/00_packages.R`
- `R/imacec_config.R`
- `R/imacec_data.R`
- `R/imacec_models.R`
- `R/imacec_outputs.R`
- `scripts/01_update_imacec.R`
- `proyectos/imacec.qmd`

## Ejecución

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"

& "C:\Program Files\R\R-4.3.2\bin\x64\Rscript.exe" "scripts\01_update_imacec.R"
quarto render --execute

git add .
git commit -m "Corrige lógica de publicación IMACEC"
git push
```

Luego revisar:

```text
https://mulloav3007.github.io/Economics/proyectos/imacec.html?v=500
```
