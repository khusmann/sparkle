#' Event Callback Wrapper
#'
#' Wraps R functions for use as event handlers in Sparkle components.
#' The wrapped function will be serialized and executed asynchronously
#' when the event fires.

#' Wrap a function for use as an event callback (internal)
#'
#' This function wraps an R function so it can be used as an event handler
#' (e.g., on_click, on_change). The function will be serialized and executed
#' asynchronously in webR when the event fires.
#'
#' This is now an internal function - event handlers are automatically wrapped.
#'
#' @param fn An R function to wrap. Can be anonymous: \code{\\() expr}
#' @return A wrapped function object that can be passed to event props
#' @keywords internal
wrap_fn <- function(fn) {
  if (!is.function(fn)) {
    stop("wrap_fn requires a function argument")
  }

  # Create a unique ID for this callback
  callback_id <- paste0("cb_", format(as.numeric(Sys.time()) * 1000, scientific = FALSE), "_", sample.int(10000, 1))

  # Store the function in a global registry
  # This will be accessible when the callback is invoked
  if (!exists(".sparkle_callbacks", envir = .GlobalEnv)) {
    assign(".sparkle_callbacks", new.env(parent = emptyenv()), envir = .GlobalEnv)
  }

  callbacks <- get(".sparkle_callbacks", envir = .GlobalEnv)
  assign(callback_id, fn, envir = callbacks)

  # Return a structure that the JS bridge can recognize
  # Only return the callback_id - the function is already stored in the registry
  structure(
    list(
      callback_id = callback_id
    ),
    class = "sparkle_callback"
  )
}

#' Invoke a registered callback (internal)
#'
#' Called by the JavaScript bridge to execute a wrapped callback.
#' This function is called from JavaScript via webR when an event fires.
#'
#' @param callback_id The ID of the callback to invoke
#' @param args Arguments to pass to the callback (default: empty list)
#' @return The result of the callback function
#' @keywords internal
#' @export
invoke_callback <- function(callback_id, args = list()) {
  if (!exists(callback_id, envir = .sparkle_callbacks)) {
    stop("Callback not found: ", callback_id)
  }
  fn <- get(callback_id, envir = .sparkle_callbacks)

  # Extract and store sequence number if present in event data
  if (!is.null(args$e$`__sparkle_sequence`)) {
    .sparkle_hook_state$current_event_sequence <- args$e$`__sparkle_sequence`
  } else {
    .sparkle_hook_state$current_event_sequence <- NULL
  }

  # Check if function accepts arguments
  fn_formals <- formals(fn)

  # If function has no parameters and we're trying to pass args, call without args
  if (length(fn_formals) == 0 && length(args) > 0) {
    return(fn())
  }

  # Otherwise use do.call to pass arguments
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
