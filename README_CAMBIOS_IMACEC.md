# Parche IMACEC: evaluación y visualización

Este parche modifica cuatro archivos:

- `R/imacec_models.R`
- `R/imacec_outputs.R`
- `scripts/01_update_imacec.R`
- `proyectos/imacec.qmd`

## Cambios principales

1. La evaluación pseudo out-of-sample parte por defecto en `2022-01-01`.
   Puedes cambiarlo con:

   ```powershell
   $env:IMACEC_EVAL_START_DATE="2022-01-01"
   ```

2. La tabla de evaluación ahora compara por separado:
   - Modelo con estadísticas experimentales
   - Modelo con indicadores sectoriales INE
   - Benchmark AR(1)
   - Promedio móvil 3m
   - Naive estacional t-12

3. El gráfico principal muestra el modelo activo en el subtítulo.

4. Los gráficos son 15% más altos aproximadamente (`height = 575`).

5. El eje Y usa marcas cada 5 puntos porcentuales y se reajusta al hacer zoom horizontal.

## Flujo recomendado

Desde la raíz del repo `Economics`:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"

& "C:\Program Files\R\R-4.3.2\bin\x64\Rscript.exe" "scripts\01_update_imacec.R"

quarto render --execute

git add .
git commit -m "Mejora evaluacion y graficos IMACEC"
git push
```

Luego revisar:

```text
https://mulloav3007.github.io/Economics/proyectos/imacec.html?v=300
```
