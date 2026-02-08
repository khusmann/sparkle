# Sparkle TODO List Example
# Demonstrates state management with lists and multiple state variables
#
# Run with: sparkle_app("examples/todo.R")

library(sparkle)
library(zeallot)

App <- function() {
  c(todos, set_todos) %<-% use_state(list())
  c(input_text, set_input_text) %<-% use_state("")

  # Helper to create a todo item
  create_todo <- function(text) {
    list(
      id = as.numeric(Sys.time()) * 1000 + sample.int(1000, 1),
      text = text,
      completed = FALSE
    )
  }

  # Calculate stats
  total_count <- length(todos)
  completed_count <- sum(vapply(todos, \(t) t$completed, logical(1)))
  remaining_count <- total_count - completed_count

  result <- ui$Container(
    max_width = "800px",

    # Header
    tags$div(
      style = list(text_align = "center", margin_bottom = "30px"),
      tags$h1("My TODO List ✨"),
      tags$p(
        "Stay organized and get things done! ",
        tags$a(
          "View source",
          href = paste0(
            "https://github.com/khusmann/sparkle/",
            "blob/main/examples/todo.R"
          )
        )
      )
    ),

    # Add task card
    ui$Card(
      tags$h3("Add New Task", style = list(margin_top = "0")),
      ui$Stack(
        direction = "horizontal",
        spacing = "sm",

        tags$div(
          style = list(flex = "1"),
          ui$Input(
            type = "text",
            value = input_text,
            placeholder = "Enter a new task...",
            on_change = \(e) set_input_text(e$target$value),
            on_key_down = \(e) {
              if (e$key == "Enter" && nchar(input_text) > 0) {
                set_todos(\(t) c(t, list(create_todo(input_text))))
                set_input_text("")
              }
            }
          )
        ),

        ui$Button(
          "Add Task",
          variant = "primary",
          size = "md",
          on_click = \() {
            if (nchar(input_text) > 0) {
              set_todos(\(t) c(t, list(create_todo(input_text))))
              set_input_text("")
            }
          }
        )
      )
    ),

    # Stats summary
    if (total_count > 0) {
      ui$Card(
        ui$Stack(
          direction = "horizontal",
          spacing = "md",

          tags$div(
            style = list(flex = "1", text_align = "center"),
            tags$div(
              style = list(font_size = "32px", font_weight = "bold", color = "#3b82f6"),
              total_count
            ),
            tags$div(
              style = list(font_size = "14px", color = "#6b7280"),
              "Total"
            )
          ),

          tags$div(
            style = list(flex = "1", text_align = "center"),
            tags$div(
              style = list(font_size = "32px", font_weight = "bold", color = "#22c55e"),
              completed_count
            ),
            tags$div(
              style = list(font_size = "14px", color = "#6b7280"),
              "Completed"
            )
          ),

          tags$div(
            style = list(flex = "1", text_align = "center"),
            tags$div(
              style = list(font_size = "32px", font_weight = "bold", color = "#f59e0b"),
              remaining_count
            ),
            tags$div(
              style = list(font_size = "14px", color = "#6b7280"),
              "Remaining"
            )
          )
        )
      )
    },

    # Todo list
    ui$Card(
      tags$div(
        style = list(
          display = "flex",
          justify_content = "space-between",
          align_items = "center",
          margin_bottom = "16px"
        ),
        tags$h3(style = list(margin = "0"), "Tasks"),
        if (completed_count > 0) {
          ui$Button(
            "Clear Completed",
            variant = "secondary",
            size = "sm",
            on_click = \() set_todos(\(t) Filter(\(todo) !todo$completed, t))
          )
        }
      ),

      if (length(todos) == 0) {
        ui$Alert(
          "No todos yet! Add one above to get started.",
          variant = "info"
        )
      } else {
        ui$Stack(
          direction = "vertical",
          spacing = "sm",

          lapply(seq_along(todos), \(i) {
            todo <- todos[[i]]

            TodoItem <- styled_div(
              display = "flex",
              align_items = "center",
              gap = "12px",
              padding = "12px",
              border_radius = "6px",
              background_color = if (todo$completed) "#f9fafb" else "white",
              border = "1px solid #e5e7eb",
              transition = "all 0.2s ease",
              css = "
                &:hover {
                  border-color: #d1d5db;
                  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
                }
              "
            )

            TodoText <- styled_span(
              flex = "1",
              font_size = "16px",
              color = if (todo$completed) "#9ca3af" else "#111827",
              text_decoration = if (todo$completed) "line-through" else "none",
              transition = "all 0.2s ease"
            )

            TodoItem(
              tags$input(
                type = "checkbox",
                checked = todo$completed,
                style = list(
                  width = "20px",
                  height = "20px",
                  cursor = "pointer"
                ),
                on_change = \() {
                  set_todos(\(t) {
                    t[[i]]$completed <- !t[[i]]$completed
                    t
                  })
                }
              ),

              TodoText(todo$text),

              if (todo$completed) {
                ui$Badge("Done", variant = "success")
              },

              ui$Button(
                "Delete",
                variant = "danger",
                size = "sm",
                on_click = \() set_todos(\(t) t[-i])
              )
            )
          })
        )
      }
    ),

    # Clear all button
    if (total_count > 0) {
      tags$div(
        style = list(text_align = "center", margin_top = "20px"),
        ui$Button(
          "Clear All Tasks",
          variant = "danger",
          size = "md",
          on_click = \() set_todos(list())
        )
      )
    }
  )

  # Wrap with style tag to inject CSS
  tags$div(
    result,
    create_style_tag()
  )
}
