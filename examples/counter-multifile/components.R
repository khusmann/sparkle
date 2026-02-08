# Reusable UI components

#' Counter display component
#'
#' Shows the current count with dynamic styling using styled components
#'
#' @param count Current count value
#' @return Sparkle element
CounterDisplay <- function(count) {
  # Create styled components with dynamic values
  DisplayContainer <- styled_div(
    text_align = "center",
    padding = "30px",
    margin = "20px 0",
    border_radius = "12px",
    background_color = "#f9fafb",
    border = paste0("3px solid ", get_count_color(count)),
    transition = "border-color 0.3s ease"
  )

  CountNumber <- styled_div(
    font_size = "64px",
    font_weight = "bold",
    color = get_count_color(count),
    transition = "color 0.3s ease"
  )

  StatusMessage <- styled_div(
    font_size = "18px",
    color = "#6b7280",
    margin_top = "10px"
  )

  DisplayContainer(
    CountNumber(format_count(count)),
    StatusMessage(get_status_message(count))
  )
}

#' Action button component
#'
#' Styled button for counter actions using Sparkle's design system
#'
#' @param label Button text
#' @param on_click Click handler
#' @param variant Button style variant ("primary", "secondary", "danger")
#' @return Sparkle element
ActionButton <- function(label, on_click, variant = "primary") {
  # Use Sparkle's built-in design system button
  ui$Button(
    label,
    variant = variant,
    on_click = on_click,
    style = list(min_width = "120px")
  )
}

# Static styled components for stats
StatItemContainer <- styled_div(text_align = "center")

StatLabel <- styled_div(
  font_size = "14px",
  color = "#6b7280",
  margin_bottom = "5px"
)

StatValue <- styled_div(
  font_size = "24px",
  font_weight = "bold",
  color = "#111827"
)

StatsCardContainer <- styled_div(
  background_color = "#ffffff",
  border = "1px solid #e5e7eb",
  border_radius = "8px",
  padding = "20px",
  margin_top = "20px",
  display = "flex",
  justify_content = "space_around"
)

#' Stat item component
#'
#' Displays a labeled statistic value
#'
#' @param label The stat label
#' @param value The stat value
#' @return Sparkle element
StatItem <- function(label, value) {
  StatItemContainer(
    StatLabel(label),
    StatValue(value)
  )
}

#' Stats card component
#'
#' Shows statistics about the counter using styled components
#'
#' @param count Current count value
#' @param total_clicks Total number of clicks
#' @return Sparkle element
StatsCard <- function(count, total_clicks) {
  StatsCardContainer(
    StatItem("Current Value", count),
    StatItem("Total Clicks", total_clicks),
    StatItem("Absolute Value", abs(count))
  )
}
