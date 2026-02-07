# Sparkle TODO List Example
# Demonstrates state management with lists and multiple state variables

library(sparkle)
library(zeallot)

TodoApp <- function() {
  c(todos, setTodos) %<-% use_state(list())
  c(inputText, setInputText) %<-% use_state("")

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
        value = inputText(),
        placeholder = "Enter a new task...",
        on_change = \(e) {
          setInputText(e$target$value)
        }
      ),
      tags$button(
        "Add Task",
        on_click = \() {
          if (nchar(inputText()) > 0) {
            setTodos(\(t) c(t, list(create_todo(inputText()))))
            setInputText("")
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
                setTodos(\(t) {
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
              on_click = \() setTodos(\(t) t[-i])
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
        on_click = \() setTodos(\(t) Filter(\(todo) !todo$completed, t))
      ),
      tags$button(
        "Clear All",
        on_click = \() setTodos(list())
      )
    )
  )
}

# Launch the app
sparkle_app(TodoApp, port = 3000)
