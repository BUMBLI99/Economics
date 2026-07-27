#!/usr/bin/env python3
"""Fail-fast checks for the generated GitHub Pages site."""
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
EXPECTED = {
    "index.html", "proyectos.html", "cv.html", "contacto.html", "404.html",
    "proyectos/imacec.html", "proyectos/ipom-iris.html", "proyectos/transmision-tpm.html",
    "proyectos/exchange.html", "proyectos/estres-financiero.html", "proyectos/curva-rendimiento.html",
    "proyectos/estres-externo.html", "assets/css/site.css", "assets/js/site.js",
    "assets/files/cv-mauricio-ulloa.pdf", ".nojekyll", "sitemap.xml", "robots.txt",
}
SKIP_SCHEMES = {"http", "https", "mailto", "tel", "javascript", "data"}
PLACEHOLDERS = ["{{", "{%", "TODO", "FIXME", "tu_correo", "localhost:"]


def local_target(page: Path, raw: str) -> Path | None:
    raw = raw.strip()
    if not raw or raw.startswith("#"):
        return None
    parsed = urlsplit(raw)
    if parsed.scheme.lower() in SKIP_SCHEMES or parsed.netloc:
        return None
    path = unquote(parsed.path)
    if not path:
        return None
    if path.startswith("/Economics/"):
        return DOCS / path.removeprefix("/Economics/")
    if path == "/Economics" or path == "/Economics/":
        return DOCS / "index.html"
    if path.startswith("/"):
        # Absolute links to other roots are not part of this project.
        return None
    target = (page.parent / path).resolve()
    try:
        target.relative_to(DOCS.resolve())
    except ValueError:
        return target
    if target.is_dir():
        target = target / "index.html"
    return target


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    if not DOCS.exists():
        errors.append("docs/ no existe; ejecuta scripts/build_site.py")
    else:
        existing = {str(p.relative_to(DOCS)).replace("\\", "/") for p in DOCS.rglob("*") if p.is_file()}
        for rel in sorted(EXPECTED - existing):
            errors.append(f"Falta archivo esperado: {rel}")

        html_files = sorted(DOCS.rglob("*.html"))
        for page in html_files:
            text = page.read_text(encoding="utf-8")
            rel = page.relative_to(DOCS)
            for token in PLACEHOLDERS:
                if token in text:
                    errors.append(f"{rel}: marcador sin resolver {token!r}")
            soup = BeautifulSoup(text, "html.parser")
            if not soup.title or not soup.title.get_text(strip=True):
                errors.append(f"{rel}: falta <title>")
            if not soup.find("meta", attrs={"name": "description"}) and rel.name != "estres-externo.html":
                errors.append(f"{rel}: falta meta description")

            ids = [tag.get("id") for tag in soup.find_all(attrs={"id": True})]
            duplicates = sorted({x for x in ids if ids.count(x) > 1})
            for ident in duplicates:
                errors.append(f"{rel}: id duplicado #{ident}")

            for img in soup.find_all("img"):
                if not img.get("alt", "").strip():
                    errors.append(f"{rel}: imagen sin texto alternativo ({img.get('src', '?')})")

            for tag, attr in [("a", "href"), ("img", "src"), ("script", "src"), ("link", "href")]:
                for node in soup.find_all(tag):
                    raw = node.get(attr)
                    if raw is None:
                        continue
                    target = local_target(page, raw)
                    if target is not None and not target.exists():
                        errors.append(f"{rel}: enlace roto {raw} -> {target}")
            for node in soup.find_all(attrs={"data-url": True}):
                raw = node.get("data-url")
                target = local_target(page, raw)
                if target is not None and not target.exists():
                    errors.append(f"{rel}: recurso dinámico ausente {raw}")

            # Fragment links should point to an ID in the same page.
            id_set = set(ids)
            for anchor in soup.find_all("a", href=re.compile(r"^#.+")):
                ident = unquote(anchor["href"][1:])
                if ident not in id_set:
                    errors.append(f"{rel}: ancla interna inexistente #{ident}")

        # Public outputs should never contain source templates or old Quarto pages.
        forbidden_ext = {".qmd", ".rmd", ".r", ".m", ".py"}
        for p in DOCS.rglob("*"):
            if p.is_file() and p.suffix.lower() in forbidden_ext:
                errors.append(f"Código fuente filtrado a docs/: {p.relative_to(DOCS)}")

        # Keep large downloads visible but flag extreme accidental files.
        for p in DOCS.rglob("*"):
            if p.is_file() and p.stat().st_size > 25 * 1024 * 1024:
                warnings.append(f"Archivo público >25 MB: {p.relative_to(DOCS)}")

    if warnings:
        print("ADVERTENCIAS")
        for msg in warnings:
            print(f"  - {msg}")
    if errors:
        print("VALIDACIÓN FALLIDA")
        for msg in errors:
            print(f"  - {msg}")
        return 1
    print(f"VALIDACIÓN OK — {len(list(DOCS.rglob('*.html')))} páginas HTML y enlaces internos verificados.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
