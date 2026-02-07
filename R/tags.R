#' HTML Tag Builders
#'
#' Create virtual DOM descriptions for HTML elements. These functions return
#' list structures that the Sparkle JavaScript bridge converts into React elements.
#'
#' @name tags
#' @export
tags <- list()

#' Create a virtual DOM element
#'
#' @param tag Character string specifying the HTML tag name
#' @param ... Named arguments become props, unnamed arguments become children
#' @return A list representing a virtual DOM element
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
      props[[prop_names[i]]] <- args[[i]]
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

#' @rdname tags
#' @export
tags$div <- function(...) create_element("div", ...)

#' @rdname tags
#' @export
tags$button <- function(...) create_element("button", ...)

#' @rdname tags
#' @export
tags$h1 <- function(...) create_element("h1", ...)

#' @rdname tags
#' @export
tags$h2 <- function(...) create_element("h2", ...)

#' @rdname tags
#' @export
tags$h3 <- function(...) create_element("h3", ...)

#' @rdname tags
#' @export
tags$p <- function(...) create_element("p", ...)

#' @rdname tags
#' @export
tags$span <- function(...) create_element("span", ...)

#' @rdname tags
#' @export
tags$input <- function(...) create_element("input", ...)

#' @rdname tags
#' @export
tags$label <- function(...) create_element("label", ...)

#' Print method for sparkle elements
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
