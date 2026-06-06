# ============================================================
# Configuración del proyecto IPoM / IRIS-Matlab
# ============================================================

ipom_variables <- tibble::tribble(
  ~variable,              ~label,                                      ~unit,                 ~block,
  "D4L_CPI",              "Inflación total",                          "% anual",             "Inflación",
  "D4L_CPIXFE",           "Inflación subyacente sin volátiles",        "% anual",             "Inflación",
  "DLA_CPI",              "Inflación total trimestral anualizada",     "% t/t anualizado",    "Inflación",
  "DLA_CPIXFE",           "Inflación subyacente trimestral anualizada", "% t/t anualizado",    "Inflación",
  "DLA_CPIRES",           "Inflación residual trimestral anualizada",  "% t/t anualizado",    "Inflación",
  "D4L_CPI_GAP_XFE",      "Brecha inflación total-subyacente",         "pp",                  "Inflación",
  "TPM",                  "Tasa de Política Monetaria",               "% anual",             "Política monetaria",
  "TPMN1",                "Tasa neutral nominal",                     "% anual",             "Política monetaria",
  "T_COLOC",              "Tasa de colocación UF",                    "% anual",             "Política monetaria",
  "L_GDP_GAP",            "Brecha de actividad",                      "%",                   "Actividad",
  "D4L_GDP",              "PIB: crecimiento anual",                   "% anual",             "Actividad",
  "DLA_GDP",              "PIB: crecimiento trimestral anualizado",    "% t/t anualizado",    "Actividad",
  "CRECSC",               "Crecimiento socios comerciales",           "% anual",             "Bloque externo",
  "L_Z",                  "Tipo de cambio real",                      "100*log",             "Bloque externo",
  "L_Z_INDEX",            "Tipo de cambio real índice",               "índice",              "Bloque externo",
  "L_Z_GAP",              "Brecha de tipo de cambio real",            "%",                   "Bloque externo",
  "L_WTI",                "WTI real",                                 "100*log",             "Bloque externo",
  "L_PCU",                "Cobre real",                               "100*log",             "Bloque externo",
  "L_WTI_NOM",            "WTI nominal",                              "nivel aproximado",    "Bloque externo",
  "L_PCU_NOM",            "Cobre nominal",                            "nivel aproximado",    "Bloque externo",
  "D4L_WTI",              "WTI: variación anual",                     "% anual",             "Bloque externo",
  "D4L_PCU",              "Cobre: variación anual",                   "% anual",             "Bloque externo",
  "VIX",                  "VIX",                                      "índice",              "Bloque externo",
  "FFR",                  "Federal Funds Rate",                       "% anual",             "Bloque externo",
  "UST10",                "Treasury 10 años",                         "% anual",             "Bloque externo",
  "SHK_CRECSC",           "Shock socios comerciales",                 "desvío",              "Shocks",
  "SHK_DLA_CPI",          "Shock inflación total",                    "desvío",              "Shocks",
  "SHK_DLA_CPIRES",       "Shock inflación residual",                 "desvío",              "Shocks",
  "SHK_DLA_CPIXFE",       "Shock inflación subyacente",               "desvío",              "Shocks",
  "SHK_L_GDP_GAP",        "Shock brecha de actividad",                "desvío",              "Shocks",
  "SHK_TPM",              "Shock TPM",                                "desvío",              "Shocks",
  "SHK_L_WTI",            "Shock WTI",                                "desvío",              "Shocks",
  "SHK_L_PCU",            "Shock cobre",                              "desvío",              "Shocks",
  "SHK_VIX",              "Shock VIX",                                "desvío",              "Shocks",
  "SHK_FFR",              "Shock FFR",                                "desvío",              "Shocks",
  "SHK_UST10",            "Shock UST10",                              "desvío",              "Shocks",
  "SHK_L_Z",              "Shock TCR",                                "desvío",              "Shocks"
)

ipom_scenarios <- tibble::tribble(
  ~source_file,                  ~scenario_id,      ~scenario,                                                   ~scenario_order, ~main_public,
  "fcast_ipom_exact.csv",        "baseline_ipom",   "Escenario base IPoM identificado",                         1, TRUE,
  "fcast_alt_tpm45_2026.csv",    "tpm45_2026",      "TPM 4,5% durante 2026 y retorno a IPoM desde 2027",        2, TRUE,
  "fcast_alt_petroleo_gap.csv",  "petroleo_gap",    "Escenario petróleo/brecha",                                3, FALSE
)

ipom_core_variables <- c(
  "D4L_CPI", "D4L_CPIXFE", "D4L_CPI_GAP_XFE",
  "TPM", "L_GDP_GAP", "L_Z_INDEX",
  "L_WTI_NOM", "L_PCU_NOM", "VIX", "FFR", "UST10", "CRECSC"
)

ipom_external_variables <- c(
  "L_WTI_NOM", "L_PCU_NOM", "VIX", "FFR", "UST10", "CRECSC", "L_Z_INDEX"
)
