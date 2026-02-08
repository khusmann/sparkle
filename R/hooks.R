#' React Hooks for Sparkle Components
#'
#' These functions provide access to React's hooks system from R code.
#' They manage state that bridges to React via the JavaScript runtime.

#' Global state accessor functions (internal)
#'
#' Get the current value of a state variable by its index.
#' This is used internally by state object methods and callbacks.
#'
#' @param index The index of the state variable
#' @return The current value of the state
#' @keywords internal
sparkle_get_state <- function(index) {
  .sparkle_hook_state$state_values[[index + 1]]
}

#' Set the value of a state variable (internal)
#'
#' Update a state variable and signal to JavaScript that state has changed.
#' This triggers a re-render of the component.
#'
#' @param index The index of the state variable
#' @param value The new value
#' @return A list signaling the state update to JavaScript
#' @keywords internal
sparkle_set_state <- function(index, value) {
  .sparkle_hook_state$state_values[[index + 1]] <- value
  # Signal to JS that state changed - return special marker
  list(
    sparkle_state_update = TRUE,
    index = index,
    value = value
  )
}

#' Use State Hook
#'
#' Creates a state variable similar to React's useState hook.
#' The state is managed by React in JavaScript, and this function
#' provides an R interface to it.
#'
#' Designed to work with the zeallot package for destructuring assignment:
#' c(value, setValue) %<-% use_state(initial)
#'
#' @param initial_value The initial value for the state variable
#' @return A 2-element list containing:
#'   \item{1}{The current state value}
#'   \item{2}{A setter function(new_value_or_fn) that updates state. Pass a value to set it directly, or a function(old_value) -> new_value for updates based on previous state}
#' @export
#' @examples
#' \dontrun{
#' library(zeallot)
#'
#' Counter <- function() {
#'   c(count, setCount) %<-% use_state(0)
#'   tags$div(
#'     tags$h1(paste("Count:", count)),
#'     tags$button("Increment", on_click = \() setCount(\(c) c + 1)),
#'     tags$button("Reset", on_click = \() setCount(0))
#'   )
#' }
#'
#' # Functional updates (pass a function to setter)
#' TodoApp <- function() {
#'   c(todos, setTodos) %<-% use_state(list())
#'   tags$button(
#'     "Add Item",
#'     on_click = \() setTodos(\(t) c(t, list("New item")))
#'   )
#' }
#' }
use_state <- function(initial_value) {
  # Get current hook index
  hook_idx <- .sparkle_hook_state$hook_index
  .sparkle_hook_state$hook_index <- hook_idx + 1L

  # Initialize state if first call
  if (length(.sparkle_hook_state$state_values) < hook_idx + 1) {
    .sparkle_hook_state$state_values[[hook_idx + 1]] <- initial_value
  }

  # Get current value
  value <- sparkle_get_state(hook_idx)

  # Create setter function
  setter <- function(new_value_or_fn) {
    if (is.function(new_value_or_fn)) {
      # Functional update: apply function to current value
      current <- sparkle_get_state(hook_idx)
      new_value <- new_value_or_fn(current)
      sparkle_set_state(hook_idx, new_value)
    } else {
      # Direct update: set to new value
      sparkle_set_state(hook_idx, new_value_or_fn)
    }
  }

  # Return list for zeallot unpacking
  list(value, setter)
}

#' Reset hook index (internal)
#'
#' Called before each component render to reset the hook counter.
#' This ensures hooks are called in consistent order.
#' @keywords internal
reset_hooks <- function() {
  .sparkle_hook_state$hook_index <- 0L
}
