# Reusable UI components

#' Counter display component
#'
#' Shows the current count with dynamic styling
#'
#' @param count Current count value
#' @return Sparkle element
CounterDisplay <- function(count) {
  tags$div(
    class_name = "counter-display",
    style = list(
      text_align = "center",
      padding = "30px",
      margin = "20px 0",
      border_radius = "12px",
      background_color = "#f9fafb",
      border = paste0("3px solid ", get_count_color(count)),
      transition = "border-color 0.3s ease"
    ),
    tags$div(
      style = list(
        font_size = "64px",
        font_weight = "bold",
        color = get_count_color(count),
        transition = "color 0.3s ease"
      ),
      format_count(count)
    ),
    tags$div(
      style = list(
        font_size = "18px",
        color = "#6b7280",
        margin_top = "10px"
      ),
      get_status_message(count)
    )
  )
}

#' Action button component
#'
#' Styled button for counter actions
#'
#' @param label Button text
#' @param on_click Click handler
#' @param variant Button style variant ("primary", "secondary", "danger")
#' @return Sparkle element
ActionButton <- function(label, on_click, variant = "primary") {
  colors <- list(
    primary = list(bg = "#3b82f6", hover = "#2563eb"),
    secondary = list(bg = "#6b7280", hover = "#4b5563"),
    danger = list(bg = "#ef4444", hover = "#dc2626")
  )

  color_scheme <- colors[[variant]]

  tags$button(
    label,
    on_click = on_click,
    style = list(
      background_color = color_scheme$bg,
      color = "white",
      border = "none",
      padding = "12px 24px",
      border_radius = "8px",
      font_size = "16px",
      font_weight = "500",
      cursor = "pointer",
      transition = "all 0.2s ease",
      min_width = "120px"
    )
  )
}

#' Stats card component
#'
#' Shows statistics about the counter
#'
#' @param count Current count value
#' @param total_clicks Total number of clicks
#' @return Sparkle element
StatsCard <- function(count, total_clicks) {
  tags$div(
    style = list(
      background_color = "#ffffff",
      border = "1px solid #e5e7eb",
      border_radius = "8px",
      padding = "20px",
      margin_top = "20px",
      display = "flex",
      justify_content = "space_around"
    ),
    tags$div(
      style = list(text_align = "center"),
      tags$div(
        style = list(
          font_size = "14px",
          color = "#6b7280",
          margin_bottom = "5px"
        ),
        "Current Value"
      ),
      tags$div(
        style = list(
          font_size = "24px",
          font_weight = "bold",
          color = "#111827"
        ),
        count
      )
    ),
    tags$div(
      style = list(text_align = "center"),
      tags$div(
        style = list(
          font_size = "14px",
          color = "#6b7280",
          margin_bottom = "5px"
        ),
        "Total Clicks"
      ),
      tags$div(
        style = list(
          font_size = "24px",
          font_weight = "bold",
          color = "#111827"
        ),
        total_clicks
      )
    ),
    tags$div(
      style = list(text_align = "center"),
      tags$div(
        style = list(
          font_size = "14px",
          color = "#6b7280",
          margin_bottom = "5px"
        ),
        "Absolute Value"
      ),
      tags$div(
        style = list(
          font_size = "24px",
          font_weight = "bold",
          color = "#111827"
        ),
        abs(count)
      )
    )
  )
}
