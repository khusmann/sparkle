#' HTML Tag Builders
#'
#' Create virtual DOM descriptions for HTML elements. These functions return
#' list structures that the Sparkle JavaScript bridge converts into React elements.
#'
#' @details
#' The \code{tags} list contains functions for creating common HTML elements:
#' \itemize{
#'   \item \code{tags$div(...)} - Create a div element
#'   \item \code{tags$button(...)} - Create a button element
#'   \item \code{tags$h1(...)}, \code{tags$h2(...)}, \code{tags$h3(...)} - Create heading elements
#'   \item \code{tags$p(...)} - Create a paragraph element
#'   \item \code{tags$span(...)} - Create a span element
#'   \item \code{tags$input(...)} - Create an input element
#'   \item \code{tags$label(...)} - Create a label element
#' }
#'
#' @param ... For tag functions: named arguments become props (attributes),
#'   unnamed arguments become children (content)
#'
#' @return A list with class \code{sparkle_element} representing a virtual DOM element
#'
#' @examples
#' \dontrun{
#' # Simple element
#' tags$div("Hello, world!")
#'
#' # Element with props
#' tags$div(class_name = "container", "Content here")
#'
#' # Nested elements
#' tags$div(
#'   tags$h1("Title"),
#'   tags$p("Paragraph text")
#' )
#'
#' # Element with event handler (auto-wrapped)
#' tags$button(
#'   "Click me",
#'   on_click = \() print("Clicked!")
#' )
#' }
#'
#' @name tags
#' @export
tags <- list()

#' Check if a prop name is an event handler
#'
#' Event handler props start with "on_" (e.g., on_click, on_change)
#'
#' @param prop_name Character string with the prop name
#' @return TRUE if this is an event handler prop, FALSE otherwise
#' @keywords internal
is_event_handler_prop <- function(prop_name) {
  grepl("^on_", prop_name)
}

#' Create a virtual DOM element
#'
#' @param tag Character string specifying the HTML tag name
#' @param ... Named arguments become props, unnamed arguments become children
#' @return A list representing a virtual DOM element
#' @keywords internal
create_element <- function(tag, ...) {
  args <- list(...)

  # Separate named (props) and unnamed (children) arguments
  prop_names <- names(args)
  if (is.null(prop_names)) {
    prop_names <- rep("", length(args))
  }

  props <- list()
  children <- list()

  for (i in seq_along(args)) {
    if (prop_names[i] != "") {
      # Named argument = prop
      prop_value <- args[[i]]

      # AUTO-WRAP: If event handler prop and function, wrap it
      if (is_event_handler_prop(prop_names[i]) && is.function(prop_value)) {
        # Check if already wrapped to avoid double-wrapping
        if (!inherits(prop_value, "sparkle_callback")) {
          prop_value <- wrap_fn(prop_value)
        }
      }

      props[[prop_names[i]]] <- prop_value
    } else {
      # Unnamed argument = child
      children <- append(children, list(args[[i]]))
    }
  }

  structure(
    list(
      tag = tag,
      props = props,
      children = children
    ),
    class = "sparkle_element"
  )
}

# Define tag functions (not individually documented to avoid roxygen2 issues)
tags$div <- function(...) create_element("div", ...)
tags$button <- function(...) create_element("button", ...)
tags$h1 <- function(...) create_element("h1", ...)
tags$h2 <- function(...) create_element("h2", ...)
tags$h3 <- function(...) create_element("h3", ...)
tags$p <- function(...) create_element("p", ...)
tags$span <- function(...) create_element("span", ...)
tags$input <- function(...) create_element("input", ...)
tags$label <- function(...) create_element("label", ...)
tags$br <- function(...) create_element("br", ...)
tags$strong <- function(...) create_element("strong", ...)
tags$a <- function(...) create_element("a", ...)

#' Print method for sparkle elements
#'
#' @param x A sparkle_element object
#' @param ... Additional arguments (ignored)
#' @return Invisibly returns the input object
#' @export
print.sparkle_element <- function(x, ...) {
  cat("<sparkle_element:", x$tag, ">\n")
  if (length(x$props) > 0) {
    cat("  Props:", paste(names(x$props), collapse = ", "), "\n")
  }
  if (length(x$children) > 0) {
    cat("  Children:", length(x$children), "\n")
  }
  invisible(x)
}
