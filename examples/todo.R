# Sparkle TODO List Example
# Demonstrates state management with lists and multiple state variables

library(sparkle)

TodoApp <- function() {
  todos <- use_state(list())
  counter <- use_state(1)

  # Helper to create a todo item
  create_todo <- function(number) {
    list(
      id = as.numeric(Sys.time()) * 1000 + sample.int(1000, 1),
      text = paste("Task", number),
      completed = FALSE
    )
  }

  tags$div(
    class_name = "todo-app",

    tags$h1("My TODO List ✨"),

    # Add button section
    tags$div(
      class_name = "todo-input",
      tags$button(
        "Add New Task",
        on_click = \() {
          todos$update(\(t) c(t, list(create_todo(counter$value))))
          counter$set(counter$value + 1)
        }
      )
    ),

    # Todo list
    tags$div(
      class_name = "todo-list",
      if (length(todos$value) == 0) {
        tags$p("No todos yet! Add one above.")
      } else {
        lapply(seq_along(todos$value), \(i) {
          todo <- todos$value[[i]]
          tags$div(
            class_name = "todo-item",
            tags$input(
              type = "checkbox",
              checked = todo$completed,
              on_change = \() {
                todos$update(\(t) {
                  t[[i]]$completed <- !t[[i]]$completed
                  t
                })
              }
            ),
            tags$span(
              class_name = if (todo$completed) "completed" else "",
              todo$text
            ),
            tags$button(
              "Delete",
              on_click = \() todos$update(\(t) t[-i])
            )
          )
        })
      }
    ),

    # Summary and actions
    tags$div(
      class_name = "todo-summary",
      tags$p(paste(
        length(todos$value), "total,",
        sum(vapply(todos$value, \(t) t$completed, logical(1))), "completed"
      )),
      tags$button(
        "Clear Completed",
        on_click = \() todos$update(\(t) Filter(\(todo) !todo$completed, t))
      ),
      tags$button(
        "Clear All",
        on_click = \() todos$set(list())
      )
    )
  )
}

# Launch the app
sparkle_app(TodoApp, port = 3000)
