# Main App component for the TODO list

App <- function() {
  c(todos, set_todos) %<-% use_state(list())
  c(input_text, set_input_text) %<-% use_state("")

  # Calculate stats
  total_count <- length(todos)
  completed_count <- sum(vapply(todos, \(t) t$completed, logical(1)))
  remaining_count <- total_count - completed_count

  ui$Container(
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
            "blob/main/examples/todo-multifile/"
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

            TodoItem(
              todo = todo,
              index = i,
              on_toggle = \() {
                set_todos(\(t) {
                  t[[i]]$completed <- !t[[i]]$completed
                  t
                })
              },
              on_delete = \() set_todos(\(t) t[-i])
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
}
