# Fix: Quarto estaba renderizando Rmd internos

El error:

```text
processing file: Data_IPOM_exploratory.Rmd
lexical error: invalid char in json text. <!DOCTYPE html ...
```

no viene de la página pública del IPoM. Viene de que Quarto estaba recorriendo y ejecutando todos los `.Rmd` del repositorio, incluyendo archivos internos de `matlab/ipom/src/r/archive_exploratory/`.

Ese Rmd llama a la BDE esperando JSON, pero la BDE devolvió HTML. Por eso `jsonlite::fromJSON()` falla.

La corrección es dejar una lista explícita en `_quarto.yml` con las únicas páginas públicas que deben renderizarse.

Después de aplicar este parche:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
quarto render --execute
```

ya no debería procesar:

```text
matlab/ipom/src/r/archive_exploratory/Data_IPOM_exploratory.Rmd
matlab/ipom/src/r/estimaciones_macro_ipom_tablas.Rmd
modelos/exchange/*.Rmd
LEEME*.md
README*.md
```

Para actualizar solo IMACEC:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\08_update_imacec_public.ps1
```

Para reconstruir solo el sitio, sin actualizar datos:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\09_rebuild_public_site.ps1
```
