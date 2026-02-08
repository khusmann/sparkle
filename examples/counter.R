# Sparkle Counter Example
# A simple counter app demonstrating state management and event handlers
#
# Run with: sparkle_app("examples/counter.R")

library(sparkle)
library(zeallot)

App <- function() {
  # Create a state variable with zeallot destructuring
  c(count, set_count) %<-% use_state(0)

  # Build the UI
  tags$div(
    class_name = "counter-app",

    # Title
    tags$h1("Sparkle Counter ✨"),

    # Display current count
    tags$div(
      class_name = "count-display",
      tags$h2(paste("Count:", count()))
    ),

    # Control buttons
    tags$div(
      class_name = "controls",

      tags$button("Decrement", on_click = \() set_count(count() - 1)),
      tags$button("Reset", on_click = \() set_count(0)),
      tags$button("Increment", on_click = \() set_count(count() + 1))
    ),

    # Info text
    tags$p(
      paste("You've clicked", abs(count()), "times",
            if (count() > 0) "(positive)" else if (count() < 0) "(negative)" else "")
    )
  )
}
