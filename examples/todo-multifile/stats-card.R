# Reusable stats card component for displaying metrics

# Static styled components
StatsContainer <- styled_div(
  flex = "1",
  text_align = "center"
)

StatsLabel <- styled_div(
  font_size = "14px",
  color = "#6b7280"
)

# Component function with dynamic styling
StatsCard <- function(count, label, color) {
  # Local: Component-specific styled element
  Number <- styled_div(
    font_size = "32px",
    font_weight = "bold",
    color = color
  )

  StatsContainer(
    Number(count),
    StatsLabel(label)
  )
}
