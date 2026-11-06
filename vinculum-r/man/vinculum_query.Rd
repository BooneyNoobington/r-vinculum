\name{vinculum_query}
\alias{vinculum_query}
\title{Run a configured Vinculum query}
\usage{
vinculum_query(client, name, params = list(), as = c("data.frame", "list"))
}
\arguments{
\item{client}{A client created by \code{\link{vinculum_client}}.}
\item{name}{The configured query name.}
\item{params}{A named list of parameter values. Wrap values for array
parameters in \code{I()}, including single-element and empty vectors.}
\item{as}{Use \code{"data.frame"} for tabular rows or \code{"list"} to
preserve the JSON row structure.}
}
\description{
Send a query to Vinculum and return its rows and result metadata. HTTP errors
raise a \code{vinculum_error} condition with \code{code} and
\code{status_code} fields. Use \code{conditionMessage()} for the message.
}
\value{
A list with \code{rows}, \code{row_count}, and \code{truncated}.
}
\examples{
\dontrun{
client <- vinculum_client("https://example.org/vinculum")
result <- vinculum_query(client, "time_series_many", list(series_ids = I(1:3)))
result$rows
}
}
