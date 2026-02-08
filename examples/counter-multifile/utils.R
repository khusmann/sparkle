# Utility functions for the counter app

#' Format count with sign
#'
#' @param n Numeric count value
#' @return Character string with formatted count
format_count <- function(n) {
  if (n > 0) {
    paste0("+", n)
  } else if (n < 0) {
    as.character(n)
  } else {
    "0"
  }
}

#' Get status message based on count
#'
#' @param n Numeric count value
#' @return Character string with status message
get_status_message <- function(n) {
  if (n == 0) {
    "Start clicking to see the magic! ✨"
  } else if (n > 0 && n <= 5) {
    "Looking good! Keep going!"
  } else if (n > 5 && n <= 10) {
    "Wow, you're on fire! 🔥"
  } else if (n > 10) {
    "Incredible! You're a clicking champion! 🏆"
  } else if (n >= -5) {
    "Going negative, interesting choice..."
  } else {
    "That's a lot of decrements! 📉"
  }
}

#' Get color for count display
#'
#' @param n Numeric count value
#' @return Character string with CSS color
get_count_color <- function(n) {
  if (n > 10) {
    "#10b981"  # Green
  } else if (n > 5) {
    "#3b82f6"  # Blue
  } else if (n > 0) {
    "#8b5cf6"  # Purple
  } else if (n < 0) {
    "#ef4444"  # Red
  } else {
    "#6b7280"  # Gray
  }
}
