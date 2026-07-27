# ============================================================
# 02_render_site.R
# Renderiza SOLO el sitio Quarto público definido en _quarto.yml
# ============================================================

if (!requireNamespace("quarto", quietly = TRUE)) {
  stop("Falta el paquete quarto. Instala con: install.packages('quarto')")
}

required_public_files <- c(
  "index.qmd",
  "proyectos.qmd",
  "cv.qmd",
  "contacto.qmd",
  "proyectos/imacec.qmd",
  "proyectos/ipom-iris.qmd",
  "proyectos/transmision-tpm.qmd",
  "proyectos/estres-externo.qmd",
  "proyectos/curva-rendimiento.qmd",
  "proyectos/exchange.qmd"
)

missing <- required_public_files[!file.exists(required_public_files)]
if (length(missing) > 0) {
  stop("Faltan archivos públicos requeridos:\n", paste("-", missing, collapse = "\n"), call. = FALSE)
}

quarto::quarto_render(execute = TRUE)

forbidden <- c(
  "docs/matlab/ipom/src/r/archive_exploratory/Data_IPOM_exploratory.html",
  "docs/matlab/ipom/src/r/estimaciones_macro_ipom_tablas.html",
  "docs/modelos/exchange/Exchange_CPI_BIS.html"
)
forbidden_found <- forbidden[file.exists(forbidden)]
if (length(forbidden_found) > 0) {
  stop(
    "Quedaron HTML internos en docs/. Esto no debería pasar:\n",
    paste("-", forbidden_found, collapse = "\n"),
    call. = FALSE
  )
}
