# TODO-specific components

TodoItem <- function(todo, index, on_toggle, on_delete) {
  # Local: Component-specific styled elements
  Checkbox <- styled_input(
    width = "20px",
    height = "20px",
    cursor = "pointer"
  )

  Item <- styled_div(
    display = "flex",
    align_items = "center",
    gap = "12px",
    padding = "12px",
    border_radius = "6px",
    background_color = if (todo$completed) "#f9fafb" else "white",
    border = "1px solid #e5e7eb",
    transition = "all 0.2s ease",
    flex_wrap = "wrap",
    css = "
      &:hover {
        border-color: #d1d5db;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
      }
    "
  )

  Text <- styled_span(
    flex = "1",
    font_size = "16px",
    color = if (todo$completed) "#9ca3af" else "#111827",
    text_decoration = if (todo$completed) "line-through" else "none",
    transition = "all 0.2s ease",
    min_width = "0",
    word_wrap = "break-word"
  )

  Item(
    Checkbox(
      type = "checkbox",
      checked = todo$completed,
      on_change = on_toggle
    ),

    Text(todo$text),

    if (todo$completed) {
      ui$Badge("Done", variant = "success")
    },

    ui$Button(
      "Delete",
      variant = "danger",
      size = "sm",
      on_click = on_delete
    )
  )
}
