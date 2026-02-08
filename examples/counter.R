# Sparkle Counter Example
# Run with: sparkle_app("examples/counter.R")

library(sparkle)
library(zeallot)

App <- function() {
  c(count, set_count) %<-% use_state(0)

  tags$div(
    tags$h1(paste("Count:", count)),
    tags$p(
      tags$a(
        "View source",
        href = "https://github.com/khusmann/sparkle/blob/main/examples/counter.R"
      )
    ),
    tags$button(
      "Increment",
      on_click = \() set_count(\(c) c + 1)
    ),
    tags$button(
      "Decrement",
      on_click = \() set_count(\(c) c - 1)
    ),
    tags$button(
      "Reset",
      on_click = \() set_count(0)
    )
  )
}
