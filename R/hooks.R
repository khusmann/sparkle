#' React Hooks for Sparkle Components
#'
#' These functions provide access to React's hooks system from R code.
#' They bridge to the JavaScript runtime via webR.

# Global state for hook management
.sparkle_hook_state <- new.env(parent = emptyenv())
.sparkle_hook_state$counter <- 0L
.sparkle_hook_state$current_component <- NULL
.sparkle_hook_state$hook_index <- 0L

#' Use State Hook
#'
#' Creates a state variable similar to React's useState hook.
#' The state is managed by React in JavaScript, and this function
#' provides an R interface to it.
#'
#' @param initial_value The initial value for the state variable
#' @return A list with two elements:
#'   \item{value}{The current state value}
#'   \item{set}{A function to update the state}
#' @export
#' @examples
#' \dontrun{
#' Counter <- function() {
#'   count <- use_state(0)
#'   tags$div(
#'     tags$h1(paste("Count:", count$value)),
#'     tags$button("Increment", on_click = wrap_fn(\() count$set(count$value + 1)))
#'   )
#' }
#' }
use_state <- function(initial_value) {
  # Get the current hook index
  hook_idx <- .sparkle_hook_state$hook_index
  .sparkle_hook_state$hook_index <- hook_idx + 1L

  # Check if we're running in browser context (webR)
  if (exists(".sparkle_bridge", envir = .GlobalEnv)) {
    # In browser: use the JavaScript bridge
    bridge <- get(".sparkle_bridge", envir = .GlobalEnv)

    # Call JS bridge to get/set state
    # The JS side will call React.useState and store the reference
    state_obj <- bridge$use_state(initial_value, hook_idx)

    return(state_obj)
  } else {
    # Not in browser: return a mock for development/testing
    message("use_state called outside browser context (mock mode)")

    # Create a simple closure-based state for testing
    current_value <- initial_value

    list(
      value = current_value,
      set = function(new_value) {
        if (is.function(new_value)) {
          # Updater function: new_value(current_value)
          current_value <<- new_value(current_value)
        } else {
          current_value <<- new_value
        }
        message("State updated to: ", current_value)
      }
    )
  }
}

#' Reset hook index (internal)
#'
#' Called before each component render to reset the hook counter.
#' This ensures hooks are called in consistent order.
#' @keywords internal
reset_hook_index <- function() {
  .sparkle_hook_state$hook_index <- 0L
}
