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
               dash: str = "") -> dict:
    """Compact, null-safe series consumed by the dependency-free web charts."""
    clean = frame[[date, value]].dropna().sort_values(date)
    return {
        "name": name, "color": color, "dash": dash,
        "values": [{"date": pd.Timestamp(d).strftime("%Y-%m-%d"), "value": round(float(v), 5)}
                   for d, v in clean.itertuples(index=False, name=None)],
    }


def interactive_assets() -> None:
    """Build a coherent interactive explorer for every published project."""
    charts: dict[str, dict] = {}
    hist = pd.read_csv(ROOT / "data/processed/imacec_nowcast_history_all_models.csv", parse_dates=["Periodo"])
    hist = hist[hist["Periodo"] >= "2019-01-01"]
    imacec_sets = []
    for ident, label, actual_col, fit_col in [("total", "IMACEC total", "imacec", "imacec_fit"), ("nonmining", "IMACEC no minero", "imacec_nm", "imacec_nm_fit")]:
        actual = hist[["Periodo", actual_col]].drop_duplicates("Periodo")
        series = [web_series("Efectivo", COLORS["navy"], actual, "Periodo", actual_col)]
        for key, name, color, dash in [("base", "Modelo experimental", COLORS["terracotta"], "7 5"), ("ine", "Modelo sectorial INE", COLORS["teal"], "3 4")]:
            block = hist[(hist["model_key"] == key) & (hist["tipo"].isin(["Histórico", "Nowcast"]))]
            series.append(web_series(name, color, block, "Periodo", fit_col, dash))
        imacec_sets.append({"id": ident, "label": label, "series": series, "zeroLine": True, "yDigits": 1})
    charts["imacec"] = {"ariaLabel": "Evolución interactiva del IMACEC", "datasets": imacec_sets}

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

    stress = pd.read_csv(ROOT / "data/processed/estres_financiero/stress_index_chile.csv", parse_dates=["date"])
    stress = stress[stress["date"] >= "2013-01-01"].set_index("date").resample("W-FRI").last().reset_index()
    charts["stress"] = {"ariaLabel": "Índice interactivo de estrés financiero", "datasets": [{"id": "index", "label": "Índice agregado", "zeroLine": True, "yDigits": 2, "series": [web_series("Índice (cierre semanal)", COLORS["blue"], stress, "date", "stress_market"), web_series("Media móvil 30 días", COLORS["navy"], stress, "date", "stress_market_30d")]}, {"id": "components", "label": "Componentes", "zeroLine": True, "yDigits": 2, "series": [web_series("Componente FX", COLORS["terracotta"], stress, "date", "stress_fx_30d"), web_series("Componente tasa 10Y", COLORS["teal"], stress, "date", "stress_y10_30d")]}]}
    (DATA_OUT / "project_charts.json").write_text(json.dumps(charts, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def imacec_assets() -> None:
    hist = pd.read_csv(ROOT / "data/processed/imacec_nowcast_history_all_models.csv", parse_dates=["Periodo"])
    status = pd.read_csv(ROOT / "data/processed/imacec_update_status.csv")
    oos = pd.read_csv(ROOT / "data/processed/imacec_pseudo_oos_metrics.csv")

    target = pd.to_datetime(status.loc[0, "periodo_objetivo"])
    active_key = "base" if status.loc[0, "modelo"] == "Modelo con estadísticas experimentales" else "ine"

    def history_plot(variable: str, fit_col: str, stem: str, title: str) -> None:
        fig, ax = plt.subplots(figsize=(12.6, 6.0))
        # Actual observations are duplicated across model rows; deduplicate explicitly.
        actual = hist[["Periodo", variable]].dropna().drop_duplicates("Periodo").sort_values("Periodo")
        ax.plot(actual["Periodo"], actual[variable], color=COLORS["navy"], linewidth=2.25,
                label="Efectivo")
        for key, label, color, ls in [
            ("base", "Ajuste: estadísticas experimentales", COLORS["terracotta"], "--"),
            ("ine", "Ajuste: indicadores sectoriales INE", COLORS["teal"], ":"),
        ]:
            d = hist[(hist["model_key"] == key) & (hist["tipo"] == "Histórico")].sort_values("Periodo")
            ax.plot(d["Periodo"], d[fit_col], color=color, linewidth=1.55, linestyle=ls, label=label)
        # Only publish the forecast that was actually available at the current vintage.
        now = hist[(hist["model_key"] == active_key) & (hist["tipo"] == "Nowcast")].sort_values("Periodo")
        now = now[now["Periodo"] == target]
        if not now.empty:
            y = now[fit_col].iloc[-1]
            ax.scatter(now["Periodo"], [y], s=82, color=COLORS["terracotta"], zorder=7,
                       edgecolor="white", linewidth=1.4, label="Nowcast vigente")
            ax.annotate(f"{y:.1f}%", (now["Periodo"].iloc[-1], y), xytext=(10, 10),
                        textcoords="offset points", color=COLORS["terracotta"], fontweight="bold")
        ax.axhline(0, color=COLORS["slate"], linewidth=0.9)
        ax.set_ylabel("Variación anual, %")
        ax.set_xlim(pd.Timestamp("2019-01-01"), target + pd.offsets.MonthBegin(2))
        ax.xaxis.set_major_locator(mdates.YearLocator(1))
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
        style_ax(ax, title, "La proyección sectorial INE solo aparece cuando los indicadores requeridos están disponibles.")
        ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.13), ncol=2, fontsize=9.2)
        add_source(fig, "Fuente: elaboración propia con datos procesados del proyecto IMACEC.")
        save(fig, stem)

    history_plot("imacec", "imacec_fit", "imacec_total_history", "IMACEC total: efectivo, ajuste y nowcast vigente")
    history_plot("imacec_nm", "imacec_nm_fit", "imacec_nonmining_history", "IMACEC no minero: efectivo, ajuste y nowcast vigente")

    order = ["Modelo con indicadores sectoriales INE", "Modelo con estadísticas experimentales",
             "Benchmark AR(1)", "Promedio móvil 3m", "Naive estacional t-12"]
    labels = {
        "Modelo con indicadores sectoriales INE": "Modelo sectorial INE",
        "Modelo con estadísticas experimentales": "Modelo experimental",
        "Benchmark AR(1)": "AR(1)",
        "Promedio móvil 3m": "Promedio móvil 3m",
        "Naive estacional t-12": "Naive estacional",
    }
    fig, axes = plt.subplots(1, 2, figsize=(13.0, 5.7), sharex=True)
    for ax, variable in zip(axes, ["IMACEC total", "IMACEC no minero"]):
        d = oos[oos["variable"] == variable].copy()
        d["modelo"] = pd.Categorical(d["modelo"], categories=order, ordered=True)
        d = d.sort_values("modelo", ascending=False)
        colors = [COLORS["teal"] if "INE" in str(x) else COLORS["terracotta"] if "experimentales" in str(x) else COLORS["slate"] for x in d["modelo"]]
        bars = ax.barh([labels[str(x)] for x in d["modelo"]], d["RMSE"], color=colors, alpha=0.94)
        for b, rmse, n in zip(bars, d["RMSE"], d["N"]):
            ax.text(b.get_width() + 0.12, b.get_y() + b.get_height()/2, f"{rmse:.2f} · n={int(n)}",
                    va="center", fontsize=8.6, color=COLORS["muted"])
        ax.set_title(variable, loc="left", color=COLORS["ink"], fontsize=14, fontweight="bold")
        ax.grid(axis="x")
        ax.spines[["top", "right", "left"]].set_visible(False)
        ax.set_xlabel("RMSE pseudo out-of-sample")
    fig.suptitle("Evaluación pseudo out-of-sample desde 2021", x=0.035, ha="left", fontsize=18,
                 fontweight="bold", color=COLORS["ink"])
    fig.text(0.035, 0.91, "Las muestras efectivas difieren porque cada bloque de información comienza en una fecha distinta.",
             ha="left", fontsize=10.5, color=COLORS["muted"])
    add_source(fig, "Fuente: imacec_pseudo_oos_metrics.csv. Menor RMSE indica mejor precisión.")
    save(fig, "imacec_oos_rmse")


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


def financial_stress_assets() -> None:
    d = pd.read_csv(ROOT / "data/processed/estres_financiero/stress_index_chile.csv", parse_dates=["date"])
    d = d[d["date"] >= "2013-01-01"].sort_values("date")
    fig, ax = plt.subplots(figsize=(13.2, 5.8))
    ax.plot(d["date"], d["stress_market"], color=COLORS["blue"], alpha=0.22, linewidth=0.8, label="Índice diario")
    ax.plot(d["date"], d["stress_market_30d"], color=COLORS["navy"], linewidth=2.25, label="Media móvil 30 días")
    ax.axhspan(1.5, max(3.5, float(d["stress_market_30d"].max()) + 0.2), color=COLORS["terracotta"], alpha=0.06)
    ax.axhspan(0.75, 1.5, color=COLORS["gold"], alpha=0.07)
    for v in [0, 0.75, 1.5]:
        ax.axhline(v, color=COLORS["slate"], linestyle="--" if v else "-", linewidth=0.8)
    ax.set_ylabel("Z-score agregado")
    ax.xaxis.set_major_locator(mdates.YearLocator(2))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
    style_ax(ax, "Índice de estrés financiero de mercado para Chile", "Promedio de residuos estandarizados de USD/CLP y tasa soberana 10Y.")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=2)
    add_source(fig, "Fuente: modelo diario del proyecto de estrés financiero.")
    save(fig, "stress_index_chile")

    fig, ax = plt.subplots(figsize=(13.2, 5.8))
    ax.plot(d["date"], d["stress_fx_30d"], color=COLORS["terracotta"], linewidth=1.9, label="Componente FX")
    ax.plot(d["date"], d["stress_y10_30d"], color=COLORS["teal"], linewidth=1.9, label="Componente tasa 10Y")
    ax.axhline(0, color=COLORS["slate"], linewidth=0.8)
    ax.set_ylabel("Z-score, media móvil 30 días")
    ax.xaxis.set_major_locator(mdates.YearLocator(2))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
    style_ax(ax, "Componentes del índice de estrés", "Valores positivos indican presión superior a la explicada por los factores externos del modelo.")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=2)
    add_source(fig, "Fuente: residuos de primera etapa del proyecto.")
    save(fig, "stress_components_chile")

    market = d[d["date"] >= "2018-01-01"].copy().sort_values("date")
    for actual, fitted, stem, title, ylabel in [
        ("clp", "fitted_clp", "stress_fx_fit", "USD/CLP: efectivo y valor ajustado", "Pesos por dólar"),
        ("y10_clp", "fitted_y10_clp", "stress_y10_fit", "Tasa soberana 10Y: efectiva y ajustada", "Tasa, %"),
    ]:
        fig, ax = plt.subplots(figsize=(12.6, 5.6))
        ax.plot(market["date"], market[actual], color=COLORS["navy"], linewidth=1.75, label="Efectivo")
        ax.plot(market["date"], market[fitted], color=COLORS["terracotta"], linewidth=1.55, linestyle="--", label="Ajustado")
        ax.set_ylabel(ylabel)
        ax.xaxis.set_major_locator(mdates.YearLocator())
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
        style_ax(ax, title, "El residuo mide la desviación respecto de fundamentos globales observables.")
        ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.12), ncol=2)
        add_source(fig, "Fuente: modelo diario del proyecto de estrés financiero.")
        save(fig, stem)


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
        "stress": "stress_index_chile.png",
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
    financial_stress_assets()
    exchange_assets()
    yield_curve_assets()
    interactive_assets()
    project_thumbnails()
    print(f"Generated site assets in {OUT}")


if __name__ == "__main__":
    main()
