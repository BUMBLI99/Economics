# Outputs del subproyecto IPoM

## `raw_iris/`

CSV crudos generados por Matlab/IRIS, por ejemplo:

```text
fcast_ipom_exact.csv
fcast_ipom_with_shocks.csv
fcast_alt_escenario.csv
fcast_alt_iran_fin_anticipado.csv
fcast_alt_riskoff.csv
fcast_base_model.csv
```

Estos archivos todavía están en formato ancho tipo IRIS.

## `quarto/`

Copia espejo de los CSV limpios creados por R en `data/processed/ipom/`. Esta carpeta existe solo para que el subproyecto IPoM tenga reunidos todos los archivos útiles.

La fuente que lee Quarto sigue siendo:

```text
data/processed/ipom/
```
