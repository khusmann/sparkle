# Reusable stats card component for displaying metrics

StatsCard <- function(count, label, color) {
  # Local: Component-specific styled elements
  Container <- styled_div(
    flex = "1",
    text_align = "center",
    min_width = "80px"
  )

  Label <- styled_div(
    font_size = "14px",
    color = "#6b7280"
  )

  Number <- styled_div(
    font_size = "32px",
    font_weight = "bold",
    color = color
  )

  Container(
    Number(count),
    Label(label)
  )
}
