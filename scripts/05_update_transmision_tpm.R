# ============================================================
# Actualiza proyecto: transmisión de TPM a tasas de mercado
# ============================================================
# Ejecutar desde la raíz del sitio Economics:
# source("scripts/05_update_transmision_tpm.R")
# o bien:
# Rscript scripts/05_update_transmision_tpm.R

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (basename(root) == "scripts") {
  root <- normalizePath(file.path(root, ".."), winslash = "/", mustWork = TRUE)
}
setwd(root)

source("R/transmision_tpm/00_setup.R")
source("R/transmision_tpm/01_config.R")
source("R/transmision_tpm/02_fetch_bde.R")
source("R/transmision_tpm/03_series_dictionary.R")
source("R/transmision_tpm/04_build_monthly_data.R")
source("R/transmision_tpm/05_models_dlm.R")
source("R/transmision_tpm/06_models_local_projections.R")
source("R/transmision_tpm/07_ecb_credit_conditions.R")
source("R/transmision_tpm/08_figures.R")
source("R/transmision_tpm/09_tables.R")

message("\n== Proyecto transmisión TPM ==")
message("Rango de descarga: ", cfg$first_date, " a ", cfg$last_date)

message("1) Descargando series BDE...")
raw_fetch <- fetch_bde_many(
  series_tbl = series_dictionary,
  first_date = cfg$first_date,
  last_date = cfg$last_date,
  stop_if_required_missing = FALSE
)

readr::write_csv(raw_fetch$data, file.path(cfg$raw_dir, "bde_rates_raw.csv"))
readr::write_csv(raw_fetch$log, file.path(cfg$metadata_dir, "fetch_log.csv"))
readr::write_csv(series_dictionary, file.path(cfg$metadata_dir, "series_dictionary.csv"))

message("2) Construyendo base mensual...")
monthly_panel <- build_monthly_panel(raw_fetch$data, series_dictionary)
readr::write_csv(monthly_panel, file.path(cfg$processed_dir, "monthly_panel_rates.csv"))

model_data <- make_model_data(monthly_panel)
readr::write_csv(model_data, file.path(cfg$processed_dir, "model_data_pass_through.csv"))

message("3) Estimando rezagos distribuidos...")
# Modelo principal corregido: macro controls, sin curva BCP/BCU como bad controls.
dlm_models <- estimate_all_dlm(model_data, k = cfg$dlm_lags, asymmetric = FALSE, spec = "macro")
pt_tbl <- purrr::map_dfr(dlm_models, ~ extract_cumulative_pt(.x, k = cfg$dlm_lags, asymmetric = FALSE))
readr::write_csv(pt_tbl, file.path(cfg$tables_dir, "pass_through_cumulative.csv"))

# Especificaciones de comparación: base puro y robustez con curva.
dlm_models_base <- estimate_all_dlm(model_data, k = cfg$dlm_lags, asymmetric = FALSE, spec = "base")
pt_tbl_base <- purrr::map_dfr(dlm_models_base, ~ extract_cumulative_pt(.x, k = cfg$dlm_lags, asymmetric = FALSE))
readr::write_csv(pt_tbl_base, file.path(cfg$tables_dir, "pass_through_cumulative_base.csv"))

dlm_models_curve <- estimate_all_dlm(model_data, k = cfg$dlm_lags, asymmetric = FALSE, spec = "curve")
pt_tbl_curve <- purrr::map_dfr(dlm_models_curve, ~ extract_cumulative_pt(.x, k = cfg$dlm_lags, asymmetric = FALSE))
readr::write_csv(pt_tbl_curve, file.path(cfg$tables_dir, "pass_through_cumulative_curve_robustness.csv"))

message("4) Estimando modelos asimétricos...")
dlm_models_asym <- estimate_all_dlm(model_data, k = cfg$dlm_lags, asymmetric = TRUE, spec = "macro")
pt_asym_tbl <- purrr::map_dfr(dlm_models_asym, ~ extract_cumulative_pt(.x, k = cfg$dlm_lags, asymmetric = TRUE))
readr::write_csv(pt_asym_tbl, file.path(cfg$tables_dir, "pass_through_asymmetric.csv"))

message("5) Estimando local projections...")
lp_tbl <- estimate_all_lp(model_data, h_max = cfg$lp_hmax, shock_var = "dtpm", spec = "macro")
readr::write_csv(lp_tbl, file.path(cfg$tables_dir, "local_projections.csv"))

lp_tbl_base <- estimate_all_lp(model_data, h_max = cfg$lp_hmax, shock_var = "dtpm", spec = "base")
readr::write_csv(lp_tbl_base, file.path(cfg$tables_dir, "local_projections_base.csv"))

message("6) Tablas resumen y robustez...")
summary_tbl <- make_pass_through_summary(pt_tbl, horizons = c(1, 3, 6))
readr::write_csv(summary_tbl, file.path(cfg$tables_dir, "pass_through_summary.csv"))

rob_tbl <- estimate_sample_robustness(model_data, k = cfg$dlm_lags)
readr::write_csv(rob_tbl, file.path(cfg$tables_dir, "robustness_samples.csv"))

message("7) Búsqueda de candidatos ECB en catálogo BDE...")
ecb_candidates <- discover_ecb_candidates(save = TRUE)

message("8) Generando figuras estáticas para respaldo...")
p_rates <- plot_rates_tpm(monthly_panel)
p_pt <- plot_cumulative_pt(pt_tbl)
p_asym <- plot_asymmetric_pt(pt_asym_tbl)
p_lp <- plot_lp_irf(lp_tbl)

ggplot2::ggsave(file.path(cfg$figures_dir, "fig_rates_tpm.png"), p_rates, width = 9, height = 5, dpi = 300)
ggplot2::ggsave(file.path(cfg$figures_dir, "fig_pass_through_cumulative.png"), p_pt, width = 9, height = 5, dpi = 300)
ggplot2::ggsave(file.path(cfg$figures_dir, "fig_pass_through_asymmetric.png"), p_asym, width = 10, height = 7, dpi = 300)
ggplot2::ggsave(file.path(cfg$figures_dir, "fig_local_projections.png"), p_lp, width = 11, height = 8, dpi = 300)

saveRDS(
  list(dlm = dlm_models, dlm_base = dlm_models_base, dlm_curve = dlm_models_curve, dlm_asym = dlm_models_asym, lp = lp_tbl, lp_base = lp_tbl_base),
  file.path(cfg$model_dir, "models.rds")
)

message("\nActualización finalizada.")
message("Archivos exportados en:")
message("- ", cfg$processed_dir)
message("- ", cfg$tables_dir)
message("- ", cfg$figures_dir)
message("\nAhora ejecuta:")
message("python scripts/build_site.py")
message("python scripts/validate_site.py")
