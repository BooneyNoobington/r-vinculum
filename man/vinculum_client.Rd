\name{vinculum_client}
\alias{vinculum_client}
\title{Create a Vinculum client}
\usage{
vinculum_client(
  base_url,
  token = Sys.getenv("VINCULUM_TOKEN"),
  timeout = 30,
  noproxy = Sys.getenv("VINCULUM_NOPROXY"),
  ca_bundle = Sys.getenv("VINCULUM_CA_BUNDLE")
)
}
\arguments{
\item{base_url}{The Vinculum service URL, including any path prefix such as
\code{/vinculum}.}
\item{token}{The bearer token. Defaults to the \code{VINCULUM_TOKEN}
environment variable.}
\item{timeout}{The maximum request time in seconds.}
\item{noproxy}{A hostname, comma-separated hostnames, or \code{"*"} for
direct connections through this client. Defaults to \code{VINCULUM_NOPROXY}.
An empty string uses curl's normal proxy rules.}
\item{ca_bundle}{Path to the PEM CA certificate or bundle used to verify
the HTTPS server. Defaults to \code{VINCULUM_CA_BUNDLE}. An empty string
uses curl's normal certificate trust configuration.}
}
\description{
Configure the URL and bearer authentication for calls to
\code{\link{vinculum_query}}.
}
\value{A Vinculum client object.}
\examples{
client <- vinculum_client("https://example.org/vinculum", token = "example-token")
print(client)
}
