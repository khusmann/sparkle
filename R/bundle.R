#' Serialize multiple R files into a single code string
#'
#' Concatenates all R files in order with file markers
#'
#' @param r_files Character vector of file paths to concatenate
#' @return Single string containing all R code
#' @keywords internal
serialize_r_files <- function(r_files) {
  all_code <- c()

  for (file in r_files) {
    all_code <- c(
      all_code,
      paste0("# File: ", basename(file)),
      readLines(file, warn = FALSE),
      ""  # blank line separator
    )
  }

  paste(all_code, collapse = "\n")
}

#' Validate that App function is defined in code
#'
#' @param serialized_code String containing R code
#' @return TRUE invisibly if valid, stops with error otherwise
#' @keywords internal
validate_app_function <- function(serialized_code) {
  # Verify that App function is defined somewhere in the code
  if (!grepl("App\\s*<-\\s*function\\s*\\(", serialized_code)) {
    stop("No 'App' function found. Please define App <- function() { ... } in one of your .R files.")
  }
  invisible(TRUE)
}

#' Create app bundle structure
#'
#' Detects dependencies, downloads packages, and creates bundle directory
#'
#' @param r_files Character vector of R file paths
#' @param bundle_dir Directory to create bundle in
#' @return List with app_code, component_name, dependencies, bundle_dir
#' @keywords internal
create_app_bundle <- function(r_files, bundle_dir) {
  # Create bundle structure:
  # bundle_dir/
  #   ├── www/           # Copy from inst/www
  #   └── repo/          # CRAN-like package repository
  #       └── bin/
  #           └── emscripten/
  #               └── contrib/
  #                   └── 4.3/
  #                       ├── PACKAGES, PACKAGES.gz, PACKAGES.rds
  #                       ├── package.tgz, package.data, package.js.metadata
  #                       └── ...

  # Detect dependencies from all files
  deps <- detect_dependencies_from_files(r_files)

  if (length(deps) > 0) {
    message("Detected dependencies: ", paste(deps, collapse = ", "))

    # Download packages
    pkg_files <- download_all_packages(deps)

    # Create CRAN-like repository structure
    repo_dir <- file.path(bundle_dir, "repo", "bin", "emscripten", "contrib", "4.3")
    dir.create(repo_dir, recursive = TRUE, showWarnings = FALSE)

    # Copy all package files to repository
    for (pkg_name in names(pkg_files)) {
      pkg_info <- pkg_files[[pkg_name]]

      for (file_type in names(pkg_info$files)) {
        src_file <- pkg_info$files[[file_type]]
        dest_file <- file.path(repo_dir, basename(src_file))
        file.copy(src_file, dest_file, overwrite = TRUE)
      }
    }

    # Generate PACKAGES index files
    generate_packages_index(repo_dir)
  } else {
    message("No dependencies detected")
  }

  # Serialize app code
  app_code <- serialize_r_files(r_files)

  # Validate that App function exists
  validate_app_function(app_code)

  return(list(
    app_code = app_code,
    component_name = "App",  # Always "App" by convention
    dependencies = if (length(deps) > 0) names(pkg_files) else character(0),
    bundle_dir = bundle_dir
  ))
}

#' Generate PACKAGES index files for repository
#'
#' Creates PACKAGES, PACKAGES.gz, and PACKAGES.rds files
#'
#' @param repo_dir Directory containing .tgz package files
#' @keywords internal
generate_packages_index <- function(repo_dir) {
  # Generate PACKAGES, PACKAGES.gz, PACKAGES.rds files
  # These are required for webR to recognize the repository

  # Get all .tgz files
  tgz_files <- list.files(repo_dir, pattern = "\\.tgz$", full.names = TRUE)

  if (length(tgz_files) == 0) {
    return(invisible(NULL))
  }

  # Use tools::write_PACKAGES to generate index files
  message("Generating PACKAGES index files...")
  tools::write_PACKAGES(
    dir = repo_dir,
    type = "binary",
    verbose = FALSE
  )
}
