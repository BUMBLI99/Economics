# Instrucciones para usar esta carpeta

Esta carpeta está preparada como sitio Quarto para el repositorio:

- Repositorio: `https://github.com/mulloav3007/Economics`
- Página: `https://mulloav3007.github.io/Economics/`
- Carpeta local esperada: `D:\Users\mullo\Documents\GitHub\Economics`

## 1. Cómo copiarla en Windows

Tienes dos opciones:

### Opción recomendada

1. Descomprime el ZIP.
2. Abre la carpeta `Economics` del ZIP.
3. Copia **todo su contenido** dentro de:

```text
D:\Users\mullo\Documents\GitHub\Economics
```

No copies la carpeta completa dentro de otra carpeta `Economics`, porque podrías quedar con:

```text
D:\Users\mullo\Documents\GitHub\Economics\Economics
```

Eso no conviene.

### Si tu carpeta `Economics` está vacía

Puedes reemplazarla completa por la carpeta descomprimida.

## 2. Renderizar con Quarto

Abre PowerShell y ejecuta:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
quarto render
```

Eso genera o actualiza la carpeta `docs/`.

## 3. Configurar GitHub Pages

En GitHub:

```text
Settings → Pages → Build and deployment
```

Usa:

```text
Source: Deploy from a branch
Branch: main
Folder: /docs
```

## 4. Subir cambios

Con PowerShell:

```powershell
git add .
git commit -m "Configura sitio Quarto Economics"
git push
```

O con GitHub Desktop:

```text
Commit to main → Push origin
```

## 5. Importante

Las páginas de proyectos traen gráficos demo con datos simulados. Sirven para comprobar que la arquitectura funciona. Antes de usar la página como portafolio definitivo, reemplaza esos bloques por datos reales.
