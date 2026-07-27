#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python3 scripts/build_site.py
python3 scripts/validate_site.py
echo "Sitio listo en docs/."
