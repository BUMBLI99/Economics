#!/usr/bin/env python3
"""Build the public portfolio into docs/ from committed analytical outputs.

The public layer is deliberately decoupled from R/Matlab execution. Analytical
pipelines update data/processed and outputs/; this script consumes those stable
artifacts, generates publication assets, and produces a deterministic static site.
"""
from __future__ import annotations

import argparse
import html
import json
import math
import re
import shutil
import subprocess
import sys
import unicodedata
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

import mistune
import pandas as pd
import yaml
from bs4 import BeautifulSoup
from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
DOCS = ROOT / "docs"
SITE_URL = "https://mulloav3007.github.io/Economics/"

MONTHS_ES = {
    1: "enero", 2: "febrero", 3: "marzo", 4: "abril", 5: "mayo", 6: "junio",
    7: "julio", 8: "agosto", 9: "septiembre", 10: "octubre", 11: "noviembre", 12: "diciembre",
}


def run_script(path: Path) -> None:
    subprocess.run([sys.executable, str(path)], cwd=ROOT, check=True)


def clean_docs() -> None:
    if DOCS.exists():
        shutil.rmtree(DOCS)
    DOCS.mkdir(parents=True)


def fmt_num(value: Any, digits: int = 2, signed: bool = False) -> str:
    try:
        x = float(value)
    except (TypeError, ValueError):
        return "—"
    if math.isnan(x):
        return "—"
    prefix = "+" if signed and x > 0 else ""
    return f"{prefix}{x:.{digits}f}".replace(".", ",")


def fmt_pct(value: Any, digits: int = 2, signed: bool = False) -> str:
    return fmt_num(value, digits, signed)


def fmt_month(value: Any) -> str:
    dt = pd.to_datetime(value)
    return f"{MONTHS_ES[dt.month]} de {dt.year}"


def fmt_date(value: Any) -> str:
    dt = pd.to_datetime(value)
    return f"{dt.day} de {MONTHS_ES[dt.month]} de {dt.year}"


def slugify(text: str) -> str:
    norm = unicodedata.normalize("NFKD", text)
    ascii_text = "".join(c for c in norm if not unicodedata.combining(c))
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", ascii_text).strip("-").lower()
    return slug or "seccion"


def table_html(df: pd.DataFrame, columns: list[str], labels: dict[str, str], formats: dict[str, Any] | None = None) -> str:
    formats = formats or {}
    parts = ['<div class="table-wrap"><table><thead><tr>']
    for col in columns:
        parts.append(f"<th>{html.escape(labels.get(col, col))}</th>")
    parts.append("</tr></thead><tbody>")
    for _, row in df.iterrows():
        parts.append("<tr>")
        for col in columns:
            val = row.get(col, "")
            if col in formats:
                val = formats[col](val)
            elif pd.isna(val):
                val = "—"
            parts.append(f"<td>{html.escape(str(val))}</td>")
        parts.append("</tr>")
    parts.append("</tbody></table></div>")
    return "".join(parts)


def build_contexts() -> dict[str, Any]:
    # IMACEC
    projections = pd.read_csv(ROOT / "data/processed/imacec_projection_all_models.csv")
    status = pd.read_csv(ROOT / "data/processed/imacec_update_status.csv").iloc[0]
    active = projections.loc[projections["model_key"].eq("base")].iloc[0]
    oos = pd.read_csv(ROOT / "data/processed/imacec_pseudo_oos_metrics.csv")
    oos["orden_var"] = oos["variable"].map({"IMACEC total": 0, "IMACEC no minero": 1}).fillna(9)
    preferred = [
        "Modelo con indicadores sectoriales INE",
        "Modelo con estadísticas experimentales",
        "Benchmark AR(1)",
        "Promedio móvil 3m",
        "Naive estacional t-12",
    ]
    oos["orden_mod"] = pd.Categorical(oos["modelo"], categories=preferred, ordered=True)
    oos = oos.sort_values(["orden_var", "orden_mod"])
    oos_table = table_html(
        oos,
        ["variable", "modelo", "N", "RMSE", "MAE", "Periodo"],
        {"variable": "Variable", "modelo": "Modelo", "N": "N", "RMSE": "RMSE", "MAE": "MAE", "Periodo": "Ventana evaluada"},
        {"N": lambda x: str(int(x)), "RMSE": lambda x: fmt_num(x, 2), "MAE": lambda x: fmt_num(x, 2)},
    )
    imacec = {
        "target": fmt_month(active["Periodo"]),
        "total": fmt_pct(active["imacec_predicho"], 2, True),
        "total_lwr": fmt_pct(active["imacec_lwr"], 2, True),
        "total_upr": fmt_pct(active["imacec_upr"], 2, True),
        "nonmining": fmt_pct(active["imacec_nm_predicho"], 2, True),
        "nonmining_lwr": fmt_pct(active["imacec_nm_lwr"], 2, True),
        "nonmining_upr": fmt_pct(active["imacec_nm_upr"], 2, True),
        "updated": fmt_date(status["fecha_actualizacion"]),
        "oos_table": oos_table,
    }

    # IPoM / IRIS
    ipom_diff = pd.read_csv(ROOT / "data/processed/ipom/ipom_scenario_differences_summary.csv")
    filt = ipom_diff[(ipom_diff["scenario_id"].eq("tpm45_2026")) & (ipom_diff["variable"].eq("D4L_CPI"))]
    if filt.empty:
        filt = ipom_diff[ipom_diff["variable"].eq("D4L_CPI")]
    max_inf = float(filt["maximo"].abs().max())
    ipom = {"max_inflation_diff": fmt_num(max_inf, 2)}

    # Transmission
    trans = pd.read_csv(ROOT / "outputs/tables/transmision_tpm/pass_through_summary.csv")
    get_h6 = lambda key: float(trans.loc[trans["product"].eq(key), "h6"].iloc[0])
    trans_table = table_html(
        trans.sort_values("h6", ascending=False),
        ["product_label", "h1", "h3", "h6"],
        {"product_label": "Producto", "h1": "1 mes", "h3": "3 meses", "h6": "6 meses"},
        {"h1": lambda x: fmt_num(x, 3), "h3": lambda x: fmt_num(x, 3), "h6": lambda x: fmt_num(x, 3)},
    )
    transmission = {
        "commercial_6m": fmt_num(get_h6("comercial_total"), 2),
        "consumption_6m": fmt_num(get_h6("consumo_total"), 2),
        "housing_6m": fmt_num(get_h6("vivienda_uf"), 3),
        "summary_table": trans_table,
    }

    # Chile financial stress
    snap = pd.read_csv(ROOT / "data/processed/estres_financiero/latest_snapshot.csv").iloc[0]
    diagnostics = pd.read_csv(ROOT / "data/processed/estres_financiero/model_diagnostics.csv")
    diagnostics_table = table_html(
        diagnostics,
        ["model", "n_obs", "r_squared", "adj_r_squared", "sample_start", "sample_end", "residual_sd"],
        {"model": "Bloque", "n_obs": "N", "r_squared": "R²", "adj_r_squared": "R² ajustado", "sample_start": "Inicio", "sample_end": "Fin", "residual_sd": "σ residuo"},
        {"n_obs": lambda x: str(int(x)), "r_squared": lambda x: fmt_num(x, 3), "adj_r_squared": lambda x: fmt_num(x, 3), "residual_sd": lambda x: fmt_num(x, 3)},
    )
    stress = {
        "date": fmt_date(snap["date"]),
        "index_30d": fmt_num(snap["stress_market_30d"], 2, True),
        "fx_30d": fmt_num(snap["stress_fx_30d"], 2, True),
        "y10_30d": fmt_num(snap["stress_y10_30d"], 2, True),
        "regime": str(snap["regime"]),
        "diagnostics_table": diagnostics_table,
    }

    # Regional exchange models
    ex_snap = pd.read_csv(ROOT / "data/processed/exchange/latest_snapshot.csv")
    ex_date = pd.to_datetime(ex_snap["date"]).max()
    clp = ex_snap[ex_snap["country"].eq("CLP")].iloc[0]
    ex_fit = pd.read_csv(ROOT / "data/processed/exchange/model_fit_summary.csv")
    fx_fit = ex_fit.loc[ex_fit["block"].eq("FX"), ["country", "r2", "rmse"]].rename(columns={"r2": "fx_r2", "rmse": "fx_rmse"})
    y10_fit = ex_fit.loc[ex_fit["block"].eq("10Y"), ["country", "r2", "rmse"]].rename(columns={"r2": "y10_r2", "rmse": "y10_rmse"})
    fit_df = fx_fit.merge(y10_fit, on="country", how="outer").sort_values("country")
    fit_table = table_html(
        fit_df,
        ["country", "fx_r2", "fx_rmse", "y10_r2", "y10_rmse"],
        {"country": "País/moneda", "fx_r2": "FX · R²", "fx_rmse": "FX · RMSE", "y10_r2": "10Y · R²", "y10_rmse": "10Y · RMSE"},
        {c: (lambda x: fmt_num(x, 3)) for c in ["fx_r2", "fx_rmse", "y10_r2", "y10_rmse"]},
    )
    exchange = {
        "date": fmt_date(ex_date),
        "clp_fx": fmt_num(clp["FX"], 2, True),
        "clp_y10": fmt_num(clp["10Y"], 2, True),
        "fit_table": fit_table,
    }

    # Yield curve
    rates = pd.read_csv(ROOT / "data/processed/transmision_tpm/monthly_panel_rates.csv", parse_dates=["date"])
    curve_cols = ["bcp_2y", "bcp_5y", "bcp_10y", "bcu_5y", "bcu_10y"]
    curve = rates.dropna(subset=curve_cols, how="all").copy()
    curve["slope_10y_2y"] = curve["bcp_10y"] - curve["bcp_2y"]
    curve["be_5y"] = curve["bcp_5y"] - curve["bcu_5y"]
    curve["be_10y"] = curve["bcp_10y"] - curve["bcu_10y"]
    latest_curve = curve.dropna(subset=["bcp_2y", "bcp_10y", "bcu_10y"]).iloc[-1]
    yield_curve = {
        "date": fmt_month(latest_curve["date"]),
        "bcp10": fmt_num(latest_curve["bcp_10y"], 2),
        "slope": fmt_num(latest_curve["slope_10y_2y"], 2, True),
        "be10": fmt_num(latest_curve["be_10y"], 2),
    }

    return {
        "imacec": imacec,
        "ipom": ipom,
        "transmission": transmission,
        "stress": stress,
        "exchange": exchange,
        "yield_curve": yield_curve,
        "yield_curve_df": curve,
    }


def enrich_html(content_html: str) -> tuple[str, list[dict[str, str]]]:
    soup = BeautifulSoup(content_html, "html.parser")
    used: set[str] = set()
    toc: list[dict[str, str]] = []
    for h in soup.find_all("h2"):
        text = h.get_text(" ", strip=True)
        base = slugify(text)
        ident = base
        n = 2
        while ident in used:
            ident = f"{base}-{n}"
            n += 1
        used.add(ident)
        h["id"] = ident
        toc.append({"id": ident, "text": text})
    for image in soup.find_all("img"):
        if not image.has_attr("loading"):
            image["loading"] = "lazy"
        if not image.has_attr("decoding"):
            image["decoding"] = "async"
    for anchor in soup.find_all("a", target="_blank"):
        rel = set(anchor.get("rel", []))
        anchor["rel"] = sorted(rel | {"noopener", "noreferrer"})
    return str(soup), toc


def render_markdown(path: Path, context: dict[str, Any], markdown: mistune.Markdown) -> tuple[str, list[dict[str, str]]]:
    source = path.read_text(encoding="utf-8")
    rendered_source = Environment(undefined=StrictUndefined, autoescape=False).from_string(source).render(**context)
    content_html = markdown(rendered_source)
    return enrich_html(content_html)


def make_brand_assets() -> None:
    img_dir = SITE / "assets/img"
    img_dir.mkdir(parents=True, exist_ok=True)
    favicon = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#193044"/><stop offset="1" stop-color="#416c8a"/></linearGradient></defs><rect width="64" height="64" rx="18" fill="url(#g)"/><text x="32" y="39" text-anchor="middle" font-family="Arial,sans-serif" font-size="22" font-weight="700" fill="white">MU</text></svg>"""
    (img_dir / "favicon.svg").write_text(favicon, encoding="utf-8")

    w, h = 1200, 630
    im = Image.new("RGB", (w, h), "#f4f1eb")
    draw = ImageDraw.Draw(im)
    draw.ellipse((-160, -210, 430, 380), fill="#dfe7ec")
    draw.ellipse((930, -140, 1360, 290), fill="#eadbd5")
    font_bold = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
    font_reg = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    title_font = ImageFont.truetype(font_bold, 66)
    sub_font = ImageFont.truetype(font_reg, 31)
    eyebrow_font = ImageFont.truetype(font_bold, 23)
    draw.rounded_rectangle((70, 70, 150, 150), radius=22, fill="#193044")
    mu_font = ImageFont.truetype(font_bold, 27)
    draw.text((110, 110), "MU", anchor="mm", font=mu_font, fill="white")
    draw.text((70, 220), "PORTAFOLIO DE ECONOMÍA APLICADA", font=eyebrow_font, fill="#b4573d")
    draw.multiline_text((70, 270), "Macroeconomía, política\nmonetaria y datos", font=title_font, fill="#162634", spacing=8)
    draw.text((72, 505), "Mauricio Ulloa · Chile y América Latina", font=sub_font, fill="#66727f")
    im.save(img_dir / "og-cover.png", quality=94)


def copy_public_assets(contexts: dict[str, Any]) -> None:
    shutil.copytree(SITE / "assets", DOCS / "assets", dirs_exist_ok=True)
    files_out = DOCS / "assets/files"
    files_out.mkdir(parents=True, exist_ok=True)

    # Curated public downloads.
    copies = {
        ROOT / "data/processed/imacec_projection_all_models.csv": files_out / "imacec-nowcast-summary.csv",
        ROOT / "data/processed/imacec_pseudo_oos_metrics.csv": files_out / "imacec-oos-metrics.csv",
        ROOT / "outputs/tables/transmision_tpm/pass_through_summary.csv": files_out / "transmission-pass-through-summary.csv",
        ROOT / "outputs/tables/transmision_tpm/local_projections.csv": files_out / "transmission-local-projections.csv",
        ROOT / "data/processed/estres_financiero/latest_snapshot.csv": files_out / "stress-latest-snapshot.csv",
        ROOT / "outputs/tables/estres_financiero/episodios_estres.csv": files_out / "stress-episodes.csv",
        ROOT / "assets/files/exchange_model_report.pdf": files_out / "exchange_model_report.pdf",
        ROOT / "assets/files/exchange_model_outputs_2025.xlsx": files_out / "exchange_model_outputs_2025.xlsx",
    }
    for src, dst in copies.items():
        if not src.exists():
            raise FileNotFoundError(f"Falta un archivo público requerido: {src}")
        shutil.copy2(src, dst)

    ipom_src = ROOT / "assets/files/ipom"
    if ipom_src.exists():
        shutil.copytree(ipom_src, files_out / "ipom", dirs_exist_ok=True)

    curve = contexts["yield_curve_df"].copy()
    cols = ["date", "bcp_2y", "bcp_5y", "bcp_10y", "bcu_5y", "bcu_10y", "slope_10y_2y", "be_5y", "be_10y"]
    curve[cols].to_csv(files_out / "yield-curve-monthly.csv", index=False)


def project_actions(slug: str) -> str:
    github_base = "https://github.com/mulloav3007/Economics/tree/main"
    source_map = {
        "imacec": f"{github_base}/R",
        "ipom-iris": f"{github_base}/matlab/ipom",
        "transmision-tpm": f"{github_base}/R/transmision_tpm",
        "exchange": f"{github_base}/modelos/exchange",
        "estres-financiero": f"{github_base}/R/estres_financiero",
        "curva-rendimiento": f"{github_base}/R/transmision_tpm",
    }
    source = source_map[slug]
    return f'<a class="button button-secondary" href="{source}" target="_blank" rel="noopener">Ver código ↗</a>'


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def build_pages(contexts: dict[str, Any]) -> None:
    projects = yaml.safe_load((SITE / "data/projects.yml").read_text(encoding="utf-8"))
    projects = sorted(projects, key=lambda p: p["order"])
    env = Environment(
        loader=FileSystemLoader(SITE / "templates"),
        autoescape=select_autoescape(["html", "xml"]),
        undefined=StrictUndefined,
        trim_blocks=True,
        lstrip_blocks=True,
    )
    markdown = mistune.create_markdown(escape=False, plugins=["table", "strikethrough"])

    common = {
        **contexts,
        "projects": projects,
        "site_url": SITE_URL,
    }

    # Home
    home = env.get_template("home.html").render(
        title="Inicio",
        description="Portafolio de economía aplicada de Mauricio Ulloa: macroeconomía, política monetaria, actividad y macrofinanzas para Chile y América Latina.",
        canonical_url=SITE_URL,
        og_image_url=SITE_URL + "assets/img/og-cover.png",
        base_path="",
        active_nav="inicio",
        body_class="home",
        featured_projects=[p for p in projects if p.get("featured")],
    )
    write_text(DOCS / "index.html", home)

    # Standard pages
    page_specs = {
        "proyectos": {
            "title": "Proyectos",
            "description": "Proyectos de nowcasting, política monetaria, tasas, tipo de cambio y condiciones financieras.",
            "eyebrow": "Portafolio",
            "page_title": "Proyectos",
            "subtitle": "Una colección estandarizada de herramientas aplicadas, notas técnicas y monitores macroeconómicos.",
            "active_nav": "proyectos",
        },
        "cv": {
            "title": "Currículum",
            "description": "Trayectoria académica y profesional de Mauricio Ulloa, economista y Magíster en Análisis Económico.",
            "eyebrow": "Trayectoria",
            "page_title": "Currículum",
            "subtitle": "Formación, experiencia de investigación y herramientas para economía aplicada.",
            "active_nav": "cv",
        },
        "contacto": {
            "title": "Contacto",
            "description": "Contacto profesional de Mauricio Ulloa.",
            "eyebrow": "Contacto",
            "page_title": "Conversemos",
            "subtitle": "Comentarios sobre los proyectos, investigación aplicada y colaboración profesional.",
            "active_nav": "contacto",
        },
    }
    for slug, spec in page_specs.items():
        content_html, _ = render_markdown(SITE / f"content/{slug}.md", common, markdown)
        rendered = env.get_template("page.html").render(
            **spec,
            content_html=content_html,
            actions="",
            canonical_url=SITE_URL + f"{slug}.html",
            og_image_url=SITE_URL + "assets/img/og-cover.png",
            base_path="",
            body_class=f"page-{slug}",
        )
        write_text(DOCS / f"{slug}.html", rendered)

    # Project pages
    project_meta_overrides = {
        "imacec": ("30 de junio de 2026", "Mensual", "R"),
        "ipom-iris": ("2026", "Trimestral", "Matlab · IRIS · R"),
        "transmision-tpm": ("Mayo de 2026", "Mensual", "R"),
        "exchange": ("1 de junio de 2026", "Diaria", "R"),
        "estres-financiero": ("18 de mayo de 2026", "Diaria", "R"),
        "curva-rendimiento": ("Mayo de 2026", "Mensual", "R"),
    }
    for p in projects:
        content_html, toc = render_markdown(SITE / f"content/projects/{p['slug']}.md", common, markdown)
        updated, frequency, tools = project_meta_overrides[p["slug"]]
        project = {
            **p,
            "deck": p["description"],
            "updated": updated,
            "frequency": frequency,
            "tools": tools,
            "actions": project_actions(p["slug"]),
        }
        rendered = env.get_template("project.html").render(
            title=p["short_title"],
            description=p["description"],
            canonical_url=SITE_URL + f"proyectos/{p['slug']}.html",
            og_image_url=SITE_URL + p["image"],
            base_path="../",
            active_nav="proyectos",
            body_class=f"project project-{p['slug']}",
            project=project,
            content_html=content_html,
            toc=toc,
        )
        write_text(DOCS / f"proyectos/{p['slug']}.html", rendered)

    # Compatibility redirect for an old public URL.
    redirect = """<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="0; url=estres-financiero.html"><link rel="canonical" href="estres-financiero.html"><title>Redirigiendo…</title></head><body><p>Este proyecto cambió de dirección. <a href="estres-financiero.html">Abrir índice de estrés financiero</a>.</p></body></html>"""
    write_text(DOCS / "proyectos/estres-externo.html", redirect)

    # 404 page.
    not_found_content = """<div class="panel reading"><p class="eyebrow">Error 404</p><h2>La página no existe o cambió de dirección.</h2><p>Regresa al índice de proyectos para continuar navegando.</p><a class="button button-primary" href="/Economics/proyectos.html">Ver proyectos</a></div>"""
    not_found = env.get_template("page.html").render(
        title="Página no encontrada",
        description="Página no encontrada.",
        canonical_url=SITE_URL + "404.html",
        og_image_url=SITE_URL + "assets/img/og-cover.png",
        base_path="",
        active_nav="",
        body_class="page-404",
        eyebrow="404",
        page_title="Página no encontrada",
        subtitle="El enlace puede haber cambiado durante la reorganización del portafolio.",
        actions="",
        content_html=not_found_content,
    )
    write_text(DOCS / "404.html", not_found)

    # Metadata and GitHub Pages support.
    write_text(DOCS / ".nojekyll", "")
    write_text(DOCS / "robots.txt", f"User-agent: *\nAllow: /\nSitemap: {SITE_URL}sitemap.xml\n")
    urls = [SITE_URL, SITE_URL + "proyectos.html", SITE_URL + "cv.html", SITE_URL + "contacto.html"]
    urls += [SITE_URL + f"proyectos/{p['slug']}.html" for p in projects]
    today = datetime.now().date().isoformat()
    xml = ['<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for url in urls:
        xml.append(f"  <url><loc>{html.escape(url)}</loc><lastmod>{today}</lastmod></url>")
    xml.append("</urlset>")
    write_text(DOCS / "sitemap.xml", "\n".join(xml) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-assets", action="store_true", help="Do not regenerate charts and CV before building.")
    args = parser.parse_args()

    if not args.skip_assets:
        run_script(ROOT / "scripts/generate_site_assets.py")
        run_script(ROOT / "scripts/build_public_cv.py")
    make_brand_assets()
    contexts = build_contexts()
    clean_docs()
    copy_public_assets(contexts)
    build_pages(contexts)
    print(f"Site built at {DOCS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
