# Ajuste de redacción pública

Este paquete reduce menciones visibles a Quarto en las páginas públicas del portafolio.

Cambios principales:

- Portada: se elimina Quarto de la lista de herramientas destacadas.
- Página de proyectos: se eliminan menciones a Quarto en las tarjetas de herramientas.
- Proyecto IPoM/IRIS: `Publicación Quarto` pasa a `Presentación de resultados`; la redacción se concentra en el modelo, el procesamiento y la presentación de resultados.
- Se mantiene la estructura técnica interna del sitio, pero se evita mencionar la herramienta de publicación dentro de la narrativa pública de los proyectos.

Aplicación recomendada:

```powershell
quarto render
git add .
git commit -m "Ajusta redaccion publica y elimina menciones innecesarias a Quarto"
git push
```
