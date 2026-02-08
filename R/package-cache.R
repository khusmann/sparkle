#' Get sparkle cache directory
#'
#' Returns the directory for cached webR WASM packages
#'
#' @return Path to cache directory
#' @keywords internal
get_cache_dir <- function() {
  # Use user's cache directory
  cache_root <- tools::R_user_dir("sparkle", which = "cache")
  cache_dir <- file.path(cache_root, "webr-packages")

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  return(cache_dir)
}

#' Download a webR WASM package
#'
#' Downloads all 3 required files for a package: .tgz, .data, .js.metadata
#'
#' @param package_name Name of the package to download
#' @param cache_dir Directory to store cached packages
#' @param webr_version WebR version to use (default: "latest")
#' @return List with package name, version, and file paths
#' @keywords internal
download_webr_package <- function(package_name, cache_dir, webr_version = "latest") {
  # Download WASM package from webR CDN
  # Each package needs 3 files: .tgz, .data, .js.metadata

  # Use the same repository URL that webR uses in the browser
  base_url <- "https://repo.r-wasm.org"
  # Use R 4.5 to match webR's current version
  pkg_base_url <- sprintf("%s/bin/emscripten/contrib/4.5", base_url)

  # Find the actual package version by checking PACKAGES file
  packages_url <- sprintf("%s/PACKAGES", pkg_base_url)

  # Parse PACKAGES to get full package filename (with version)
  packages_content <- tryCatch({
    readLines(url(packages_url))
  }, error = function(e) {
    stop("Failed to fetch PACKAGES index: ", e$message)
  })

  # Extract package version from PACKAGES file
  pkg_pattern <- paste0("^Package: ", package_name, "$")
  pkg_idx <- grep(pkg_pattern, packages_content)
  if (length(pkg_idx) == 0) {
    stop("Package ", package_name, " not found in webR repository")
  }

  # Get version from next few lines
  version_line <- grep("^Version:", packages_content[pkg_idx:(pkg_idx + 10)])[1]
  version <- trimws(sub("^Version: ", "", packages_content[pkg_idx + version_line - 1]))

  pkg_fullname <- sprintf("%s_%s", package_name, version)

  # Define all three file types
  files <- list(
    tgz = sprintf("%s.tgz", pkg_fullname),
    data = sprintf("%s.data", pkg_fullname),
    metadata = sprintf("%s.js.metadata", pkg_fullname)
  )

  # Check if .tgz file is cached (required file)
  dest_files <- lapply(files, function(f) file.path(cache_dir, f))
  tgz_cached <- file.exists(dest_files$tgz)

  # Validate cached .tgz file (check it's not empty/corrupted)
  if (tgz_cached) {
    tgz_valid <- file.info(dest_files$tgz)$size > 0

    if (tgz_valid) {
      message("Using cached package: ", package_name)
      # Return only the files that actually exist
      cached_files <- Filter(file.exists, dest_files)
      return(list(
        name = package_name,
        version = version,
        files = cached_files
      ))
    } else {
      # Cached .tgz is invalid, clean it up
      message("Cached .tgz for ", package_name, " is invalid, re-downloading...")
      if (file.exists(dest_files$tgz)) {
        unlink(dest_files$tgz)
      }
    }
  }

  # Download all three files
  message("Downloading ", package_name, " (", version, ") from webR CDN...")

  downloaded_files <- list()
  for (file_type in names(files)) {
    src_url <- sprintf("%s/%s", pkg_base_url, files[[file_type]])
    dest_path <- dest_files[[file_type]]

    tryCatch({
      download.file(src_url, dest_path, mode = "wb", quiet = FALSE)
      downloaded_files[[file_type]] <- dest_path
    }, error = function(e) {
      warning("Failed to download ", files[[file_type]], ": ", e$message)
      return(NULL)
    })
  }

  # Verify at least the .tgz file was downloaded
  if (!("tgz" %in% names(downloaded_files))) {
    # Clean up any partial downloads
    lapply(dest_files, function(f) {
      if (file.exists(f)) {
        unlink(f)
      }
    })
    stop("Failed to download package .tgz file for ", package_name)
  }

  # For R 4.5+, .data and .js.metadata files might not exist
  # Just warn if they're missing but continue
  if (length(downloaded_files) < 3) {
    message("Note: Only ", length(downloaded_files), " file(s) downloaded for ", package_name,
            " (.data and .js.metadata may not be required)")
  }

  # Validate the .tgz file (ensure it's not empty)
  if (!file.exists(dest_files$tgz) || file.info(dest_files$tgz)$size == 0) {
    # Clean up invalid downloads
    lapply(dest_files, function(f) {
      if (file.exists(f)) {
        unlink(f)
      }
    })
    stop("Downloaded .tgz file for ", package_name, " is invalid or empty")
  }

  return(list(
    name = package_name,
    version = version,
    files = downloaded_files
  ))
}

#' Download all required packages
#'
#' @param packages Character vector of package names
#' @return Named list of package information
#' @keywords internal
download_all_packages <- function(packages) {
  cache_dir <- get_cache_dir()

  downloaded <- list()
  for (pkg in packages) {
    result <- tryCatch({
      download_webr_package(pkg, cache_dir)
    }, error = function(e) {
      warning("Skipping package ", pkg, ": ", e$message)
      NULL
    })

    if (!is.null(result)) {
      downloaded[[pkg]] <- result
    }
  }

  return(downloaded)
}

#' Clear the sparkle package cache
#'
#' Clears cached webR WASM packages. Can clear entire cache or specific packages.
#'
#' @param packages Character vector of package names to clear, or NULL to clear all (default: NULL)
#' @param force Skip confirmation prompt if TRUE (default: FALSE)
#' @export
#' @examples
#' \dontrun{
#' # Clear entire cache (with confirmation)
#' clear_cache()
#'
#' # Clear specific packages
#' clear_cache(c("dplyr", "ggplot2"))
#'
#' # Force clear without confirmation
#' clear_cache(force = TRUE)
#' }
clear_cache <- function(packages = NULL, force = FALSE) {
  # Clear the sparkle package cache
  # If packages is NULL, clears entire cache
  # If packages is a vector, only clears specified packages

  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist: ", cache_dir)
    return(invisible(NULL))
  }

  if (is.null(packages)) {
    # Clear entire cache
    if (!force) {
      response <- readline(prompt = "Clear entire package cache? This will re-download all packages. (y/N): ")
      if (!tolower(trimws(response)) %in% c("y", "yes")) {
        message("Cache clear cancelled")
        return(invisible(NULL))
      }
    }

    cache_files <- list.files(cache_dir, full.names = TRUE)
    n_files <- length(cache_files)

    if (n_files == 0) {
      message("Cache is already empty")
      return(invisible(NULL))
    }

    unlink(cache_files)
    message("Cleared ", n_files, " files from cache: ", cache_dir)

  } else {
    # Clear specific packages
    cleared <- 0

    for (pkg in packages) {
      # Find all files matching this package (any version)
      pattern <- paste0("^", pkg, "_.*\\.(tgz|data|js\\.metadata)$")
      pkg_files <- list.files(cache_dir, pattern = pattern, full.names = TRUE)

      if (length(pkg_files) > 0) {
        unlink(pkg_files)
        cleared <- cleared + length(pkg_files)
        message("Cleared ", pkg, " (", length(pkg_files), " files)")
      } else {
        message("Package ", pkg, " not found in cache")
      }
    }

    if (cleared > 0) {
      message("Cleared ", cleared, " files from cache")
    }
  }

  invisible(NULL)
}
