#' React Hooks for Sparkle Components
#'
#' These functions provide access to React's hooks system from R code.
#' They manage state that bridges to React via the JavaScript runtime.

#' Global state accessor functions
#'
#' Get the current value of a state variable by its index.
#' This is used internally by callbacks to access state.
#'
#' @param index The index of the state variable
#' @return The current value of the state
#' @export
sparkle_get_state <- function(index) {
  .sparkle_hook_state$state_values[[index + 1]]
}

#' Set the value of a state variable
#'
#' Update a state variable and signal to JavaScript that state has changed.
#' This triggers a re-render of the component.
#'
#' @param index The index of the state variable
#' @param value The new value
#' @return A list signaling the state update to JavaScript
#' @export
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
#' @return A list with two elements:
#'   \item{index}{The index of this state variable (for use in callbacks)}
#'   \item{value}{The current state value}
#' @export
#' @examples
#' \dontrun{
#' Counter <- function() {
#'   count <- use_state(0)
#'   tags$div(
#'     tags$h1(paste("Count:", count$value)),
#'     tags$button(
#'       "Increment",
#'       on_click = wrap_fn(function() {
#'         current <- sparkle_get_state(count$index)
#'         sparkle_set_state(count$index, current + 1)
#'       })
#'     )
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

  # Return state index for use in callbacks
  list(
    index = hook_idx,
    value = current_value
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
