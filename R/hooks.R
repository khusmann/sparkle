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
#' @param initial_value The initial value for the state variable
#' @return A sparkle_state object with:
#'   \item{value}{The current state value (read-only)}
#'   \item{set(new_value)}{Method to update state to a new value}
#'   \item{update(fn)}{Method to update state using a function: fn(old_value) -> new_value}
#' @export
#' @examples
#' \dontrun{
#' Counter <- function() {
#'   count <- use_state(0)
#'   tags$div(
#'     tags$h1(paste("Count:", count$value)),
#'     tags$button("Increment", on_click = \() count$set(count$value + 1)),
#'     tags$button("Reset", on_click = \() count$set(0))
#'   )
#' }
#'
#' # Functional updates
#' TodoApp <- function() {
#'   todos <- use_state(list())
#'   tags$button(
#'     "Add Item",
#'     on_click = \() todos$update(\(t) c(t, list("New item")))
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
  current_value <- .sparkle_hook_state$state_values[[hook_idx + 1]]

  # Return S3 class with state methods
  structure(
    list(
      index = hook_idx,
      value = current_value
    ),
    class = "sparkle_state"
  )
}

#' Reset hook index (internal)
#'
#' Called before each component render to reset the hook counter.
#' This ensures hooks are called in consistent order.
#' @keywords internal
reset_hooks <- function() {
  .sparkle_hook_state$hook_index <- 0L
}

#' Access sparkle_state methods
#'
#' Provides method access for state objects returned by use_state().
#'
#' @param x A sparkle_state object
#' @param name The method or field name being accessed
#' @return For 'set': a function(new_value) that updates state
#'   For 'update': a function(fn) that applies fn to current value
#'   For other names: the underlying list element
#' @export
`$.sparkle_state` <- function(x, name) {
  if (name == "set") {
    # Return a setter function bound to this state's index
    function(new_value) {
      sparkle_set_state(x$index, new_value)
    }
  } else if (name == "update") {
    # Return an updater function for functional updates
    function(update_fn) {
      if (!is.function(update_fn)) {
        stop("update() requires a function argument")
      }
      current <- sparkle_get_state(x$index)
      new_value <- update_fn(current)
      sparkle_set_state(x$index, new_value)
    }
  } else {
    # Default: access the underlying list element
    NextMethod()
  }
}

#' Prevent direct assignment to sparkle_state fields
#'
#' Prevents users from directly modifying state object fields,
#' which would bypass React's re-render mechanism.
#'
#' @param x A sparkle_state object
#' @param name The field name being assigned to
#' @param value The value being assigned
#' @export
`$<-.sparkle_state` <- function(x, name, value) {
  if (name %in% c("value", "index")) {
    stop("Cannot directly assign to '", name, "'. Use $set() method instead.")
  }
  NextMethod()
}

#' Print method for sparkle_state objects
#'
#' @param x A sparkle_state object
#' @param ... Additional arguments (ignored)
#' @return Invisibly returns the input object
#' @export
print.sparkle_state <- function(x, ...) {
  cat("<sparkle_state: value=", deparse(x$value), ">\n", sep = "")
  invisible(x)
}
