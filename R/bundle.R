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
    message("Downloaded packages: ", paste(names(pkg_files), collapse = ", "))

    # Create CRAN-like repository structure
    # Use R 4.5 to match webR's current version
    repo_dir <- file.path(bundle_dir, "repo", "bin", "emscripten", "contrib", "4.5")
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
  message("DEBUG: repo_dir = ", repo_dir)
  message("DEBUG: .tgz files = ", paste(basename(tgz_files), collapse = ", "))

  # Try to generate PACKAGES with error handling
  tryCatch({
    # For webR binary packages, we need to unpack the .tgz to extract DESCRIPTION
    # then use write_PACKAGES. But for now, let's try with type = "mac.binary"
    # which also uses .tgz format
    tools::write_PACKAGES(
      dir = repo_dir,
      type = "mac.binary",  # Binary packages in .tgz format
      verbose = TRUE
    )
    message("DEBUG: write_PACKAGES completed")
  }, error = function(e) {
    message("DEBUG: write_PACKAGES failed: ", e$message)
    message("DEBUG: Trying manual PACKAGES generation...")

    # Manually create a basic PACKAGES file
    # This is a fallback if write_PACKAGES doesn't work
    create_manual_packages_index(repo_dir, tgz_files)
  })

  # Verify PACKAGES files were created
  packages_file <- file.path(repo_dir, "PACKAGES")
  if (file.exists(packages_file)) {
    message("DEBUG: PACKAGES file created successfully")
    message("DEBUG: PACKAGES content preview:")
    message(paste(head(readLines(packages_file), 10), collapse = "\n"))
  } else {
    warning("PACKAGES file was not created!")
  }
}

#' Manually create PACKAGES index file
#'
#' @param repo_dir Repository directory
#' @param tgz_files Vector of .tgz file paths
#' @keywords internal
create_manual_packages_index <- function(repo_dir, tgz_files) {
  # Extract package info from .tgz files and create PACKAGES index
  packages_info <- lapply(tgz_files, function(tgz) {
    # Extract package name and version from filename
    basename <- basename(tgz)
    pkg_fullname <- sub("\\.tgz$", "", basename)
    parts <- strsplit(pkg_fullname, "_")[[1]]

    if (length(parts) != 2) {
      return(NULL)
    }

    list(
      Package = parts[1],
      Version = parts[2],
      File = basename
    )
  })

  packages_info <- Filter(Negate(is.null), packages_info)

  if (length(packages_info) == 0) {
    return(invisible(NULL))
  }

  # Write PACKAGES file
  packages_file <- file.path(repo_dir, "PACKAGES")

  lines <- unlist(lapply(packages_info, function(pkg) {
    c(
      paste0("Package: ", pkg$Package),
      paste0("Version: ", pkg$Version),
      ""  # blank line between entries
    )
  }))

  writeLines(lines, packages_file)
  message("DEBUG: Manually created PACKAGES file")

  invisible(NULL)
}
