# ============================================================
# imacec_utils.R
# Utilidades generales: API BCCh, transformaciones y fechas
# ============================================================

assert_bcch_credentials <- function(user = USER_BCCH, pass = PASS_BCCH) {
  if (identical(user, "") || identical(pass, "")) {
    stop(
      "Faltan credenciales BCCh. Define BCCH_USER y BCCH_PASS en tu .Renviron local. ",
      "No escribas credenciales directamente en scripts públicos."
    )
  }
  invisible(TRUE)
}

bcch_url <- function(series_code, firstdate, lastdate, user = USER_BCCH, pass = PASS_BCCH) {
  assert_bcch_credentials(user, pass)
  base <- "https://si3.bcentral.cl/SieteRestWS/SieteRestWS.ashx"
  paste0(
    base,
    "?user=", utils::URLencode(user, reserved = TRUE),
    "&pass=", utils::URLencode(pass, reserved = TRUE),
    "&firstdate=", firstdate,
    "&lastdate=", lastdate,
    "&timeseries=", series_code,
    "&function=GetSeries"
  )
}

bcch_redact_url <- function(url) {
  url <- sub("([?&]user=)[^&]+", "\\1***", url)
  url <- sub("([?&]pass=)[^&]+", "\\1***", url)
  url
}

bcch_decode_json_text <- function(raw_response) {
  # La API del BCCh ocasionalmente retorna bytes que hacen fallar a
  # rjson::fromJSON(file = url) con "input string is invalid UTF-8".
  # Por eso se descarga como raw, se normaliza encoding y recién ahí se parsea.
  txt0 <- rawToChar(raw_response)
  encodings <- c("UTF-8", "latin1", "WINDOWS-1252", "unknown")

  for (enc in encodings) {
    txt <- tryCatch(
      if (identical(enc, "unknown")) {
        iconv(txt0, to = "UTF-8", sub = "")
      } else {
        iconv(txt0, from = enc, to = "UTF-8", sub = "")
      },
      error = function(e) NA_character_
    )

    if (is.na(txt) || !nzchar(txt)) next

    txt <- sub("^\\ufeff", "", txt, perl = TRUE)
    txt <- sub("^\\xEF\\xBB\\xBF", "", txt, perl = TRUE)
    txt <- trimws(txt)

    if (jsonlite::validate(txt)) return(txt)
  }

  stop("No se pudo normalizar la respuesta JSON del BCCh a UTF-8.", call. = FALSE)
}

bcch_from_json_safe <- function(url, tries = 3L, pause_base = 1.25) {
  last_error <- NULL

  for (i in seq_len(tries)) {
    out <- tryCatch({
      resp <- httr::RETRY(
        verb = "GET",
        url = url,
        times = 2,
        pause_base = pause_base,
        httr::timeout(60),
        httr::user_agent("Economics-portfolio/1.0 (+https://mulloav3007.github.io/Economics/)")
      )

      httr::stop_for_status(resp)
      raw_response <- httr::content(resp, as = "raw")
      txt <- bcch_decode_json_text(raw_response)
      jsonlite::fromJSON(txt, simplifyVector = FALSE)
    }, error = function(e) {
      last_error <<- e
      NULL
    })

    if (!is.null(out)) return(out)
    Sys.sleep(pause_base * i)
  }

  stop(
    "No se pudo leer la respuesta del BCCh después de ", tries, " intentos. ",
    "URL redacted: ", bcch_redact_url(url), ". ",
    "Último error: ", conditionMessage(last_error),
    call. = FALSE
  )
}

fetch_series <- function(code, firstdate = first_date, lastdate = last_date) {
  if (is.null(code) || identical(code, "")) stop("Código de serie vacío o NULL.")

  url <- bcch_url(code, firstdate, lastdate)
  j <- bcch_from_json_safe(url)

  # Si la API retorna una estructura de error, fallar con mensaje legible.
  if (!is.null(j$Error) || !is.null(j$error) || !is.null(j$Codigo)) {
    msg <- paste(c(j$Error, j$error, j$Descripcion, j$description, j$Codigo), collapse = " ")
    stop("BCCh reportó un error para la serie ", code, ": ", msg, call. = FALSE)
  }

  pull_obs <- function(node) {
    if (is.null(node) || is.null(node$Obs) || length(node$Obs) == 0) return(NULL)

    tibble::tibble(
      date  = lubridate::dmy(vapply(node$Obs, function(x) x[["indexDateString"]], character(1))),
      value = suppressWarnings(as.numeric(gsub(",", ".", vapply(node$Obs, function(x) x[["value"]], character(1)), fixed = TRUE)))
    )
  }

  out <- list()
  if (!is.null(j$Series))    out[[length(out) + 1]] <- pull_obs(j$Series)
  if (!is.null(j$DAILY))     out[[length(out) + 1]] <- pull_obs(j$DAILY)
  if (!is.null(j$MONTHLY))   out[[length(out) + 1]] <- pull_obs(j$MONTHLY)
  if (!is.null(j$WEEKLY))    out[[length(out) + 1]] <- pull_obs(j$WEEKLY)
  if (!is.null(j$QUARTERLY)) out[[length(out) + 1]] <- pull_obs(j$QUARTERLY)
  if (!is.null(j$ANNUAL))    out[[length(out) + 1]] <- pull_obs(j$ANNUAL)

  out <- out[!vapply(out, is.null, logical(1))]
  if (length(out) == 0) return(tibble::tibble(date = as.Date(character()), value = numeric()))

  dplyr::bind_rows(out) |>
    dplyr::filter(!is.na(date)) |>
    dplyr::arrange(date)
}

yoy <- function(x) {
  (x / dplyr::lag(x, 12) - 1) * 100
}

last_non_na <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_real_)
  as.numeric(utils::tail(x, 1))
}

month_label_es <- function(fecha) {
  # Evita depender de locale del sistema operativo.
  meses <- c(
    "enero", "febrero", "marzo", "abril", "mayo", "junio",
    "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
  )
  paste(meses[lubridate::month(fecha)], lubridate::year(fecha))
}

clean_period <- function(x) {
  as.Date(lubridate::floor_date(as.Date(x), "month"))
}
