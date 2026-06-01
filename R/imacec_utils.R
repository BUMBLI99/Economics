# ============================================================
# imacec_utils.R
# Utilidades generales: API BCCh, transformaciones y fechas
# ============================================================

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

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

bcch_strip_bom <- function(txt) {
  # No usar expresiones regulares tipo "\\ufeff": en algunas instalaciones
  # de R/PCRE2 falla con "PCRE2 does not support \\u".
  if (is.na(txt) || !nzchar(txt)) return(txt)

  bom_unicode <- intToUtf8(0xFEFF)
  if (startsWith(txt, bom_unicode)) {
    txt <- substring(txt, nchar(bom_unicode, type = "chars") + 1L)
  }
  txt <- gsub(bom_unicode, "", txt, fixed = TRUE)

  # Variante byte-order-mark UTF-8 literal. Se maneja sin regex.
  bom_utf8 <- rawToChar(as.raw(c(0xEF, 0xBB, 0xBF)))
  if (startsWith(txt, bom_utf8)) {
    txt <- substring(txt, nchar(bom_utf8, type = "chars") + 1L)
  }
  txt
}

bcch_decode_json_text <- function(raw_response) {
  # La API del BCCh ocasionalmente retorna bytes que hacen fallar a
  # rjson::fromJSON(file = url) con "input string is invalid UTF-8".
  # Por eso se descarga como raw, se normaliza encoding y recién ahí se parsea.
  txt0 <- rawToChar(raw_response)
  encodings <- c("UTF-8", "latin1", "WINDOWS-1252", "unknown")
  last_error <- NULL

  for (enc in encodings) {
    txt <- tryCatch(
      if (identical(enc, "unknown")) {
        iconv(txt0, to = "UTF-8", sub = "")
      } else {
        iconv(txt0, from = enc, to = "UTF-8", sub = "")
      },
      error = function(e) {
        last_error <<- conditionMessage(e)
        NA_character_
      }
    )

    if (is.na(txt) || !nzchar(txt)) next

    txt <- bcch_strip_bom(txt)
    txt <- trimws(txt)

    if (jsonlite::validate(txt)) return(txt)
    last_error <- "jsonlite::validate(txt) == FALSE"
  }

  stop("No se pudo normalizar la respuesta JSON del BCCh a UTF-8. Último error: ", last_error, call. = FALSE)
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

bcch_is_success <- function(j) {
  codigo <- j$Codigo %||% j$codigo %||% NULL
  descripcion <- tolower(trimws(as.character(j$Descripcion %||% j$description %||% "")))

  # La respuesta normal de SieteRestWS suele traer Codigo = 0 y
  # Descripcion = "Success". Eso NO es error. El bug anterior trataba
  # cualquier presencia de Codigo como error, por eso se caía con "Success 0".
  if (!is.null(codigo)) {
    codigo_chr <- trimws(as.character(codigo[1]))
    if (codigo_chr %in% c("0", "0.0", "00", "")) return(TRUE)
    return(FALSE)
  }

  if (descripcion %in% c("success", "ok")) return(TRUE)
  TRUE
}

bcch_error_message <- function(j) {
  paste(
    na.omit(c(
      as.character(j$Error %||% j$error %||% NA_character_),
      as.character(j$Descripcion %||% j$description %||% NA_character_),
      as.character(j$Codigo %||% j$codigo %||% NA_character_)
    )),
    collapse = " "
  )
}

parse_bcch_date <- function(x) {
  x <- as.character(x)
  d <- suppressWarnings(lubridate::dmy(x))
  bad <- is.na(d)
  if (any(bad)) d[bad] <- suppressWarnings(lubridate::ymd(x[bad]))
  bad <- is.na(d)
  if (any(bad)) d[bad] <- suppressWarnings(as.Date(x[bad]))
  as.Date(d)
}

bcch_collect_series_nodes <- function(x) {
  nodes <- list()

  walk_node <- function(node) {
    if (is.null(node)) return(NULL)
    if (is.list(node) && !is.null(node$Obs)) {
      nodes[[length(nodes) + 1L]] <<- node
      return(NULL)
    }
    if (is.list(node)) {
      for (child in node) walk_node(child)
    }
    NULL
  }

  walk_node(x)
  nodes
}

bcch_pull_obs <- function(node) {
  if (is.null(node) || is.null(node$Obs) || length(node$Obs) == 0) return(NULL)

  get_obs_field <- function(obs, candidates) {
    for (nm in candidates) {
      val <- obs[[nm]]
      if (!is.null(val) && length(val) > 0) return(as.character(val[1]))
    }
    NA_character_
  }

  fechas <- vapply(node$Obs, get_obs_field, character(1), candidates = c("indexDateString", "indexDate", "date", "Date"))
  valores <- vapply(node$Obs, get_obs_field, character(1), candidates = c("value", "Value", "valor", "Valor"))

  tibble::tibble(
    date = parse_bcch_date(fechas),
    value = suppressWarnings(as.numeric(gsub(",", ".", valores, fixed = TRUE)))
  ) |>
    dplyr::filter(!is.na(date)) |>
    dplyr::arrange(date)
}

fetch_series <- function(code, firstdate = first_date, lastdate = last_date) {
  if (is.null(code) || identical(code, "")) stop("Código de serie vacío o NULL.")

  url <- bcch_url(code, firstdate, lastdate)
  j <- bcch_from_json_safe(url)

  # Solo falla si BCCh trae Codigo distinto de cero o un error explícito.
  # Codigo = 0 / Descripcion = Success es la respuesta normal de éxito.
  explicit_error <- !is.null(j$Error) || !is.null(j$error)
  if (explicit_error || !bcch_is_success(j)) {
    msg <- bcch_error_message(j)
    if (!nzchar(msg)) msg <- "respuesta sin observaciones o código no exitoso"
    stop("BCCh reportó un error para la serie ", code, ": ", msg, call. = FALSE)
  }

  top_nodes <- list(j$Series, j$DAILY, j$MONTHLY, j$WEEKLY, j$QUARTERLY, j$ANNUAL)
  nodes <- unlist(lapply(top_nodes, bcch_collect_series_nodes), recursive = FALSE)

  out <- lapply(nodes, bcch_pull_obs)
  out <- out[!vapply(out, is.null, logical(1))]

  if (length(out) == 0) {
    warning("La serie BCCh no trajo observaciones: ", code)
    return(tibble::tibble(date = as.Date(character()), value = numeric()))
  }

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
