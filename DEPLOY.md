# Publicar el sitio en GitHub Pages

## Opción recomendada: GitHub Actions

1. Reemplaza el contenido del repositorio `mulloav3007/Economics` por esta versión.
2. Confirma localmente que el sitio construye:

   ```bash
   python -m pip install -r requirements-site.txt
   python scripts/build_site.py
   python scripts/validate_site.py
   ```

3. Sube los cambios:

   ```bash
   git add .
   git commit -m "Rebuild professional economics portfolio"
   git push origin main
   ```

4. En GitHub abre `Settings → Pages`.
5. En **Build and deployment → Source**, selecciona **GitHub Actions**.
6. Abre la pestaña `Actions` y comprueba que el workflow **Build and deploy portfolio** finalice correctamente.
7. La página quedará disponible en:

   ```text
   https://mulloav3007.github.io/Economics/
   ```

A partir de ese momento, cada `push` a `main` vuelve a construir el sitio desde `site/`, valida los enlaces y despliega el artefacto generado.

## Opción alternativa: publicar `docs/` desde la rama

La carpeta `docs/` queda incluida y lista para usar. Si se prefiere el mecanismo antiguo:

1. `Settings → Pages`.
2. Selecciona **Deploy from a branch**.
3. Rama `main` y carpeta `/docs`.

No conviene activar simultáneamente el workflow y el despliegue desde rama. La opción con GitHub Actions es más segura porque impide publicar una construcción inválida.

## Actualización sin recalcular modelos

Cuando solo cambie texto, diseño o presentación:

```bash
python scripts/build_site.py
python scripts/validate_site.py
```

En Windows:

```powershell
.\scripts\09_rebuild_public_site.ps1
```

## Actualización con nuevos datos

Ejecuta primero el pipeline analítico correspondiente. Después reconstruye y valida el sitio. El constructor nunca reemplaza datos procesados por un fallback silencioso.

## Diagnóstico rápido

- **El workflow no aparece:** confirma que `.github/workflows/pages.yml` está en `main`.
- **Pages sigue mostrando la versión anterior:** revisa que la fuente sea `GitHub Actions` y que el último despliegue haya terminado.
- **El build falla por un archivo ausente:** no publiques manualmente; restaura o regenera la salida indicada por el error.
- **Un gráfico no cambia:** verifica que el CSV en `data/processed/` u `outputs/` se haya actualizado antes de ejecutar `build_site.py`.
