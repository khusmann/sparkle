# Reusable layout components

# Centered header layout
HeaderSection <- styled_div(
  text_align = "center",
  margin_bottom = "30px"
)

# Flex header with space-between layout (for title + actions)
TasksHeader <- styled_div(
  display = "flex",
  justify_content = "space-between",
  align_items = "center",
  margin_bottom = "16px"
)

# Centered content wrapper
CenterWrapper <- styled_div(
  text_align = "center",
  margin_top = "20px"
)
