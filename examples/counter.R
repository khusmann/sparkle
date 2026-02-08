# Sparkle Counter Example
# Run with: sparkle_app("examples/counter.R")

library(sparkle)
library(zeallot)

App <- function() {
  c(count, set_count) %<-% use_state(0)

  tags$div(
    tags$h1(paste("Count:", count)),
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
    ),
    tags$div(
      style = list(
        margin_top = "40px",
        padding_top = "20px",
        border_top = "1px solid #e5e7eb",
        text_align = "center",
        font_size = "14px",
        color = "#6b7280"
      ),
      tags$a(
        "View source on GitHub",
        href = "https://github.com/khusmann/sparkle/blob/main/examples/counter.R",
        target = "_blank",
        style = list(color = "#3b82f6", text_decoration = "none")
      )
    )
  )
}
