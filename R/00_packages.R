# ============================================================
# 00_packages.R
# Paquetes requeridos para el proyecto IMACEC
# ============================================================

required_packages <- c(
  "rjson", "dplyr", "tidyr", "lubridate", "readxl", "ggplot2",
  "knitr", "tibble", "readr", "purrr", "stringr", "scales",
  "gt", "plotly", "httr", "jsonlite"
)

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop(
    "Faltan paquetes requeridos: ", paste(missing_packages, collapse = ", "),
    "\nInstálalos con: install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "), "))"
  )
}

suppressPackageStartupMessages({
  library(rjson)
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(readxl)
  library(ggplot2)
  library(knitr)
  library(tibble)
  library(readr)
  library(purrr)
  library(stringr)
  library(scales)
  library(gt)
  library(plotly)
  library(httr)
  library(jsonlite)
})
