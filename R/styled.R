#' Styled Components for Sparkle
#'
#' Create styled components with CSS-in-R. These functions return factory functions
#' that create elements with automatically generated CSS classes.
#'
#' @name styled-components
NULL

#' Convert snake_case to kebab-case for CSS properties
#'
#' @param str Character string in snake_case
#' @return Character string in kebab-case
#' @keywords internal
#' @examples
#' \dontrun{
#' snake_to_kebab("background_color")  # "background-color"
#' snake_to_kebab("font_size")         # "font-size"
#' }
snake_to_kebab <- function(str) {
  gsub("_", "-", str)
}

#' Convert R style props to CSS string
#'
#' Takes a named list of style properties and converts them to a CSS string.
#' Property names are converted from snake_case to kebab-case.
#'
#' @param props Named list of style properties
#' @return Character string containing CSS declarations
#' @keywords internal
#' @examples
#' \dontrun{
#' style_props_to_css(list(
#'   background_color = "red",
#'   font_size = "16px",
#'   padding = "10px"
#' ))
#' # Returns: "background-color: red; font-size: 16px; padding: 10px;"
#' }
style_props_to_css <- function(props) {
  if (length(props) == 0) {
    return("")
  }

  css_parts <- vapply(names(props), function(name) {
    value <- props[[name]]
    css_name <- snake_to_kebab(name)
    paste0(css_name, ": ", value, ";")
  }, character(1))

  paste(css_parts, collapse = " ")
}

#' Create a styled component
#'
#' Creates a factory function that generates elements with automatically
#' generated CSS classes. The CSS is registered globally and injected
#' into the document.
#'
#' @param tag HTML tag name (e.g., "div", "button", "span")
#' @param ... Style properties as named arguments (snake_case)
#' @param css Additional CSS string for advanced styling (pseudo-classes, media queries)
#' @return A function that creates styled elements
#' @keywords internal
#' @examples
#' \dontrun{
#' # Create a custom button
#' MyButton <- create_styled_component(
#'   "button",
#'   background_color = "blue",
#'   color = "white",
#'   padding = "10px 20px",
#'   css = "&:hover { background-color: darkblue; }"
#' )
#'
#' # Use it
#' MyButton("Click me", on_click = handler)
#' }
create_styled_component <- function(tag, ..., css = NULL) {
  style_props <- list(...)

  # Convert R style props to CSS
  css_from_props <- style_props_to_css(style_props)

  # Combine with custom CSS
  css_parts <- c(css_from_props, css)
  css_parts <- css_parts[!is.null(css_parts) & nchar(css_parts) > 0]
  full_css <- paste(css_parts, collapse = " ")

  # Register style and get class name
  class_name <- register_style(full_css)

  # Return a factory function that creates elements with this style
  function(...) {
    args <- list(...)

    # Merge with any user-provided class_name
    if ("class_name" %in% names(args)) {
      args$class_name <- paste(class_name, args$class_name)
    } else {
      args$class_name <- class_name
    }

    # Create element with the tag and merged args
    do.call(create_element, c(list(tag = tag), args))
  }
}

#' Create a styled div
#'
#' Creates a factory function for styled div elements.
#'
#' @param ... Style properties as named arguments (use snake_case)
#' @param css Additional CSS string for advanced styling
#' @return A function that creates styled div elements
#' @export
#' @examples
#' \dontrun{
#' Container <- styled_div(
#'   max_width = "800px",
#'   margin = "0 auto",
#'   padding = "20px"
#' )
#'
#' Container(
#'   tags$h1("Hello"),
#'   tags$p("Content")
#' )
#' }
styled_div <- function(..., css = NULL) {
  create_styled_component("div", ..., css = css)
}

#' Create a styled button
#'
#' Creates a factory function for styled button elements.
#'
#' @param ... Style properties as named arguments (use snake_case)
#' @param css Additional CSS string for advanced styling
#' @return A function that creates styled button elements
#' @export
#' @examples
#' \dontrun{
#' PrimaryButton <- styled_button(
#'   background_color = "#007bff",
#'   color = "white",
#'   border = "none",
#'   padding = "10px 20px",
#'   border_radius = "4px",
#'   cursor = "pointer",
#'   css = "
#'     &:hover { background-color: #0056b3; }
#'     &:active { transform: translateY(1px); }
#'   "
#' )
#'
#' PrimaryButton("Submit", on_click = handler)
#' }
styled_button <- function(..., css = NULL) {
  create_styled_component("button", ..., css = css)
}

#' Create a styled input
#'
#' Creates a factory function for styled input elements.
#'
#' @param ... Style properties as named arguments (use snake_case)
#' @param css Additional CSS string for advanced styling
#' @return A function that creates styled input elements
#' @export
#' @examples
#' \dontrun{
#' StyledInput <- styled_input(
#'   padding = "8px 12px",
#'   border = "1px solid #ddd",
#'   border_radius = "4px",
#'   font_size = "14px",
#'   css = "&:focus { border-color: #007bff; outline: none; }"
#' )
#'
#' StyledInput(
#'   type = "text",
#'   placeholder = "Enter text",
#'   value = value(),
#'   on_change = handler
#' )
#' }
styled_input <- function(..., css = NULL) {
  create_styled_component("input", ..., css = css)
}

#' Create a styled span
#'
#' Creates a factory function for styled span elements.
#'
#' @param ... Style properties as named arguments (use snake_case)
#' @param css Additional CSS string for advanced styling
#' @return A function that creates styled span elements
#' @export
styled_span <- function(..., css = NULL) {
  create_styled_component("span", ..., css = css)
}

#' Create a styled paragraph
#'
#' Creates a factory function for styled p elements.
#'
#' @param ... Style properties as named arguments (use snake_case)
#' @param css Additional CSS string for advanced styling
#' @return A function that creates styled p elements
#' @export
styled_p <- function(..., css = NULL) {
  create_styled_component("p", ..., css = css)
}

#' Create a styled h1 heading
#'
#' Creates a factory function for styled h1 elements.
#'
#' @param ... Style properties as named arguments (use snake_case)
#' @param css Additional CSS string for advanced styling
#' @return A function that creates styled h1 elements
#' @export
styled_h1 <- function(..., css = NULL) {
  create_styled_component("h1", ..., css = css)
}

#' Create a styled h2 heading
#'
#' Creates a factory function for styled h2 elements.
#'
#' @param ... Style properties as named arguments (use snake_case)
#' @param css Additional CSS string for advanced styling
#' @return A function that creates styled h2 elements
#' @export
styled_h2 <- function(..., css = NULL) {
  create_styled_component("h2", ..., css = css)
}

#' Create a styled h3 heading
#'
#' Creates a factory function for styled h3 elements.
#'
#' @param ... Style properties as named arguments (use snake_case)
#' @param css Additional CSS string for advanced styling
#' @return A function that creates styled h3 elements
#' @export
styled_h3 <- function(..., css = NULL) {
  create_styled_component("h3", ..., css = css)
}

#' Create a styled label
#'
#' Creates a factory function for styled label elements.
#'
#' @param ... Style properties as named arguments (use snake_case)
#' @param css Additional CSS string for advanced styling
#' @return A function that creates styled label elements
#' @export
styled_label <- function(..., css = NULL) {
  create_styled_component("label", ..., css = css)
}
