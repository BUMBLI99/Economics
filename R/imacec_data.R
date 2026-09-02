# ============================================================
# imacec_data.R
# Descarga y construcción de la base con dos cortes informativos
# ============================================================

fetch_series_optional <- function(code, var_name = NULL) {
  tryCatch(
    fetch_series(code),
    error = function(e) {
      warning("No se pudo descargar ", var_name %||% code, ": ", conditionMessage(e), call. = FALSE)
      tibble::tibble(date = as.Date(character()), value = numeric())
    }
  )
}

monthly_series <- function(code, name, transform = identity) {
  fetch_series(code) |>
    dplyr::mutate(Periodo = lubridate::floor_date(date, "month")) |>
    dplyr::group_by(Periodo) |>
    dplyr::summarise(value = dplyr::last(value), .groups = "drop") |>
    dplyr::arrange(Periodo) |>
    dplyr::mutate(value = transform(value)) |>
    dplyr::rename(!!name := value)
}

get_eee_expectations <- function() {
  series <- list(
    eee_imacec = codes$eee_imacec,
    eee_imacec_nm = codes$eee_imacec_nm
  )
  raw <- purrr::imap_dfr(series, function(code, name) {
    fetch_series_optional(code, name) |>
      dplyr::mutate(variable = name)
  })
  if (!nrow(raw)) {
    return(tibble::tibble(
      survey_period = as.Date(character()), Periodo = as.Date(character()),
      eee_imacec = numeric(), eee_imacec_nm = numeric()
    ))
  }

  out <- raw |>
    dplyr::filter(!is.na(date), !is.na(value)) |>
    dplyr::mutate(
      survey_period = lubridate::floor_date(date, "month"),
      # La EEE publicada en M pregunta por el IMACEC de M-1.
      Periodo = survey_period %m-% lubridate::period(months = 1)
    ) |>
    dplyr::group_by(variable, survey_period, Periodo) |>
    dplyr::summarise(value = dplyr::last(value), .groups = "drop") |>
    tidyr::pivot_wider(names_from = variable, values_from = value) |>
    dplyr::arrange(Periodo)
  if (!"eee_imacec" %in% names(out)) out$eee_imacec <- NA_real_
  if (!"eee_imacec_nm" %in% names(out)) out$eee_imacec_nm <- NA_real_
  out
}

get_uf_monthly <- function() {
  fetch_series(codes$uf_diaria) |>
    dplyr::mutate(Periodo = lubridate::floor_date(date, "month")) |>
    dplyr::group_by(Periodo) |>
    dplyr::slice_max(date, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::transmute(Periodo, uf_nivel = value)
}

normalize_ivs_text <- function(x) {
  x <- iconv(tolower(trimws(as.character(x))), from = "", to = "ASCII//TRANSLIT")
  gsub("[^a-z0-9]+", " ", x)
}

parse_ivs_number <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  x <- trimws(as.character(x))
  x[x %in% c("", "-", "..", "...")] <- NA_character_
  both <- grepl(",", x, fixed = TRUE) & grepl(".", x, fixed = TRUE)
  x[both] <- gsub(".", "", x[both], fixed = TRUE)
  x <- gsub(",", ".", x, fixed = TRUE)
  suppressWarnings(as.numeric(x))
}

parse_ivs_period <- function(x) {
  if (inherits(x, "Date")) return(lubridate::floor_date(as.Date(x), "month"))
  if (inherits(x, "POSIXt")) return(lubridate::floor_date(as.Date(x), "month"))

  raw <- as.character(x)
  num <- suppressWarnings(as.numeric(raw))
  out <- as.Date(rep(NA_character_, length(raw)))
  excel <- !is.na(num) & num > 20000 & num < 80000
  out[excel] <- as.Date(num[excel], origin = "1899-12-30")

  z <- normalize_ivs_text(raw)
  months_es <- c(
    ene = "01", enero = "01", feb = "02", febrero = "02", mar = "03", marzo = "03",
    abr = "04", abril = "04", may = "05", mayo = "05", jun = "06", junio = "06",
    jul = "07", julio = "07", ago = "08", agosto = "08", sep = "09", sept = "09",
    septiembre = "09", oct = "10", octubre = "10", nov = "11", noviembre = "11",
    dic = "12", diciembre = "12"
  )
  for (i in which(is.na(out))) {
    parts <- unlist(strsplit(z[i], " "))
    parts <- parts[nzchar(parts)]
    year_part <- parts[grepl("^[0-9]{2,4}$", parts)]
    month_part <- parts[parts %in% names(months_es)]
    if (length(year_part) && length(month_part)) {
      yy <- as.integer(year_part[length(year_part)])
      if (yy < 100) yy <- 2000 + yy
      out[i] <- as.Date(sprintf("%04d-%s-01", yy, months_es[[month_part[1]]]))
    } else {
      out[i] <- suppressWarnings(lubridate::floor_date(lubridate::ymd(raw[i]), "month"))
    }
  }
  lubridate::floor_date(out, "month")
}

download_ivs_file <- function(url, destination = ivs_path) {
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  response <- httr::GET(url, httr::timeout(90), httr::user_agent("Economics-IMACEC/2.0"))
  httr::stop_for_status(response)
  writeBin(httr::content(response, as = "raw"), destination)
  if (file.info(destination)$size < 10000) stop("El archivo IVS descargado no parece un Excel válido.")
  destination
}

find_ivs_url <- function() {
  if (nzchar(ivs_url)) return(ivs_url)
  response <- httr::GET(ivs_page, httr::timeout(60), httr::user_agent("Economics-IMACEC/2.0"))
  httr::stop_for_status(response)
  page <- httr::content(response, as = "text", encoding = "UTF-8")
  links <- stringr::str_extract_all(page, "https?://[^\\\"' ]+\\.xlsx(?:\\?[^\\\"' ]*)?")[[1]]
  links <- unique(gsub("&amp;", "&", links, fixed = TRUE))
  preferred <- links[grepl("serie|mensual|servicio|ivs", links, ignore.case = TRUE)]
  if (length(preferred)) return(preferred[1])
  if (length(links)) return(links[1])
  stop(
    "No se encontró automáticamente el Excel histórico IVS. Define IMACEC_IVS_URL ",
    "o IMACEC_IVS_FILE con el archivo oficial del INE."
  )
}

resolve_ivs_file <- function() {
  if (file.exists(ivs_path)) return(ivs_path)
  download_ivs_file(find_ivs_url(), ivs_path)
}

read_ivs_official <- function(path = resolve_ivs_file()) {
  sheets <- readxl::excel_sheets(path)
  if (!"2" %in% sheets) stop("El Excel IVS no contiene la hoja oficial '2'.")
  raw <- suppressMessages(readxl::read_excel(path, sheet = "2", col_names = FALSE, .name_repair = "minimal"))
  if (nrow(raw) < 7 || ncol(raw) < 23) stop("La hoja '2' del IVS cambió de estructura.")

  headers <- normalize_ivs_text(vapply(c(2L, unname(ivs_columns)), function(j) raw[[j]][6], character(1)))
  expected <- c("mes", "transporte", "alojamiento", "informacion", "inmobiliarias", "profesionales", "administrativos")
  if (!all(vapply(seq_along(expected), function(i) grepl(expected[i], headers[i], fixed = TRUE), logical(1)))) {
    stop("Los encabezados de la hoja '2' no coinciden con las columnas oficiales B, C, G, K, O, S y W.")
  }

  rows <- 7:nrow(raw)
  out <- tibble::tibble(Periodo = parse_ivs_period(raw[[2]][rows]))
  for (name in names(ivs_columns)) out[[name]] <- parse_ivs_number(raw[[ivs_columns[[name]]]][rows])
  out |>
    dplyr::filter(!is.na(Periodo)) |>
    dplyr::distinct(Periodo, .keep_all = TRUE) |>
    dplyr::arrange(Periodo)
}

read_ivs_optional <- function() {
  tryCatch(
    read_ivs_official(),
    error = function(e) {
      warning(
        "El IVS oficial no está disponible; el ciclo EEE/M4 continuará y M8P quedará pendiente: ",
        conditionMessage(e), call. = FALSE
      )
      out <- tibble::tibble(Periodo = as.Date(character()))
      for (name in names(ivs_columns)) out[[name]] <- numeric()
      out
    }
  )
}

get_base_levels <- function() {
  series <- list(
    imacec_total_nivel = codes$imacec_total,
    imacec_no_minero_nivel = codes$imacec_no_minero,
    venta_minorista = codes$venta_minorista,
    credito_monto_nivel = codes$credito_monto,
    credito_cantidad_nivel = codes$credito_cantidad,
    avisos_laborales_nivel = codes$avisos_laborales,
    ipc_servicios_nivel = codes$ipc_servicios
  )
  purrr::imap(series, monthly_series) |>
    purrr::reduce(dplyr::full_join, by = "Periodo") |>
    dplyr::left_join(get_uf_monthly(), by = "Periodo") |>
    dplyr::arrange(Periodo)
}

get_ine_levels <- function() {
  purrr::imap(codes_ine, monthly_series) |>
    purrr::reduce(dplyr::full_join, by = "Periodo") |>
    dplyr::arrange(Periodo)
}

build_imacec_dataset <- function() {
  ivs_names <- names(ivs_columns)
  data <- get_base_levels() |>
    dplyr::full_join(get_ine_levels(), by = "Periodo") |>
    dplyr::full_join(read_ivs_optional(), by = "Periodo") |>
    dplyr::left_join(read_calendar(), by = "Periodo") |>
    dplyr::arrange(Periodo) |>
    dplyr::mutate(
      imacec_total = yoy(imacec_total_nivel),
      imacec_no_minero = yoy(imacec_no_minero_nivel),
      monto_credito = yoy(credito_monto_nivel),
      cantidad_credito = yoy(credito_cantidad_nivel),
      monto_credito_real = yoy(credito_monto_nivel / uf_nivel),
      avisos_laborales = yoy(avisos_laborales_nivel),
      mineria = yoy(mineria),
      manufactura = yoy(manufactura),
      comercio = yoy(comercio),
      electricidad = yoy(electricidad)
    )

  real_names <- sub("_nivel$", "_real", ivs_names)
  for (i in seq_along(ivs_names)) data[[real_names[i]]] <- yoy(data[[ivs_names[i]]] / data$ipc_servicios_nivel)

  data |>
    dplyr::mutate(
      factor_ivs_real = ifelse(
        rowSums(!is.na(dplyr::pick(dplyr::all_of(real_names)))) == length(real_names),
        rowMeans(dplyr::pick(dplyr::all_of(real_names)), na.rm = TRUE),
        NA_real_
      ),
      imacec_total_lag1 = dplyr::lag(imacec_total),
      imacec_no_minero_lag1 = dplyr::lag(imacec_no_minero),
      avisos_laborales_lag1 = dplyr::lag(avisos_laborales),
      mes_numero = lubridate::month(Periodo),
      mes_factor = factor(mes_numero, levels = 1:12, labels = c(
        "Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"
      )),
      efecto_bisiesto_yoy = as.integer(mes_numero == 2 & lubridate::leap_year(Periodo)) -
        as.integer(mes_numero == 2 & lubridate::leap_year(Periodo %m-% lubridate::years(1))),
      dummy_covid = as.integer(Periodo >= as.Date("2020-03-01") & Periodo <= as.Date("2021-12-01"))
    ) |>
    dplyr::filter(Periodo >= model_start_date)
}
