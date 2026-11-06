#' Create a Vinculum client
vinculum_client <- function(base_url, token = Sys.getenv("VINCULUM_TOKEN"),
                            timeout = 30) {
  url_error <- "base_url must be an HTTP or HTTPS URL without credentials, a query, or a fragment."
  if (!is_string(base_url) || !grepl("^https?://", base_url, ignore.case = TRUE) ||
      grepl("[?#]", base_url)) {
    stop(url_error, call. = FALSE)
  }
  url <- tryCatch(httr2::url_parse(base_url), error = function(e) NULL)
  if (!is_string(url$hostname) || !is.null(url$username) || !is.null(url$password)) {
    stop(url_error, call. = FALSE)
  }
  if (!is_string(token) || nchar(token, type = "bytes") > 512L ||
      grepl("[^!-~]", token, useBytes = TRUE)) {
    stop("Pass a bearer token or set VINCULUM_TOKEN.", call. = FALSE)
  }
  if (!is.numeric(timeout) || is.complex(timeout) || length(timeout) != 1L ||
      !is.finite(timeout) || timeout <= 0) {
    stop("timeout must be a positive number of seconds.", call. = FALSE)
  }

  request <- httr2::request(sub("/+$", "", base_url)) |>
    httr2::req_method("POST") |>
    httr2::req_auth_bearer_token(token) |>
    httr2::req_headers(Accept = "application/json") |>
    httr2::req_timeout(timeout) |>
    httr2::req_options(followlocation = FALSE) |>
    httr2::req_error(is_error = function(response) FALSE)
  structure(list(request = request), class = "vinculum_client")
}

print.vinculum_client <- function(x, ...) {
  cat("<vinculum_client> ", x$request$url, "\n", sep = "")
  invisible(x)
}

#' Run a configured query
vinculum_query <- function(client, name, params = list(),
                           as = c("data.frame", "list")) {
  if (!inherits(client, "vinculum_client")) {
    stop("Create client with vinculum_client().", call. = FALSE)
  }
  if (!is_string(name) || !grepl("^[A-Za-z][A-Za-z0-9_-]{0,63}\\z", name, perl = TRUE)) {
    stop("name must be a configured query name.", call. = FALSE)
  }
  if (!is.list(params) || is.object(params) ||
      (length(params) && (is.null(names(params)) || anyNA(names(params)) ||
                          any(!nzchar(names(params))) || anyDuplicated(names(params))))) {
    stop("params must be a named list.", call. = FALSE)
  }
  tabular <- match.arg(as) == "data.frame"

  request <- httr2::req_url_path_append(client$request, "queries", name)
  if (length(params)) {
    request <- httr2::req_body_json(
      request, params, auto_unbox = TRUE, null = "null", na = "null", digits = NA
    )
  } else {
    request <- httr2::req_body_raw(request, "{}", type = "application/json")
  }
  response <- tryCatch(
    httr2::req_perform(request),
    httr2_failure = function(e) stop_vinculum(conditionMessage(e), "transport_error")
  )
  status <- httr2::resp_status(response)
  payload <- tryCatch(
    jsonlite::parse_json(httr2::resp_body_string(response),
                        simplifyVector = tabular, bigint_as_char = TRUE),
    error = function(e) NULL
  )

  if (status < 200L || status >= 300L) {
    detail <- if (is.list(payload)) payload[["error"]]
    if (is.list(detail) && is_string(detail[["code"]]) && is_string(detail[["message"]])) {
      stop_vinculum(detail[["message"]], detail[["code"]], status)
    }
    message <- sprintf("Vinculum returned HTTP %d.", status)
    if (is.list(payload) && is_string(payload[["detail"]])) {
      message <- paste(message, payload[["detail"]])
    }
    stop_vinculum(message, "http_error", status)
  }
  parse_result(payload, tabular, status)
}

parse_result <- function(payload, tabular, status) {
  if (is.list(payload)) {
    rows <- payload[["rows"]]
    count <- payload[["row_count"]]
    truncated <- payload[["truncated"]]
    if (tabular && identical(rows, list())) {
      rows <- data.frame()
    }
    if (tabular && is.data.frame(rows)) {
      actual_count <- nrow(rows)
    } else if (!tabular && is.list(rows) && is.null(names(rows)) &&
               all(vapply(rows, is.list, logical(1)))) {
      actual_count <- length(rows)
    } else {
      actual_count <- NA_integer_
    }
    if (is.numeric(count) && isTRUE(count == actual_count) &&
        is.logical(truncated) && length(truncated) == 1L && !is.na(truncated)) {
      return(list(rows = rows, row_count = as.integer(count), truncated = truncated))
    }
  }
  stop_vinculum("The response did not contain a Vinculum result.", "protocol_error", status)
}

is_string <- function(value) {
  is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value)
}

stop_vinculum <- function(message, code, status_code = NA_integer_) {
  stop(structure(
    list(message = message, call = NULL, code = code, status_code = status_code),
    class = c("vinculum_error", "error", "condition")
  ))
}
