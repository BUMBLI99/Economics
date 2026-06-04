args <- commandArgs(trailingOnly = TRUE)
repo <- if (length(args) >= 1) args[[1]] else getwd()
repo <- normalizePath(repo, winslash = "/", mustWork = TRUE)
setwd(repo)

renv <- file.path(repo, ".Renviron")
if (file.exists(renv)) {
  readRenviron(renv)
}

required <- c(
  "rmarkdown", "knitr", "rjson", "httr", "jsonlite", "dplyr",
  "lubridate", "tidyr", "zoo", "tibble", "ggplot2", "purrr", "modelsummary"
)
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  message("Instalando paquetes faltantes: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org")
}

needed_env <- c("BCCH_USER", "BCCH_PASS", "FRED_API_KEY")
missing_env <- needed_env[!nzchar(Sys.getenv(needed_env))]
if (length(missing_env) > 0) {
  stop(
    "Faltan variables en .Renviron o en el entorno: ",
    paste(missing_env, collapse = ", "),
    "\nCopia .Renviron.example como .Renviron, completa tus claves y vuelve a ejecutar."
  )
}

input <- file.path(repo, "modelos", "exchange", "Exchange_CPI_BIS.Rmd")
out_dir <- file.path(repo, "modelos", "exchange")

if (!file.exists(input)) {
  stop("No existe el modelo: ", input)
}

message("Renderizando modelo Exchange con CPI BIS...")
rmarkdown::render(
  input = input,
  output_format = "pdf_document",
  output_file = "exchange_report.pdf",
  output_dir = out_dir,
  clean = TRUE,
  quiet = FALSE,
  envir = new.env(parent = globalenv())
)

message("Modelo renderizado: ", file.path(out_dir, "exchange_report.pdf"))
