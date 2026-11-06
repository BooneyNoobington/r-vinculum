\name{vinculum_client}
\alias{vinculum_client}
\title{Create a Vinculum client}
\usage{
vinculum_client(base_url, token = Sys.getenv("VINCULUM_TOKEN"), timeout = 30)
}
\arguments{
\item{base_url}{The Vinculum service URL, including any path prefix such as
\code{/vinculum}.}
\item{token}{The bearer token. Defaults to the \code{VINCULUM_TOKEN}
environment variable.}
\item{timeout}{The maximum request time in seconds.}
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
