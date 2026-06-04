# Backward-compatible wrapper.
# Antes este archivo intentaba renderizar un PDF con rmarkdown. Ahora el flujo
# principal genera outputs web (CSV + graficos) sin depender de Pandoc.

args <- commandArgs(trailingOnly = TRUE)
repo <- if (length(args) >= 1) args[[1]] else getwd()
repo <- normalizePath(repo, winslash = "/", mustWork = TRUE)

source(file.path(repo, "scripts", "exchange", "build_exchange_outputs.R"), local = TRUE)
