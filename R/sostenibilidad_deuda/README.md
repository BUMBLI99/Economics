# Sostenibilidad de la deuda pública de Chile

Pipeline modular para reconstruir las sendas del IFP 2T 2026 y realizar ejercicios
condicionales de dinámica de deuda. La capa analítica queda separada de la publicación web.

## Criterios metodológicos

- La identidad usa deuda bruta del Gobierno Central y balance primario con signo positivo para superávit.
- El crecimiento nominal se deriva del PIB nominal publicado; no se aproxima sumando PIB real e IPC.
- Los ajustes stock-flujo y la conciliación de la senda compatible se presentan por separado.
- Los shocks de tasas de mercado pasan gradualmente a la tasa efectiva del stock mediante una fracción
  de refinanciamiento configurable (25% anual como referencia), en vez de trasladarse uno a uno al instante.
- El 45% del PIB se presenta como nivel prudente de la regla dual, no como límite legal rígido.
- Las trayectorias posteriores a 2030 son extensiones ilustrativas propias, no proyecciones oficiales.

Los módulos se ejecutan desde `scripts/06_update_sostenibilidad_deuda.R`.

Los insumos públicos están en `data/raw/sostenibilidad_deuda/` como CSV UTF-8.
El directorio incluye un diccionario de campos y distingue datos oficiales,
cálculos reproducidos y supuestos editables; el libro XLSX de trabajo no se
publica.
