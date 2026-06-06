# Nota sobre inicialización de brecha 2000-2004

La brecha de producto 2000Q1-2004Q4 queda fijada con los valores legacy.

Motivo: el Rmd usa un HP one-sided como fallback para esos trimestres porque el vector IPoM/BCCh empieza operativo desde 2005Q1. Si la descarga comienza en 1996Q1 y `min_obs = 20`, el HP no produce valores para 2000Q1-2000Q3 y además cambia la trayectoria 2000Q4-2004Q4 por condiciones iniciales. Para evitar que los coeficientes de la IS cambien por una decisión de ventana/warm-up, esos puntos se congelan con la base legacy.

Desde 2005Q1 en adelante se mantiene la serie hardcodeada en el Rmd, y desde 2021Q1 se usan los supuestos de gap definidos para el escenario.
