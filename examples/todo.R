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

  tags$div(
    class_name = "todo-app",

    tags$h1("My TODO List ✨"),

    # Add input section
    tags$div(
      class_name = "todo-input",
      tags$input(
        type = "text",
        value = input_text(),
        placeholder = "Enter a new task...",
        on_change = \(e) {
          set_input_text(e$target$value)
        }
      ),
      tags$button(
        "Add Task",
        on_click = \() {
          if (nchar(input_text()) > 0) {
            set_todos(\(t) c(t, list(create_todo(input_text()))))
            set_input_text("")
          }
        }
      )
    ),

    # Todo list
    tags$div(
      class_name = "todo-list",
      if (length(todos()) == 0) {
        tags$p("No todos yet! Add one above.")
      } else {
        lapply(seq_along(todos()), \(i) {
          todo <- todos()[[i]]
          tags$div(
            class_name = "todo-item",
            tags$input(
              type = "checkbox",
              checked = todo$completed,
              on_change = \() {
                set_todos(\(t) {
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
              on_click = \() set_todos(\(t) t[-i])
            )
          )
        })
      }
    ),

    # Summary and actions
    tags$div(
      class_name = "todo-summary",
      tags$p(paste(
        length(todos()), "total,",
        sum(vapply(todos(), \(t) t$completed, logical(1))), "completed"
      )),
      tags$button(
        "Clear Completed",
        on_click = \() set_todos(\(t) Filter(\(todo) !todo$completed, t))
      ),
      tags$button(
        "Clear All",
        on_click = \() set_todos(list())
      )
    )
  )
}
