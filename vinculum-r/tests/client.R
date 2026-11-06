library(vinculum)

Sys.setenv(VINCULUM_TOKEN = "fixture-token")
Sys.unsetenv(c("VINCULUM_NOPROXY", "VINCULUM_CA_BUNDLE"))
client <- vinculum_client("https://proxy.test/vinculum/")
stopifnot(!any(grepl("fixture-token", capture.output(print(client)), fixed = TRUE)))

ok <- '{"rows":[{"amount":"12.5000","large":9223372036854775807}],"row_count":1,"truncated":true}'
for (ids in list(integer(), 1L, 1:3)) {
  mock <- function(req) {
    stopifnot(
      identical(req$url, "https://proxy.test/vinculum/queries/by_ids"),
      identical(req$method, "POST"),
      as.character(req$headers[["Authorization"]]) == "Bearer fixture-token"
    )
    json <- do.call(jsonlite::toJSON, c(list(x = req$body$data), req$body$params))
    expected <- paste0('{"ids":[', paste(ids, collapse = ","), ']}')
    stopifnot(as.character(json) == expected)
    httr2::response(body = charToRaw(ok))
  }
  result <- httr2::with_mocked_responses(
    mock,
    vinculum_query(client, "by_ids", list(ids = I(ids)))
  )
  stopifnot(
    is.data.frame(result$rows),
    identical(result$rows$amount, "12.5000"),
    identical(result$rows$large, "9223372036854775807"),
    identical(result$row_count, 1L),
    isTRUE(result$truncated)
  )
}

empty <- '{"rows":[],"row_count":0,"truncated":false}'
result <- httr2::with_mocked_responses(
  function(req) {
    stopifnot(as.character(req$body$data) == "{}")
    httr2::response(body = charToRaw(empty))
  },
  vinculum_query(client, "no_params")
)
stopifnot(is.data.frame(result$rows), identical(result$row_count, 0L))

raw_result <- httr2::with_mocked_responses(
  function(req) httr2::response(body = charToRaw(ok)),
  vinculum_query(client, "by_ids", list(ids = I(1L)), as = "list")
)
stopifnot(identical(raw_result$rows[[1]]$large, "9223372036854775807"))

failed <- httr2::with_mocked_responses(
  function(req) httr2::response(
    status_code = 502L,
    body = charToRaw('{"error":{"code":"query_failed","message":"no such table: measurements"}}')
  ),
  tryCatch(vinculum_query(client, "broken"), vinculum_error = identity)
)
stopifnot(
  inherits(failed, "vinculum_error"),
  identical(failed$code, "query_failed"),
  failed$status_code == 502L,
  conditionMessage(failed) == "no such table: measurements"
)

ca_path <- tempfile(pattern = "Vinculum test CA ", fileext = ".pem")
writeLines("CA path fixture", ca_path)
Sys.setenv(VINCULUM_NOPROXY = "proxy.test", VINCULUM_CA_BUNDLE = ca_path)
configured <- vinculum_client("https://proxy.test/vinculum")
httr2::with_mocked_responses(
  function(req) {
    stopifnot(
      identical(req$options$noproxy, "proxy.test"),
      identical(req$options$cainfo, normalizePath(ca_path, winslash = "/"))
    )
    httr2::response(body = charToRaw(empty))
  },
  invisible(vinculum_query(configured, "no_params"))
)

overridden <- vinculum_client("https://proxy.test/vinculum", noproxy = "*", ca_bundle = "")
stopifnot(
  identical(overridden$request$options$noproxy, "*"),
  is.null(overridden$request$options$cainfo)
)
unlink(ca_path)
