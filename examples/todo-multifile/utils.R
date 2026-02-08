# Helper functions for the TODO app

# Helper to create a todo item
create_todo <- function(text) {
  list(
    id = as.numeric(Sys.time()) * 1000 + sample.int(1000, 1),
    text = text,
    completed = FALSE
  )
}
