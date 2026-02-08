#' Core Styling Infrastructure for Sparkle
#'
#' This file contains the internal functions for CSS generation,
#' class naming, and style registry management.
#'
#' @name styled-core
#' @keywords internal
NULL

# Environment to track generated styles (persists across renders)
# Only initialize if not already present (e.g., created by webR bridge)
if (!exists(".sparkle_styles")) {
  .sparkle_styles <- new.env(parent = emptyenv())
}

# Counter for generating unique class names
# Only initialize if not already present (e.g., created by webR bridge)
if (!exists(".style_counter")) {
  .style_counter <- 0
}

#' Generate unique class name
#'
#' Generates a unique class name for a CSS rule. Uses a simple counter
#' to ensure uniqueness without dependencies.
#'
#' @param css_content Character string containing CSS rules
#' @return A unique class name string (e.g., "sparkle-s1", "sparkle-s2")
#' @keywords internal
generate_class_name <- function(css_content) {
  .style_counter <<- .style_counter + 1
  paste0("sparkle-s", .style_counter)
}

#' Register a style and return its class name
#'
#' Stores CSS rules in the global style registry and returns the class name.
#' If the same CSS is registered multiple times, it reuses the existing class.
#'
#' @param css_rules Character string containing CSS rules
#' @return The class name for this style
#' @keywords internal
register_style <- function(css_rules) {
  # Check if this CSS already exists in registry
  existing_classes <- ls(.sparkle_styles)

  for (class_name in existing_classes) {
    if (identical(get(class_name, envir = .sparkle_styles), css_rules)) {
      # Reuse existing class name
      return(class_name)
    }
  }

  # Generate new class name and register
  class_name <- generate_class_name(css_rules)
  assign(class_name, css_rules, envir = .sparkle_styles)

  class_name
}

#' Create a <style> tag with all registered styles
#'
#' Collects all CSS from the style registry and creates a <style> element
#' containing all registered styles. This should be injected into the
#' component tree to ensure styles are available in the DOM.
#'
#' @return A sparkle_element representing a <style> tag, or NULL if no styles
#' @keywords internal
create_style_tag <- function() {
  class_names <- ls(.sparkle_styles)

  if (length(class_names) == 0) {
    return(NULL)
  }

  # Collect all CSS rules
  all_css <- vapply(class_names, function(class_name) {
    css_rules <- get(class_name, envir = .sparkle_styles)
    paste0(".", class_name, " { ", css_rules, " }")
  }, character(1))

  # Create style element with all CSS
  css_content <- paste(all_css, collapse = "\n")
  create_element("style", css_content)
}

#' Clear all registered styles
#'
#' Removes all styles from the registry and resets the counter.
#' Useful for testing or hot-reload scenarios.
#'
#' @keywords internal
clear_styles <- function() {
  rm(list = ls(.sparkle_styles), envir = .sparkle_styles)
  .style_counter <<- 0
}

#' Wrap component output with style tags
#'
#' Wraps a component's output to include all registered CSS styles.
#' This is called automatically by the Sparkle bridge when components render.
#'
#' @param component_output The virtual DOM output from a component
#' @return The wrapped output with styles injected
#' @keywords internal
with_styles <- function(component_output) {
  # CRITICAL: Force evaluation of component_output BEFORE creating style tag
  # R uses lazy evaluation, so App() won't run until we use component_output
  force(component_output)

  style_tag <- create_style_tag()

  if (is.null(style_tag)) {
    # No styles registered, return as-is
    return(component_output)
  }

  # Create a wrapper div with styles and content
  # The style tag comes first so CSS is available when elements render
  create_element("div",
    style_tag,
    component_output
  )
}
