#' Detect package dependencies from R files
#'
#' Uses renv for robust dependency detection across all R files.
#' Handles library(), require(), and pkg::function calls.
#'
#' @param r_files Character vector of R file paths to analyze
#' @return Character vector of unique package names (excluding sparkle)
#' @keywords internal
detect_dependencies_from_files <- function(r_files) {
  # Use renv::dependencies() for robust detection
  # This handles more complex cases than regex (e.g., pkg::function calls)

  all_deps <- character(0)

  for (file in r_files) {
    # renv::dependencies() returns a data frame with Package, File, etc.
    deps_df <- renv::dependencies(file, quiet = TRUE)

    if (nrow(deps_df) > 0) {
      all_deps <- c(all_deps, deps_df$Package)
    }
  }

  # Remove duplicates and sparkle itself
  packages <- unique(all_deps)
  packages <- packages[packages != "sparkle"]

  return(packages)
}
