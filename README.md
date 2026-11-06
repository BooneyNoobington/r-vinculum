# Vinculum for R

Run configured Vinculum queries from R. The package returns a data frame by default and exposes the API's row count and truncation flag.

## Install

Once this repository is on GitHub, replace `OWNER` with its account or organization name.

```r
install.packages("remotes")
remotes::install_github("OWNER/vinculum-r")
```

For a private repository, authenticate `remotes` with `GITHUB_PAT`. To install from an extracted copy instead, use `remotes::install_local("path/to/vinculum-r")`.

## Query

Set `VINCULUM_TOKEN` in your environment before starting R. Use the service URL including its prefix and substitute one of your configured query names. This example uses the API demo's list endpoint.

```r
library(vinculum)

client <- vinculum_client("https://server.company.org/vinculum")
result <- vinculum_query(client, "time_series_many", list(series_ids = I(1:3)))

result$rows
result$row_count
result$truncated
```

Pass `token =` to `vinculum_client()` to supply a token explicitly. The request timeout defaults to 30 seconds and can be set with `timeout =`.

### Parameters and results

| Parameter | R value in `params` | JSON value |
| --- | --- | --- |
| Single integer | `series_id = 1L` | `1` |
| Integer array | `series_ids = I(c(1L, 2L, 3L))` | `[1, 2, 3]` |
| One-item array | `series_ids = I(1L)` | `[1]` |
| Empty integer array | `series_ids = I(integer())` | `[]` |
| String array | `statuses = I(c("active", "pending"))` | `["active", "pending"]` |
| Null | `note = NULL` | `null` |

Use `I()` around values declared as `integer_list` or `string_list` in Vinculum. This keeps the JSON array shape at every length. For a query with zero parameters, omit `params` or pass `list()`.

Use `as = "list"` to keep the rows as a list of records, including nested JSON. A zero-row tabular result is an empty data frame. Vinculum's date, time, and decimal strings stay as strings. Integers beyond JSON's exact double-precision range are read as strings.

### Errors

A `vinculum_error` condition exposes `code` and `status_code`. `conditionMessage()` returns the API's diagnostic when available. A network failure uses code `transport_error` and `NA` for the status.

```r
tryCatch(
  vinculum_query(client, "time_series_many", list(series_ids = I(1L))),
  vinculum_error = function(error) {
    message(conditionMessage(error))
    list(code = error$code, status_code = error$status_code)
  }
)
```

## Publish this source

Update the maintainer email in `DESCRIPTION`. From this directory, use an authenticated GitHub CLI and replace `OWNER` with the destination.

```sh
git init -b main
git add .
git commit -m "Add Vinculum R client"
gh repo create OWNER/vinculum-r --private --source=. --push
```

Run package checks with `R CMD build vinculum-r` from the parent directory, then `R CMD check --no-manual vinculum_0.1.0.tar.gz`.
