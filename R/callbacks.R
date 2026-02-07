#' Event Callback Wrapper
#'
#' Wraps R functions for use as event handlers in Sparkle components.
#' The wrapped function will be serialized and executed asynchronously
#' when the event fires.

#' Wrap a function for use as an event callback
#'
#' This function wraps an R function so it can be used as an event handler
#' (e.g., on_click, on_change). The function will be serialized and executed
#' asynchronously in webR when the event fires.
#'
#' @param fn An R function to wrap. Can be anonymous: \code{\\() expr}
#' @return A wrapped function object that can be passed to event props
#' @export
#' @examples
#' \dontrun{
#' tags$button(
#'   "Click me",
#'   on_click = wrap_fn(\() {
#'     print("Button clicked!")
#'   })
#' )
#' }
wrap_fn <- function(fn) {
  if (!is.function(fn)) {
    stop("wrap_fn requires a function argument")
  }

  # Create a unique ID for this callback
  callback_id <- paste0("cb_", as.integer(Sys.time() * 1000), "_", sample.int(10000, 1))

  # Store the function in a global registry
  # This will be accessible when the callback is invoked
  if (!exists(".sparkle_callbacks", envir = .GlobalEnv)) {
    assign(".sparkle_callbacks", new.env(parent = emptyenv()), envir = .GlobalEnv)
  }

  callbacks <- get(".sparkle_callbacks", envir = .GlobalEnv)
  assign(callback_id, fn, envir = callbacks)

  # Return a structure that the JS bridge can recognize
  structure(
    list(
      callback_id = callback_id,
      fn = fn
    ),
    class = "sparkle_callback"
  )
}

#' Invoke a registered callback (internal)
#'
#' Called by the JavaScript bridge to execute a wrapped callback.
#' @param callback_id The ID of the callback to invoke
#' @param args Arguments to pass to the callback
#' @return The result of the callback function
#' @keywords internal
invoke_callback <- function(callback_id, args = list()) {
  if (!exists(".sparkle_callbacks", envir = .GlobalEnv)) {
    stop("Callback registry not initialized")
  }

  callbacks <- get(".sparkle_callbacks", envir = .GlobalEnv)

  if (!exists(callback_id, envir = callbacks)) {
    stop("Callback not found: ", callback_id)
  }

  fn <- get(callback_id, envir = callbacks)
  do.call(fn, args)
}

#' Print method for sparkle callbacks
#'
#' @param x A sparkle_callback object
#' @param ... Additional arguments (ignored)
#' @return Invisibly returns the input object
#' @export
print.sparkle_callback <- function(x, ...) {
  cat("<sparkle_callback:", x$callback_id, ">\n")
  invisible(x)
}
