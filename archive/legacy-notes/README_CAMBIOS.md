# Paquete de rediseño para la página GitHub Pages

Este paquete reemplaza la portada y mejora la presentación visual del sitio Quarto.

## Archivos incluidos

- `_quarto.yml`: configuración del sitio, navegación, footer, CSS y opciones de render.
- `index.qmd`: nueva página principal profesional.
- `proyectos.qmd`: nueva página de proyectos con tarjetas sin títulos azules.
- `cv.qmd`: página CV más limpia.
- `contacto.qmd`: página de contacto más limpia.
- `assets/css/styles.css`: tema visual completo del sitio.

## Cómo instalar

1. Descomprime este paquete.
2. Copia los archivos en la raíz del repositorio `Economics`, respetando carpetas.
3. Acepta reemplazar los archivos existentes.
4. En la terminal del proyecto ejecuta:

```bash
quarto render
```

5. Revisa localmente el sitio generado en `docs/index.html`.
6. Si todo se ve bien:

```bash
git add _quarto.yml index.qmd proyectos.qmd cv.qmd contacto.qmd assets/css/styles.css docs/
git commit -m "Rediseña portada y presentación del portafolio"
git push
```

GitHub Pages publicará el contenido desde `docs/`.

## Detalles del rediseño

- Corrige el problema de archivos `.qmd` comprimidos en una sola línea.
- Elimina el botón global de código de Quarto en la portada.
- Sustituye títulos azules subrayados por tarjetas con llamadas a acción sobrias.
- Usa enlaces tipo chip con icono `↗`.
- Mejora jerarquía visual, espaciado, paleta, navbar, footer y responsividad móvil.
- Mantiene compatibilidad con tus páginas de proyectos existentes.


## Ajuste v2: portada más ancha

Se corrigió la estrechez de la portada. La clase `.mu-home` ahora expande la página principal a un ancho máximo de 1320px, centrado respecto del viewport, y el hero usa una columna izquierda más amplia. También se agregó `overflow-x: hidden` para evitar desplazamientos horizontales accidentales cuando el título es muy largo.
