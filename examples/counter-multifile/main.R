# Main application file
# This file defines the App component that ties everything together
#
# Files are loaded alphabetically, so:
# 1. aaa-libraries.R loads first (library imports)
# 2. components.R loads second
# 3. main.R loads third
# 4. utils.R loads fourth
#
# All functions from all files are available in the global scope

#' Main application component
#'
#' This demonstrates a multi-file Sparkle app with:
#' - Utility functions (utils.R)
#' - Reusable components (components.R)
#' - Main app logic (main.R)
#'
#' Run with: sparkle::sparkle_app("examples/counter-multifile/")
App <- function() {
  # State management
  c(count, set_count) %<-% use_state(0)
  c(total_clicks, set_total_clicks) %<-% use_state(0)

  # Event handlers
  increment <- function() {
    set_count(\(c) c + 1)
    set_total_clicks(\(t) t + 1)
  }

  decrement <- function() {
    set_count(\(c) c - 1)
    set_total_clicks(\(t) t + 1)
  }

  reset <- function() {
    set_count(0)
    # Don't reset total_clicks - it's cumulative
  }

  # Render UI
  tags$div(
    style = list(
      max_width = "600px",
      margin = "40px auto",
      padding = "20px",
      font_family = "system-ui, -apple-system, sans-serif"
    ),

    # Header
    tags$h1(
      "Multi-File Counter App ✨",
      style = list(
        text_align = "center",
        color = "#111827",
        margin_bottom = "10px"
      )
    ),

    tags$p(
      style = list(
        text_align = "center",
        color = "#6b7280",
        margin_bottom = "30px"
      ),
      "This example demonstrates code organization across multiple files! ",
      tags$a(
        "View source",
        href = paste0(
          "https://github.com/khusmann/sparkle/",
          "tree/main/examples/counter-multifile"
        )
      )
    ),

    # Counter display (from components.R, uses utils.R)
    CounterDisplay(count),

    # Control buttons (using ActionButton component from components.R)
    tags$div(
      style = list(
        display = "flex",
        gap = "10px",
        justify_content = "center",
        margin = "20px 0"
      ),
      ActionButton("- Decrease", decrement, "danger"),
      ActionButton("Reset", reset, "secondary"),
      ActionButton("+ Increase", increment, "primary")
    ),

    # Statistics card (from components.R)
    StatsCard(count, total_clicks),

    # File structure info
    tags$div(
      style = list(
        margin_top = "30px",
        padding = "15px",
        background_color = "#f3f4f6",
        border_radius = "8px",
        font_size = "14px",
        color = "#4b5563"
      ),
      tags$strong("File Structure:"),
      tags$div(
        style = list(margin_top = "8px", font_family = "monospace"),
        "📁 counter-multifile/",
        tags$br(),
        "├── aaa-libraries.R (Library imports)",
        tags$br(),
        "├── components.R    (UI components)",
        tags$br(),
        "├── main.R         (App definition)",
        tags$br(),
        "└── utils.R        (Helper functions)"
      )
    )
  )
}
