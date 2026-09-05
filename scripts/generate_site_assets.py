#!/usr/bin/env python3
"""Generate all public charts and lightweight JSON assets for the portfolio site.

The analytical pipelines remain in R/Matlab. This script only transforms committed
processed outputs into deterministic, publication-ready web assets.
"""
from __future__ import annotations

import json
from pathlib import Path

import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "site" / "assets" / "img" / "charts"
DATA_OUT = ROOT / "site" / "assets" / "data"
OUT.mkdir(parents=True, exist_ok=True)
DATA_OUT.mkdir(parents=True, exist_ok=True)

COLORS = {
    "navy": "#193044",
    "blue": "#416C8A",
    "teal": "#2B7777",
    "terracotta": "#B4573D",
    "gold": "#B28A4A",
    "sage": "#6F8A72",
    "purple": "#76658C",
    "slate": "#73808D",
    "ink": "#1F2B36",
    "muted": "#65717E",
    "grid": "#DDD8CF",
    "paper": "#FFFFFF",
    "soft": "#F5F2EC",
}

plt.rcParams.update({
    "figure.facecolor": COLORS["paper"],
    "axes.facecolor": COLORS["paper"],
    "savefig.facecolor": COLORS["paper"],
    "font.family": "DejaVu Sans",
    "font.size": 11,
    "axes.titlesize": 17,
    "axes.titleweight": "bold",
    "axes.labelsize": 11,
    "axes.labelcolor": COLORS["muted"],
    "axes.edgecolor": COLORS["grid"],
    "axes.linewidth": 0.8,
    "xtick.color": COLORS["muted"],
    "ytick.color": COLORS["muted"],
    "grid.color": COLORS["grid"],
    "grid.alpha": 0.72,
    "legend.frameon": False,
    "svg.hashsalt": "economics-portfolio",
})


def style_ax(ax: plt.Axes, title: str, subtitle: str | None = None, grid: str = "y") -> None:
    ax.set_title(title, loc="left", color=COLORS["ink"], pad=24 if subtitle else 12)
    if subtitle:
        ax.text(0, 1.025, subtitle, transform=ax.transAxes, ha="left", va="bottom",
                fontsize=10.5, color=COLORS["muted"])
    ax.grid(axis=grid, linewidth=0.8)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(COLORS["grid"])
    ax.spines["bottom"].set_color(COLORS["grid"])
    ax.margins(x=0.01)


def save(fig: plt.Figure, stem: str, height: int = 760) -> None:
    fig.tight_layout(pad=1.8)
    fig.savefig(OUT / f"{stem}.svg", bbox_inches="tight")
    fig.savefig(OUT / f"{stem}.png", dpi=160, bbox_inches="tight")
    plt.close(fig)


def add_source(fig: plt.Figure, text: str) -> None:
    fig.text(0.012, 0.006, text, ha="left", va="bottom", fontsize=8.2, color=COLORS["muted"])


def web_series(name: str, color: str, frame: pd.DataFrame, date: str, value: str,
               dash: str = "", line: bool = True, marker: str = "", width: float = 2.4) -> dict:
    """Compact, null-safe series consumed by the dependency-free web charts."""
    clean = frame[[date, value]].dropna().sort_values(date)
    return {
        "name": name, "color": color, "dash": dash, "line": line,
        "marker": marker, "width": width,
        "values": [{"date": pd.Timestamp(d).strftime("%Y-%m-%d"), "value": round(float(v), 5)}
                   for d, v in clean.itertuples(index=False, name=None)],
    }


def interactive_assets() -> None:
    """Build a coherent interactive explorer for every published project."""
    charts: dict[str, dict] = {}
    hist = pd.read_csv(ROOT / "data/processed/imacec_nowcast_history_all_models.csv", parse_dates=["Periodo"])
    hist = hist[hist["Periodo"] >= "2019-01-01"]
    projections = pd.read_csv(ROOT / "data/processed/imacec_projection_all_models.csv", parse_dates=["Periodo"])
    status = pd.read_csv(ROOT / "data/processed/imacec_update_status.csv")
    archive_path = ROOT / "data/processed/imacec_projection_archive.csv"
    archive = pd.read_csv(archive_path, parse_dates=["Periodo"]) if archive_path.exists() else pd.DataFrame()
    manual_path = ROOT / "data/processed/imacec_manual_vintages.csv"
    manual = pd.read_csv(manual_path, parse_dates=["Periodo"]) if manual_path.exists() else pd.DataFrame()
    archive_frames = [frame for frame in [archive, manual] if not frame.empty]
    archived_points = (pd.concat(archive_frames, ignore_index=True, sort=False)
                       if archive_frames else pd.DataFrame())
    new_schema = {"target_key", "observed", "fitted", "model_key"}.issubset(hist.columns)
    projection_schema = {"target_key", "forecast", "eee_value", "model_key"}.issubset(projections.columns)
    cycle_schema = {"ciclo_estado", "modelo_principal", "periodo_objetivo"}.issubset(status.columns)
    stage = str(status.iloc[-1]["ciclo_estado"]) if cycle_schema else "pending"
    default_key = str(status.iloc[-1]["modelo_principal"]) if cycle_schema else "summary"
    target_period = pd.to_datetime(status.iloc[-1]["periodo_objetivo"]) if cycle_schema else None
    model_meta = {
        "ar1": ("Proxy · AR(1)", "AR(1) de referencia", COLORS["gold"], "circle"),
        "ma3": ("Proxy · media móvil 3m", "Media móvil 3 meses", COLORS["sage"], "diamond"),
        "m4": ("Corte experimental · M4", "M4 · Dinámico", COLORS["terracotta"], "circle"),
        "m8p": ("Corte INE · M8P", "M8P · INE + IVS real", COLORS["teal"], "diamond"),
    }

    def actual_series(target_key: str) -> pd.DataFrame:
        if new_schema:
            return (hist[(hist["target_key"] == target_key) & (hist["tipo"] == "Efectivo")]
                    [["Periodo", "observed"]].dropna().drop_duplicates("Periodo").sort_values("Periodo"))
        value = "imacec" if target_key == "total" else "imacec_nm"
        if value not in hist.columns:
            return pd.DataFrame(columns=["Periodo", "observed"])
        return (hist[["Periodo", value]].dropna().drop_duplicates("Periodo")
                .rename(columns={value: "observed"}).sort_values("Periodo"))

    def is_true(value: object) -> bool:
        return str(value).strip().lower() in {"true", "1", "yes"}

    def best_point(target_key: str, model_key: str) -> pd.DataFrame:
        current = projections[
            (projections["target_key"] == target_key) &
            (projections["model_key"] == model_key)
        ].copy() if projection_schema else pd.DataFrame()
        required = {"target_key", "model_key", "forecast", "run_timestamp", "Periodo"}
        if not required.issubset(archived_points.columns) or target_period is None:
            return current.tail(1)
        historical = archived_points[
            (archived_points["target_key"] == target_key) &
            (archived_points["model_key"] == model_key) &
            (archived_points["Periodo"] == target_period)
        ].copy()
        if not historical.empty:
            realtime = historical[historical.get("is_realtime", False).map(is_true)] if "is_realtime" in historical else pd.DataFrame()
            chosen = realtime if not realtime.empty else historical
            return chosen.sort_values("run_timestamp").tail(1)
        return current.tail(1)

    def actual_target_row(actual: pd.DataFrame) -> pd.DataFrame:
        if target_period is None:
            return pd.DataFrame(columns=["Periodo", "observed"])
        return actual[actual["Periodo"] == target_period].tail(1)

    def row_table(label: str, point: pd.DataFrame, value_col: str,
                  status: str = "", source: str = "") -> dict | None:
        if point.empty or value_col not in point or pd.isna(point.iloc[-1][value_col]):
            return None
        row = point.iloc[-1]
        interval = "—"
        if value_col == "forecast" and pd.notna(row.get("lwr")) and pd.notna(row.get("upr")):
            interval = f"[{float(row['lwr']):.2f}; {float(row['upr']):.2f}]"
        timestamp = str(row.get("run_timestamp", row.get("fecha_actualizacion", "—")))
        if value_col == "eee_value" and pd.notna(row.get("eee_survey_period")):
            timestamp = str(row["eee_survey_period"])
        vintage = timestamp[:10] if len(timestamp) >= 10 and timestamp[4:5] == "-" else timestamp
        if value_col == "eee_value" and pd.notna(row.get("eee_survey_period")):
            vintage = str(row["eee_survey_period"])[:7] + " (encuesta)"
        return {
            "concept": label,
            "period": pd.Timestamp(row["Periodo"]).strftime("%Y-%m"),
            "value": round(float(row[value_col]), 4),
            "interval": interval,
            "vintage": vintage,
            "status": source or status or str(row.get("provenance", row.get("estado", ""))),
        }

    def effective_table_row(actual: pd.DataFrame) -> dict | None:
        point = actual_target_row(actual)
        if point.empty:
            return None
        publication = str(status.iloc[-1].get("fecha_actualizacion", "Dato oficial"))
        point = point.assign(run_timestamp=publication, provenance="Banco Central de Chile")
        return row_table("IMACEC efectivo", point, "observed", source="Dato oficial publicado")

    def eee_table_row(point: pd.DataFrame) -> dict | None:
        return row_table("EEE comparable", point, "eee_value", source="EEE publicada un mes después del período objetivo")

    def model_table_row(model_key: str, point: pd.DataFrame) -> dict | None:
        if point.empty:
            return None
        _, model_label, _, _ = model_meta[model_key]
        source = str(point.iloc[-1].get("provenance", point.iloc[-1].get("estado", "")))
        return row_table(f"Proyección {model_label}", point, "forecast", source=source)

    def compact_rows(rows: list[dict | None]) -> list[dict]:
        return [row for row in rows if row is not None]

    def current_dataset(target_key: str, model_key: str, actual: pd.DataFrame) -> dict | None:
        if not (new_schema and projection_schema) or model_key not in model_meta:
            return None
        block = hist[(hist["target_key"] == target_key) & (hist["model_key"] == model_key)]
        point = best_point(target_key, model_key)
        if block.empty and point.empty:
            return None
        dataset_label, model_label, color, marker = model_meta[model_key]
        series = [web_series("IMACEC efectivo", COLORS["navy"], actual, "Periodo", "observed", width=2.7)]
        fit = block[block["tipo"] == "Ajuste"]
        if not fit.empty:
            series.append(web_series("Ajuste histórico reestimado", color, fit, "Periodo", "fitted", "7 5", width=2.0))
        if not point.empty:
            series.append(web_series(f"Proyección {model_label}", color, point, "Periodo", "forecast",
                                     line=False, marker=marker, width=0))
            series.append(web_series("EEE comparable", COLORS["purple"], point, "Periodo", "eee_value",
                                     line=False, marker="triangle", width=0))
        realtime = bool(not point.empty and is_true(point.iloc[-1].get("is_realtime", False)))
        note = ("Vintage guardado antes de conocerse el dato efectivo." if realtime else
                "Referencia reestimada con la base disponible al cierre; no se presenta como vintage en tiempo real.")
        if not fit.empty:
            fit_date = str(status.iloc[-1].get("fecha_actualizacion", ""))[:10]
            note += f" Ajuste histórico reestimado al {fit_date}: dentro de muestra, distinto del pronóstico archivado."
        else:
            note += " Ajuste histórico no disponible en la última ejecución; el punto archivado no acredita que el modelo automático se haya estimado."
        diagnostics_path = ROOT / "data/processed/imacec_model_status.csv"
        if diagnostics_path.exists():
            diagnostics = pd.read_csv(diagnostics_path).fillna("")
            diagnostic = diagnostics[(diagnostics.model_key == model_key) & (diagnostics.target_key == target_key)]
            if not diagnostic.empty:
                missing = diagnostic.iloc[-1].missing_variables
                if missing:
                    note += f" Faltan datos del corte actual: {missing}."
                if diagnostic.iloc[-1].ine_fallback and model_key == "m8p":
                    note += " Reestimación actual con respaldo INE a un decimal para indicadores ausentes en BDE."
        rows = compact_rows([
            effective_table_row(actual), model_table_row(model_key, point), eee_table_row(point)
        ])
        return {
            "id": model_key, "label": dataset_label, "series": series,
            "zeroLine": True, "yDigits": 1, "table": rows, "note": note, "exactDates": True,
        }

    def summary_dataset(target_key: str, actual: pd.DataFrame) -> dict:
        series = [web_series("IMACEC efectivo", COLORS["navy"], actual, "Periodo", "observed", width=2.7)]
        effective = actual_target_row(actual)
        if not effective.empty:
            series.append(web_series("Dato efectivo del período", COLORS["navy"], effective,
                                     "Periodo", "observed", line=False, marker="circle", width=0))
        points = {key: best_point(target_key, key) for key in ["m8p", "m4", "ar1", "ma3"]}
        for key, point in points.items():
            if point.empty:
                continue
            _, model_label, color, marker = model_meta[key]
            series.append(web_series(f"Proyección {model_label}", color, point, "Periodo", "forecast",
                                     line=False, marker=marker, width=0))
        eee = next((point for point in points.values()
                    if not point.empty and "eee_value" in point and point["eee_value"].notna().any()), pd.DataFrame())
        if not eee.empty:
            series.append(web_series("EEE comparable", COLORS["purple"], eee, "Periodo", "eee_value",
                                     line=False, marker="triangle", width=0))
        rows = [effective_table_row(actual)]
        rows.extend(model_table_row(key, points[key]) for key in ["m8p", "m4", "ar1", "ma3"])
        rows.append(eee_table_row(eee))
        return {
            "id": "summary", "label": "Resumen del período", "series": series,
            "zeroLine": True, "yDigits": 1, "table": compact_rows(rows), "exactDates": True,
            "note": "El resumen prioriza vintages guardados antes del dato efectivo; las referencias reconstruidas quedan identificadas en la tabla.",
        }

    for target_key, chart_key in [("total", "imacec-total"), ("no_minero", "imacec-nonmining")]:
        actual = actual_series(target_key)
        datasets: list[dict] = []
        if stage == "official_review" or not projection_schema:
            datasets.append(summary_dataset(target_key, actual))
            for key in ["m8p", "m4", "ar1", "ma3"]:
                dataset = current_dataset(target_key, key, actual)
                if dataset is not None:
                    datasets.append(dataset)
            selected = "summary"
        else:
            order = [default_key] + [key for key in ["m8p", "m4", "ar1", "ma3"] if key != default_key]
            for key in order:
                dataset = current_dataset(target_key, key, actual)
                if dataset is not None:
                    datasets.append(dataset)
            if not datasets:
                datasets.append(summary_dataset(target_key, actual))
            selected = default_key if any(d["id"] == default_key for d in datasets) else datasets[0]["id"]
        charts[chart_key] = {
            "ariaLabel": f"Evolución interactiva del {'IMACEC total' if target_key == 'total' else 'IMACEC no minero'}",
            "defaultDataset": selected, "datasets": datasets,
        }

    ipom = pd.read_csv(ROOT / "data/processed/ipom/ipom_scenarios_long.csv", parse_dates=["date"])
    ipom = ipom[(ipom["scenario_id"].isin(["baseline_ipom", "tpm45_2026"])) & (ipom["date"] >= "2024-01-01")]
    ipom_sets = []
    for var, label in [("TPM", "TPM"), ("D4L_CPI", "Inflación total"), ("D4L_CPIXFE", "Inflación subyacente"), ("L_GDP_GAP", "Brecha de actividad")]:
        series = [web_series(name, color, ipom[(ipom["variable"] == var) & (ipom["scenario_id"] == sid)], "date", "value", dash)
                  for sid, name, color, dash in [("baseline_ipom", "Escenario base", COLORS["navy"], ""), ("tpm45_2026", "TPM 4,5% en 2026", COLORS["terracotta"], "7 5")]]
        ipom_sets.append({"id": var.lower(), "label": label, "series": series, "zeroLine": True, "yDigits": 2})
    charts["ipom"] = {"ariaLabel": "Escenarios interactivos del modelo IPoM", "datasets": ipom_sets}

    rates = pd.read_csv(ROOT / "data/processed/transmision_tpm/monthly_panel_rates.csv", parse_dates=["date"])
    rates = rates[rates["date"] >= "2014-01-01"]
    rate_series = [web_series(name, color, rates, "date", col) for col, name, color in [("tpm", "TPM", COLORS["navy"]), ("comercial_total", "Crédito comercial", COLORS["terracotta"]), ("vivienda_uf", "Vivienda UF >3 años", COLORS["purple"]), ("cap_90_1y", "Captación 90d–1a", COLORS["teal"])]]
    cum = pd.read_csv(ROOT / "outputs/tables/transmision_tpm/pass_through_cumulative.csv")
    cum["chart_date"] = pd.to_datetime("2000-01-01") + cum["horizon"].map(lambda value: pd.DateOffset(months=int(value)))
    cum_series = [web_series(label, color, cum[cum["product"] == product], "chart_date", "cumulative") for product, label, color in [("comercial_total", "Comercial", COLORS["terracotta"]), ("consumo_total", "Consumo", COLORS["teal"]), ("vivienda_uf", "Vivienda UF", COLORS["purple"]), ("cap_90_1y", "Captaciones", COLORS["gold"])]]
    horizon_by_date = {pd.Timestamp(row.chart_date).strftime("%Y-%m-%d"): f"Horizonte: {int(row.horizon)} {'mes' if int(row.horizon) == 1 else 'meses'}" for row in cum[["chart_date", "horizon"]].drop_duplicates().itertuples(index=False)}
    for series in cum_series:
        for point in series["values"]:
            point["label"] = horizon_by_date[point["date"]]
    horizon_ticks = [{"date": date, "label": label.removeprefix("Horizonte: ")} for date, label in horizon_by_date.items()]
    charts["transmission"] = {"ariaLabel": "Transmisión interactiva de la TPM", "datasets": [{"id": "rates", "label": "TPM y tasas bancarias", "series": rate_series, "yDigits": 2}, {"id": "pass", "label": "Pass-through acumulado", "series": cum_series, "xTicks": horizon_ticks, "yDigits": 3}]}

    debt = pd.read_csv(ROOT / "data/processed/sostenibilidad_deuda/trayectorias_escenarios.csv")
    debt["chart_date"] = pd.to_datetime(debt["anio"].astype(int).astype(str) + "-01-01")
    debt_order = [
        ("Base compatible con la meta", COLORS["navy"], ""),
        ("Gasto comprometido (oficial)", COLORS["gold"], "5 4"),
        ("Menor crecimiento", COLORS["teal"], ""),
        ("Mayor tasa de interés", COLORS["purple"], ""),
        ("Menor esfuerzo fiscal", COLORS["blue"], ""),
        ("Combinación adversa", COLORS["terracotta"], ""),
    ]
    debt_series = [
        web_series(name, color, debt[debt["escenario"].eq(name)], "chart_date", "deuda_pib", dash)
        for name, color, dash in debt_order
    ]
    # Express debt ratios as percentage points for a natural web tooltip.
    for series in debt_series:
        for point in series["values"]:
            point["value"] = round(100 * point["value"], 4)
            point["label"] = point["date"][:4]
    base = debt[debt["escenario"].eq("Base compatible con la meta")].copy()
    decomposition = [
        web_series(label, color, base, "chart_date", col)
        for col, label, color in [
            ("efecto_interes_crecimiento", "Interés-crecimiento", COLORS["navy"]),
            ("efecto_balance_primario", "Balance primario", COLORS["terracotta"]),
            ("efecto_sfa", "Ajustes stock-flujo", COLORS["teal"]),
        ]
    ]
    for series in decomposition:
        for point in series["values"]:
            point["value"] = round(100 * point["value"], 4)
            point["label"] = point["date"][:4]
    charts["debt"] = {
        "ariaLabel": "Escenarios interactivos de deuda pública",
        "defaultDataset": "trajectories",
        "datasets": [
            {"id": "trajectories", "label": "Trayectorias de deuda", "series": debt_series,
             "yDigits": 1, "note": "Porcentaje del PIB. Desde 2031 las trayectorias son extensiones ilustrativas propias."},
            {"id": "decomposition", "label": "Descomposición del escenario base", "series": decomposition,
             "zeroLine": True, "yDigits": 2, "note": "Contribución anual en puntos porcentuales del PIB."},
        ],
    }
    simulator = base[["anio", "crecimiento_nominal", "tasa_efectiva", "balance_primario",
                      "sfa_total", "deuda_rezagada", "deuda_pib"]].copy()
    simulator.to_json(DATA_OUT / "debt_simulator.json", orient="records", force_ascii=False)
    from debt_web_assets import enrich_debt_chart
    enrich_debt_chart(charts, debt)
    (DATA_OUT / "project_charts.json").write_text(json.dumps(charts, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def imacec_assets() -> None:
    hist = pd.read_csv(ROOT / "data/processed/imacec_nowcast_history_all_models.csv", parse_dates=["Periodo"])
    projections = pd.read_csv(ROOT / "data/processed/imacec_projection_all_models.csv", parse_dates=["Periodo"])
    new_schema = {"target_key", "observed", "fitted", "model_key"}.issubset(hist.columns)

    for target_key, legacy_col, stem, title in [
        ("total", "imacec", "imacec_total_history", "IMACEC total: efectivo y proyección vigente"),
        ("no_minero", "imacec_nm", "imacec_nonmining_history", "IMACEC no minero: efectivo y proyección vigente"),
    ]:
        if new_schema:
            actual = (hist[(hist["target_key"] == target_key) & (hist["tipo"] == "Efectivo")]
                      [["Periodo", "observed"]].dropna().drop_duplicates("Periodo").sort_values("Periodo"))
        elif legacy_col in hist.columns:
            actual = (hist[["Periodo", legacy_col]].dropna().drop_duplicates("Periodo")
                      .rename(columns={legacy_col: "observed"}).sort_values("Periodo"))
        else:
            actual = pd.DataFrame(columns=["Periodo", "observed"])

        fig, ax = plt.subplots(figsize=(12.6, 6.0))
        if not actual.empty:
            ax.plot(actual["Periodo"], actual["observed"], color=COLORS["navy"],
                    linewidth=2.35, label="IMACEC efectivo")
        if {"target_key", "forecast", "model_key"}.issubset(projections.columns):
            points = projections[projections["target_key"] == target_key]
            for key, color, marker in [("m4", COLORS["terracotta"], "o"), ("m8p", COLORS["teal"], "D")]:
                point = points[points["model_key"] == key]
                if not point.empty:
                    ax.scatter(point["Periodo"], point["forecast"], color=color, marker=marker,
                               s=72, zorder=6, edgecolor="white", linewidth=1.2, label=key.upper())
        ax.axhline(0, color=COLORS["slate"], linewidth=0.9)
        ax.set_ylabel("Variación anual, %")
        if not actual.empty:
            ax.set_xlim(pd.Timestamp("2019-01-01"), actual["Periodo"].max() + pd.offsets.MonthBegin(2))
        ax.xaxis.set_major_locator(mdates.YearLocator(1))
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
        style_ax(ax, title, "El sitio interactivo conserva por separado efectivo, ajuste, nowcast y EEE.")
        ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.13), ncol=3, fontsize=9.2)
        add_source(fig, "Fuente: Banco Central de Chile, INE y elaboración propia.")
        save(fig, stem)


def ipom_assets() -> None:
    d = pd.read_csv(ROOT / "data/processed/ipom/ipom_scenarios_long.csv", parse_dates=["date"])
    d = d[(d["scenario_id"].isin(["baseline_ipom", "tpm45_2026"])) & (d["date"] >= "2024-01-01")]
    scenarios = {
        "baseline_ipom": ("Escenario base", COLORS["navy"], "-"),
        "tpm45_2026": ("TPM 4,5% en 2026", COLORS["terracotta"], "--"),
    }
    variables = {
        "TPM": ("ipom_tpm", "Trayectoria de la TPM", "Tasa anual, %"),
        "D4L_CPI": ("ipom_inflation", "Inflación total", "Variación anual, %"),
        "D4L_CPIXFE": ("ipom_core", "Inflación subyacente sin volátiles", "Variación anual, %"),
        "L_GDP_GAP": ("ipom_output_gap", "Brecha de actividad", "%"),
    }
    for var, (stem, title, ylabel) in variables.items():
        fig, ax = plt.subplots(figsize=(11.8, 5.8))
        for sid, (label, color, ls) in scenarios.items():
            x = d[(d["variable"] == var) & (d["scenario_id"] == sid)].sort_values("date")
            ax.plot(x["date"], x["value"], label=label, color=color, linewidth=2.35, linestyle=ls)
        ax.axvspan(pd.Timestamp("2026-01-01"), pd.Timestamp("2026-12-31"), color=COLORS["gold"], alpha=0.10)
        ax.axhline(0, color=COLORS["slate"], linewidth=0.8)
        ax.set_ylabel(ylabel)
        ax.xaxis.set_major_locator(mdates.YearLocator())
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
        style_ax(ax, title, "Simulación condicional; el escenario alternativo vuelve a la trayectoria base desde 2027.")
        ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=2)
        add_source(fig, "Fuente: outputs procesados del modelo semi-estructural Matlab/IRIS.")
        save(fig, stem)


def transmission_assets() -> None:
    panel = pd.read_csv(ROOT / "data/processed/transmision_tpm/monthly_panel_rates.csv", parse_dates=["date"])
    panel = panel[panel["date"] >= "2014-01-01"]
    fig, ax = plt.subplots(figsize=(12.2, 6.0))
    series = [
        ("tpm", "TPM", COLORS["navy"], 2.4),
        ("comercial_total", "Crédito comercial", COLORS["terracotta"], 1.7),
        ("vivienda_uf", "Vivienda UF >3 años", COLORS["purple"], 1.7),
        ("cap_90_1y", "Captación 90d-1a", COLORS["teal"], 1.7),
    ]
    for col, label, color, lw in series:
        ax.plot(panel["date"], panel[col], label=label, color=color, linewidth=lw)
    ax.set_ylabel("Tasa anual, %")
    ax.xaxis.set_major_locator(mdates.YearLocator(2))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
    style_ax(ax, "TPM y tasas bancarias clave", "Datos mensuales; tasas activas y pasivas responden con velocidades distintas.")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=4, fontsize=9.2)
    add_source(fig, "Fuente: Banco Central de Chile, panel procesado del proyecto.")
    save(fig, "transmission_key_rates")

    cum = pd.read_csv(ROOT / "outputs/tables/transmision_tpm/pass_through_cumulative.csv")
    product_labels = {
        "comercial_total": "Comercial total",
        "consumo_total": "Consumo total",
        "vivienda_uf": "Vivienda UF >3 años",
        "cap_90_1y": "Captación 90d-1a",
        "consumo_tarj_rot": "Tarjeta rotativo",
    }
    pcolors = [COLORS["terracotta"], COLORS["teal"], COLORS["purple"], COLORS["gold"], COLORS["blue"]]
    fig, ax = plt.subplots(figsize=(11.8, 5.8))
    for (prod, label), color in zip(product_labels.items(), pcolors):
        x = cum[cum["product"] == prod].sort_values("horizon")
        ax.plot(x["horizon"], x["cumulative"], marker="o", markersize=4.2, linewidth=2.0,
                label=label, color=color)
    ax.axhline(1, color=COLORS["slate"], linestyle="--", linewidth=1.0)
    ax.set_xlabel("Meses desde el cambio de TPM")
    ax.set_ylabel("Coeficiente acumulado")
    ax.set_xticks(range(0, 7))
    style_ax(ax, "Pass-through acumulado de la TPM", "La referencia en 1 representa un traspaso acumulado uno a uno.")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.13), ncol=3, fontsize=9.0)
    add_source(fig, "Fuente: modelo de rezagos distribuidos del proyecto.")
    save(fig, "transmission_cumulative")

    asym = pd.read_csv(ROOT / "outputs/tables/transmision_tpm/pass_through_asymmetric.csv")
    asym = asym[(asym["horizon"] == 6) & (asym["product"].isin(product_labels))].copy()
    piv = asym.pivot(index="product", columns="type", values="cumulative").reindex(product_labels.keys())
    y = np.arange(len(piv))
    fig, ax = plt.subplots(figsize=(10.8, 5.7))
    ax.barh(y + 0.18, piv["alza_tpm"], height=0.34, color=COLORS["terracotta"], label="Alzas de TPM")
    ax.barh(y - 0.18, piv["baja_tpm"], height=0.34, color=COLORS["teal"], label="Bajas de TPM")
    ax.set_yticks(y, [product_labels[p] for p in piv.index])
    ax.axvline(0, color=COLORS["slate"], linewidth=0.8)
    ax.set_xlabel("Pass-through acumulado a 6 meses")
    style_ax(ax, "Asimetría del traspaso monetario", "Comparación descriptiva entre episodios de alzas y bajas de TPM.", grid="x")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=2)
    add_source(fig, "Fuente: especificación asimétrica del proyecto; interpretación no causal.")
    save(fig, "transmission_asymmetry")

    lp = pd.read_csv(ROOT / "outputs/tables/transmision_tpm/local_projections.csv")
    selected = ["comercial_total", "consumo_total", "vivienda_uf", "cap_90_1y"]
    fig, ax = plt.subplots(figsize=(11.8, 5.8))
    for prod, color in zip(selected, [COLORS["terracotta"], COLORS["teal"], COLORS["purple"], COLORS["gold"]]):
        x = lp[lp["product"] == prod].sort_values("horizon")
        ax.plot(x["horizon"], x["estimate"], color=color, linewidth=2.0, label=product_labels[prod])
        ax.fill_between(x["horizon"].to_numpy(float), x["conf_low"].to_numpy(float), x["conf_high"].to_numpy(float), color=color, alpha=0.10)
    ax.axhline(0, color=COLORS["slate"], linewidth=0.8)
    ax.set_xlabel("Horizonte, meses")
    ax.set_ylabel("Respuesta estimada")
    style_ax(ax, "Respuestas dinámicas por local projections", "Bandas de confianza del 95%; ejercicio agregado y condicional.")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.13), ncol=4, fontsize=9)
    add_source(fig, "Fuente: local projections del proyecto de transmisión monetaria.")
    save(fig, "transmission_local_projections")


def exchange_assets() -> None:
    residuals = pd.read_csv(ROOT / "data/processed/exchange/residuals_long.csv", parse_dates=["date"])
    residuals = residuals[residuals["date"] >= "2018-01-01"].sort_values("date")
    palette = {"CLP": COLORS["terracotta"], "BRL": COLORS["teal"], "MXN": COLORS["sage"], "PEN": COLORS["gold"], "COP": COLORS["blue"]}
    for market, stem, title, ylabel in [
        ("FX", "exchange_fx_residuals", "Desvíos del tipo de cambio respecto del modelo", "Residuo estandarizado FX"),
        ("10Y", "exchange_y10_residuals", "Desvíos de tasas soberanas 10Y respecto del modelo", "Residuo estandarizado 10Y"),
    ]:
        fig, ax = plt.subplots(figsize=(13.4, 5.8))
        for cc in ["CLP", "BRL", "MXN", "PEN", "COP"]:
            x = residuals[(residuals["market"] == market) & (residuals["country"] == cc)]
            ax.plot(x["date"], x["z_score"], color=palette[cc], linewidth=1.25, alpha=0.92, label=cc)
        ax.axhline(0, color=COLORS["slate"], linewidth=0.8)
        ax.axhline(2, color=COLORS["grid"], linestyle="--", linewidth=0.8)
        ax.axhline(-2, color=COLORS["grid"], linestyle="--", linewidth=0.8)
        ax.set_ylabel(ylabel)
        ax.xaxis.set_major_locator(mdates.YearLocator())
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
        style_ax(ax, title, "CLP, BRL, MXN, PEN y COP; valores positivos representan presión por sobre el ajuste del modelo.")
        ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=5)
        add_source(fig, "Fuente: modelos diarios regionales con BIS, FRED, BCCh y EMBIG país.")
        save(fig, stem)

    fit = pd.read_csv(ROOT / "data/processed/exchange/model_fit_summary.csv")
    countries = ["CLP", "BRL", "MXN", "PEN", "COP"]
    x = np.arange(len(countries))
    fx = fit[fit["block"] == "FX"].set_index("country").reindex(countries)
    y10 = fit[fit["block"] == "10Y"].set_index("country").reindex(countries)
    fig, ax = plt.subplots(figsize=(10.8, 5.6))
    width = 0.36
    ax.bar(x - width/2, fx["r2"], width, label="FX", color=COLORS["terracotta"])
    ax.bar(x + width/2, y10["r2"], width, label="10Y", color=COLORS["teal"])
    ax.set_xticks(x, countries)
    ax.set_ylim(0, 1.05)
    ax.set_ylabel("R² de primera etapa")
    style_ax(ax, "Capacidad explicativa de los modelos de primera etapa", "El R² es descriptivo del ajuste dentro de muestra; no equivale a identificación causal.")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=2)
    add_source(fig, "Fuente: model_fit_summary.csv.")
    save(fig, "exchange_model_fit")

    second = pd.read_csv(ROOT / "data/processed/exchange/second_stage_summary.csv")
    second = second.set_index("country").reindex(countries)
    fig, ax = plt.subplots(figsize=(10.8, 5.6))
    bars = ax.bar(countries, second["beta_y10_spread"], color=[palette[c] for c in countries])
    for b, v in zip(bars, second["beta_y10_spread"]):
        ax.text(b.get_x()+b.get_width()/2, b.get_height()+0.012, f"{v:.2f}", ha="center", fontsize=9, color=COLORS["muted"])
    ax.set_ylabel("Coeficiente del spread soberano 10Y")
    style_ax(ax, "Relación entre tensión soberana y residuo cambiario", "Segunda etapa por país; coeficientes positivos y estadísticamente significativos en la muestra.")
    add_source(fig, "Fuente: second_stage_summary.csv.")
    save(fig, "exchange_second_stage")

    # Lightweight JSON for the country selector: weekly observations from 2022 onward.
    dash = pd.read_csv(ROOT / "data/processed/exchange/country_dashboard_data.csv", parse_dates=["date"])
    dash = dash[dash["date"] >= "2022-01-01"].copy()
    dash["week"] = dash["date"].dt.to_period("W-FRI").dt.end_time.dt.normalize()
    dash = (dash.sort_values("date").groupby(["country", "panel", "series", "week"], as_index=False).tail(1)
            .sort_values(["country", "panel", "series", "week"]))
    payload = []
    for row in dash.itertuples(index=False):
        payload.append({"date": row.week.strftime("%Y-%m-%d"), "country": row.country,
                        "panel": row.panel, "series": row.series, "value": None if pd.isna(row.value) else round(float(row.value), 5)})
    (DATA_OUT / "exchange_dashboard.json").write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def yield_curve_assets() -> None:
    d = pd.read_csv(ROOT / "data/processed/transmision_tpm/monthly_panel_rates.csv", parse_dates=["date"])
    latest = d.dropna(subset=["bcp_2y", "bcp_5y", "bcp_10y", "bcu_5y", "bcu_10y"]).iloc[-1]
    fig, ax = plt.subplots(figsize=(9.6, 5.5))
    ax.plot([2, 5, 10], [latest.bcp_2y, latest.bcp_5y, latest.bcp_10y], marker="o", linewidth=2.4,
            color=COLORS["navy"], label="BCP nominal")
    ax.plot([5, 10], [latest.bcu_5y, latest.bcu_10y], marker="o", linewidth=2.4,
            color=COLORS["teal"], label="BCU real")
    ax.set_xticks([2, 5, 10], ["2 años", "5 años", "10 años"])
    ax.set_ylabel("Tasa anual, %")
    style_ax(ax, f"Curva soberana chilena · {latest.date:%B %Y}", "Promedios mensuales de bonos nominales y reajustables en UF.")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=2)
    add_source(fig, "Fuente: Banco Central de Chile, panel mensual procesado.")
    save(fig, "yield_curve_latest")

    d["slope_10_2"] = d["bcp_10y"] - d["bcp_2y"]
    fig, ax = plt.subplots(figsize=(12.0, 5.6))
    x = d.dropna(subset=["slope_10_2"])
    ax.fill_between(x["date"], 0, x["slope_10_2"], where=x["slope_10_2"] >= 0, color=COLORS["teal"], alpha=0.18)
    ax.fill_between(x["date"], 0, x["slope_10_2"], where=x["slope_10_2"] < 0, color=COLORS["terracotta"], alpha=0.18)
    ax.plot(x["date"], x["slope_10_2"], color=COLORS["navy"], linewidth=1.8)
    ax.axhline(0, color=COLORS["slate"], linewidth=0.9)
    ax.set_ylabel("Puntos porcentuales")
    ax.xaxis.set_major_locator(mdates.YearLocator(2))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
    style_ax(ax, "Pendiente de la curva nominal: BCP 10Y menos BCP 2Y", "Valores negativos identifican episodios de inversión de la curva.")
    add_source(fig, "Fuente: Banco Central de Chile, elaboración propia.")
    save(fig, "yield_curve_slope")

    d["be5"] = d["bcp_5y"] - d["bcu_5y"]
    d["be10"] = d["bcp_10y"] - d["bcu_10y"]
    fig, ax = plt.subplots(figsize=(12.0, 5.6))
    ax.plot(d["date"], d["be5"], color=COLORS["terracotta"], linewidth=1.9, label="Compensación 5 años")
    ax.plot(d["date"], d["be10"], color=COLORS["teal"], linewidth=1.9, label="Compensación 10 años")
    ax.set_ylabel("Puntos porcentuales")
    ax.xaxis.set_major_locator(mdates.YearLocator(2))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
    style_ax(ax, "Compensación inflacionaria aproximada", "Diferencia entre tasas nominales BCP y reales BCU; incorpora primas de riesgo y liquidez.")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=2)
    add_source(fig, "Fuente: Banco Central de Chile, elaboración propia.")
    save(fig, "yield_curve_breakeven")

    curve = d[["date", "bcp_2y", "bcp_5y", "bcp_10y", "bcu_5y", "bcu_10y"]].dropna().copy()
    curve = curve[curve["date"] >= "2010-01-01"]
    payload = []
    for row in curve.itertuples(index=False):
        payload.append({"date": row.date.strftime("%Y-%m-%d"), "nominal": [round(row.bcp_2y, 4), round(row.bcp_5y, 4), round(row.bcp_10y, 4)],
                        "real": [None, round(row.bcu_5y, 4), round(row.bcu_10y, 4)]})
    (DATA_OUT / "yield_curve.json").write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def project_thumbnails() -> None:
    # Use already generated charts as stable thumbnails; the build copies both formats.
    dashboard = ROOT / "site" / "assets" / "dashboards" / "atlas-metropolitano.html"
    if dashboard.exists():
        sae_line = next(line for line in dashboard.read_text(encoding="utf-8").splitlines() if line.startswith("const SAE = "))
        sae = pd.DataFrame(json.loads(sae_line.removeprefix("const SAE = ").removesuffix(";")))
        atlas = sae[(sae["d"] == "income") & (sae["y"] == 2024)].nlargest(12, "v").sort_values("v")
        fig, ax = plt.subplots(figsize=(12.0, 6.75))
        ax.barh(atlas["n"].str.title(), atlas["v"] * 100, color=COLORS["terracotta"], alpha=.9)
        ax.set_xlabel("Porcentaje de la población")
        style_ax(ax, "Pobreza por ingresos SAE · 2024", "Comunas con mayor estimación puntual en la Región Metropolitana.")
        add_source(fig, "Fuente: Ministerio de Desarrollo Social y Familia, estimaciones SAE comunales.")
        fig.tight_layout(pad=1.8)
        fig.savefig(OUT / "atlas_poverty_2024.png", dpi=160, bbox_inches="tight")
        plt.close(fig)
    mapping = {
        "imacec": "imacec_total_history.png",
        "ipom": "ipom_tpm.png",
        "transmission": "transmission_cumulative.png",
        "debt": "debt_trajectories.png",
        "exchange": "exchange_fx_residuals.png",
        "yield": "yield_curve_latest.png",
        "atlas": "atlas_poverty_2024.png",
    }
    thumbs = ROOT / "site" / "assets" / "img" / "projects"
    thumbs.mkdir(parents=True, exist_ok=True)
    from PIL import Image, ImageEnhance
    for name, src in mapping.items():
        img = Image.open(OUT / src).convert("RGB")
        w, h = img.size
        target_ratio = 16 / 9
        ratio = w / h
        if ratio > target_ratio:
            new_w = int(h * target_ratio)
            left = (w - new_w) // 2
            img = img.crop((left, 0, left + new_w, h))
        else:
            new_h = int(w / target_ratio)
            top = max(0, (h - new_h) // 2)
            img = img.crop((0, top, w, top + new_h))
        img = img.resize((1280, 720))
        img = ImageEnhance.Contrast(img).enhance(1.02)
        img.save(thumbs / f"{name}.jpg", quality=88, optimize=True)


def main() -> None:
    imacec_assets()
    ipom_assets()
    transmission_assets()
    exchange_assets()
    yield_curve_assets()
    interactive_assets()
    project_thumbnails()
    print(f"Generated site assets in {OUT}")


if __name__ == "__main__":
    main()
