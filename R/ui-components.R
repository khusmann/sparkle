#' UI Component Library
#'
#' A collection of pre-built components for Sparkle apps.
#' These components provide a cohesive design system with consistent colors,
#' spacing, and typography.
#'
#' @details
#' The \code{ui} list contains pre-built design system components:
#' \itemize{
#'   \item \code{ui$Button(label, variant, size, ...)} - Styled button with variants and sizes
#'   \item \code{ui$Card(...)} - Container with elevated styling
#'   \item \code{ui$Input(...)} - Styled text input
#'   \item \code{ui$Badge(label, variant)} - Small label or status indicator
#'   \item \code{ui$Alert(..., variant)} - Message box for important information
#'   \item \code{ui$Stack(..., direction, spacing)} - Flex container with spacing
#'   \item \code{ui$Container(..., max_width)} - Centered container with max-width
#' }
#'
#' @section Button:
#' \code{ui$Button(label, variant = "primary", size = "md", ...)}
#'
#' Variants: "primary", "secondary", "success", "danger", "warning"
#'
#' Sizes: "sm", "md", "lg"
#'
#' @section Card:
#' \code{ui$Card(...)}
#'
#' A container with elevated styling (shadow and rounded corners).
#'
#' @section Input:
#' \code{ui$Input(...)}
#'
#' A styled text input. Pass props like type, placeholder, value, on_change.
#'
#' @section Badge:
#' \code{ui$Badge(label, variant = "primary")}
#'
#' A small label or status indicator.
#'
#' @section Alert:
#' \code{ui$Alert(..., variant = "info")}
#'
#' A message box. Variants: "info", "success", "warning", "danger"
#'
#' @section Stack:
#' \code{ui$Stack(..., direction = "vertical", spacing = "md")}
#'
#' A flex container with consistent spacing.
#'
#' @section Container:
#' \code{ui$Container(..., max_width = "1200px")}
#'
#' A centered container with max-width and padding.
#'
#' @name ui
#' @export
#' @examples
#' \dontrun{
#' # Button examples
#' ui$Button("Submit", variant = "primary", size = "lg", on_click = handler)
#' ui$Button("Cancel", variant = "secondary", on_click = cancelHandler)
#'
#' # Card example
#' ui$Card(
#'   tags$h2("Card Title"),
#'   tags$p("Card content goes here")
#' )
#'
#' # Input example
#' ui$Input(
#'   type = "text",
#'   placeholder = "Enter your name",
#'   value = name(),
#'   on_change = \(e) setName(e$target$value)
#' )
#'
#' # Badge examples
#' ui$Badge("New", variant = "success")
#' ui$Badge("Beta", variant = "warning")
#'
#' # Alert examples
#' ui$Alert("Operation successful!", variant = "success")
#' ui$Alert("Please check your input", variant = "warning")
#'
#' # Stack example
#' ui$Stack(
#'   tags$div("Item 1"),
#'   tags$div("Item 2"),
#'   direction = "vertical",
#'   spacing = "md"
#' )
#'
#' # Container example
#' ui$Container(
#'   tags$h1("My App"),
#'   tags$p("Content")
#' )
#' }
ui <- list()

# Design tokens - centralized design values
.tokens <- list(
  colors = list(
    primary = "#3b82f6",
    secondary = "#6b7280",
    success = "#22c55e",
    danger = "#ef4444",
    warning = "#f59e0b",
    info = "#0ea5e9"
  ),
  spacing = list(
    xs = "4px",
    sm = "8px",
    md = "16px",
    lg = "24px",
    xl = "32px"
  ),
  radius = list(
    sm = "4px",
    md = "6px",
    lg = "8px",
    xl = "12px"
  ),
  font_sizes = list(
    sm = "14px",
    md = "16px",
    lg = "18px",
    xl = "24px"
  )
)

ui$Button <- function(label, variant = "primary", size = "md", ...) {
  # Size-based styles
  padding <- switch(size,
    sm = "6px 12px",
    lg = "14px 28px",
    "10px 20px"  # md default
  )

  font_size <- switch(size,
    sm = .tokens$font_sizes$sm,
    lg = .tokens$font_sizes$lg,
    .tokens$font_sizes$md  # md default
  )

  # Variant color
  bg_color <- .tokens$colors[[variant]]
  if (is.null(bg_color)) {
    bg_color <- .tokens$colors$primary
  }

  # Create styled button
  StyledButton <- styled_button(
    background_color = bg_color,
    color = "white",
    padding = padding,
    font_size = font_size,
    border = "none",
    border_radius = .tokens$radius$md,
    cursor = "pointer",
    font_weight = "500",
    transition = "all 0.2s ease",
    font_family = "system-ui, -apple-system, sans-serif",
    css = "
      &:hover {
        opacity: 0.9;
        transform: translateY(-1px);
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      }
      &:active {
        transform: translateY(0);
      }
      &:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }
    "
  )

  StyledButton(label, ...)
}

ui$Card <- function(...) {
  StyledCard <- styled_div(
    background_color = "white",
    border_radius = .tokens$radius$lg,
    padding = .tokens$spacing$lg,
    box_shadow = "0 4px 6px rgba(0, 0, 0, 0.1)",
    border = "1px solid #e5e7eb"
  )

  StyledCard(...)
}

ui$Input <- function(...) {
  StyledInput <- styled_input(
    padding = "10px 12px",
    border = "1px solid #d1d5db",
    border_radius = .tokens$radius$md,
    font_size = .tokens$font_sizes$md,
    font_family = "system-ui, -apple-system, sans-serif",
    width = "100%",
    transition = "border-color 0.2s ease",
    css = "
      &:focus {
        outline: none;
        border-color: #3b82f6;
        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
      }
      &::placeholder {
        color: #9ca3af;
      }
    "
  )

  StyledInput(...)
}

ui$Badge <- function(label, variant = "primary") {
  bg_color <- .tokens$colors[[variant]]
  if (is.null(bg_color)) {
    bg_color <- .tokens$colors$primary
  }

  StyledBadge <- styled_span(
    background_color = bg_color,
    color = "white",
    padding = "4px 8px",
    border_radius = .tokens$radius$sm,
    font_size = "12px",
    font_weight = "600",
    display = "inline-block"
  )

  StyledBadge(label)
}

ui$Alert <- function(..., variant = "info") {
  colors <- list(
    info = list(bg = "#dbeafe", border = "#3b82f6", text = "#1e40af"),
    success = list(bg = "#d1fae5", border = "#22c55e", text = "#065f46"),
    warning = list(bg = "#fef3c7", border = "#f59e0b", text = "#92400e"),
    danger = list(bg = "#fee2e2", border = "#ef4444", text = "#991b1b")
  )

  scheme <- colors[[variant]]
  if (is.null(scheme)) {
    scheme <- colors$info
  }

  StyledAlert <- styled_div(
    background_color = scheme$bg,
    border_left = paste0("4px solid ", scheme$border),
    color = scheme$text,
    padding = .tokens$spacing$md,
    border_radius = .tokens$radius$md,
    margin = paste(.tokens$spacing$md, "0")
  )

  StyledAlert(...)
}

ui$Stack <- function(..., direction = "vertical", spacing = "md") {
  flex_direction <- if (direction == "horizontal") "row" else "column"
  gap_value <- .tokens$spacing[[spacing]]
  if (is.null(gap_value)) {
    gap_value <- .tokens$spacing$md
  }

  StyledStack <- styled_div(
    display = "flex",
    flex_direction = flex_direction,
    gap = gap_value,
    flex_wrap = "wrap"
  )

  StyledStack(...)
}

ui$Container <- function(..., max_width = "1200px") {
  StyledContainer <- styled_div(
    max_width = max_width,
    margin = "0 auto",
    padding = paste0(.tokens$spacing$lg, " ", .tokens$spacing$md),
    width = "100%",
    box_sizing = "border-box",
    overflow_x = "hidden"
  )

  StyledContainer(...)
}
