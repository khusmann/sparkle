# Sparkle Styled Components Demo
# Demonstrates creating custom styled components with CSS-in-R
#
# Run with: sparkle_app("examples/styled-demo.R")

library(sparkle)
library(zeallot)

# Static styled components at module level
PrimaryButton <- styled_button(
  background_color = "#3b82f6",
  color = "white",
  padding = "12px 24px",
  border = "none",
  border_radius = "6px",
  font_size = "16px",
  font_weight = "500",
  cursor = "pointer",
  transition = "all 0.2s ease",
  css = "
    &:hover {
      background-color: #2563eb;
      transform: translateY(-2px);
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    &:active {
      transform: translateY(0);
    }
  "
)

Container <- styled_div(
  max_width = "600px",
  margin = "40px auto",
  padding = "30px",
  font_family = "system-ui, -apple-system, sans-serif",
  width = "100%",
  box_sizing = "border-box",
  overflow_x = "hidden"
)

ButtonRow <- styled_div(
  display = "flex",
  gap = "12px",
  justify_content = "center",
  margin_top = "20px",
  flex_wrap = "wrap"
)

# Wrapper component with dynamic styles
CountDisplay <- function(count) {
  # Local: Component-specific styled element
  Display <- styled_div(
    font_size = "48px",
    font_weight = "bold",
    text_align = "center",
    margin = "30px 0",
    padding = "20px",
    border_radius = "12px",
    background_color = "#f9fafb",
    color = if (count > 0) "#22c55e" else if (count < 0) "#ef4444" else "#6b7280",
    transition = "color 0.3s ease"
  )

  Display(paste("Count:", count))
}

App <- function() {
  c(count, set_count) %<-% use_state(0)

  # Render component - no styled components defined here
  Container(
    tags$h1(
      "Styled Components Demo ✨",
      style = list(text_align = "center", color = "#374151")
    ),
    tags$p(
      style = list(text_align = "center", color = "#6b7280"),
      "Custom styled components with CSS-in-R. ",
      tags$a(
        "View source",
        href = paste0(
          "https://github.com/khusmann/sparkle/",
          "blob/main/examples/styled-demo.R"
        )
      )
    ),
    CountDisplay(count),
    ButtonRow(
      PrimaryButton("- Decrement", on_click = \() set_count(\(c) c - 1)),
      PrimaryButton("Reset", on_click = \() set_count(0)),
      PrimaryButton("+ Increment", on_click = \() set_count(\(c) c + 1))
    ),
    tags$p(
      paste(
        "You've clicked",
        abs(count),
        "times",
        if (count > 0) "(positive)" else if (count < 0) "(negative)" else ""
      ),
      style = list(
        text_align = "center",
        color = "#6b7280",
        margin_top = "20px"
      )
    )
  )
}
