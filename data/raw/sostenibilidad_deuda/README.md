# Insumos de sostenibilidad de la deuda

Este directorio reemplaza el libro de trabajo por insumos abiertos en CSV
(UTF-8, coma como separador y punto decimal). Los valores son los resultados
calculados del libro revisado; no se publican fórmulas ni un binario XLSX.

## Cobertura y naturaleza

- `deuda_historica.csv`: deuda bruta del Gobierno Central, 1990–2025.
- `macro_ifp.csv`: escenario macroeconómico oficial, 2025–2030.
- `deuda_oficial.csv`: sendas de deuda comprometida y compatible, 2025–2030.
- `balance_ifp.csv`: balances, intereses y holguras, 2026–2030.
- `financiamiento_ifp.csv`: necesidades y fuentes de financiamiento, 2026–2030.
- `supuestos_2031_2035.csv`: extensión ilustrativa propia; no es proyección institucional.
- `escenarios.csv`: definición transparente de shocks determinísticos.
- `diccionario_campos.csv`: significado, unidad y naturaleza de cada variable.

Los datos oficiales provienen del Informe de Finanzas Públicas del segundo
trimestre de 2026 (IFP 2T26) de Dipres y de la Oficina de la Deuda Pública del
Ministerio de Hacienda. Fecha de corte del ejercicio: 29 de julio de 2026.

Fuentes principales:

- https://www.dipres.gob.cl/598/articles-419241_Informe_PDF.pdf
- https://www.dipres.gob.cl/598/articles-419241_Version_Excel.xlsx
- https://www.hacienda.cl/areas-de-trabajo/finanzas-internacionales/oficina-de-la-deuda-publica/datos-de-la-deuda-publica-de-chile

## Convenciones

- Las proporciones se almacenan como fracciones: `0.45` equivale a 45% del PIB.
- Los montos `mm_clp` están en millones de pesos chilenos corrientes.
- Un balance primario positivo representa superávit.
- `sfa` significa ajuste stock-flujo; sus componentes positivos aumentan deuda.
- Las celdas sin dato se representan vacías y se leen como `NA`.
- Los valores 2031–2035 y los shocks son supuestos editables del autor.

La reproducción se ejecuta con `Rscript scripts/06_update_sostenibilidad_deuda.R`.
