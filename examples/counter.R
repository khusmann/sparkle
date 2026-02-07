# Sparkle Counter Example
# A simple counter app demonstrating state management and event handlers

library(sparkle)

Counter <- function() {
  # Create a state variable
  count <- use_state(0)

  # Build the UI
  tags$div(
    class_name = "counter-app",

    # Title
    tags$h1("Sparkle Counter ✨"),

    # Display current count
    tags$div(
      class_name = "count-display",
      tags$h2(paste("Count:", count$value))
    ),

    # Control buttons
    tags$div(
      class_name = "controls",

      tags$button(
        "Decrement",
        on_click = wrap_fn(\() count$set(count$value - 1))
      ),

      tags$button(
        "Reset",
        on_click = wrap_fn(\() count$set(0))
      ),

      tags$button(
        "Increment",
        on_click = wrap_fn(\() count$set(count$value + 1))
      )
    ),

    # Info text
    tags$p(
      paste("You've clicked", abs(count$value), "times",
            if (count$value > 0) "(positive)" else if (count$value < 0) "(negative)" else "")
    )
  )
}

# Launch the app
sparkle_app(Counter, port = 3000)
