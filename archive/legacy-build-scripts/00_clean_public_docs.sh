#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Limpiando HTML publicos internos en docs..."
rm -f docs/LEEME*.html docs/INSTRUCCIONES*.html docs/README*.html docs/NOTAS*.html
rm -rf docs/matlab

echo
echo "Limpieza lista. Si tienes Quarto y R configurados, ejecuta: quarto render"
echo "Luego revisa git status, commit y push."
