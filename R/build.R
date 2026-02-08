#' Build a Standalone Sparkle App
#'
#' Creates a self-contained static build of a Sparkle app that can be deployed
#' to GitHub Pages, Netlify, or any static hosting service. The build includes
#' all R packages bundled locally for complete offline functionality and
#' long-term stability.
#'
#' @param app_path Path to app file or directory containing .R files
#' @param output_dir Directory where the static build will be created
#' @param minify Logical; if TRUE, minify the generated HTML (default: FALSE)
#' @param open_browser Logical; if TRUE, open the built app in browser (default: FALSE)
#'
#' @details
#' The function creates a complete static website in `output_dir` containing:
#' \itemize{
#'   \item index.html - Entry point with embedded app code
#'   \item bundle.js - React + Sparkle runtime
#'   \item repo/ - Local R package repository (if dependencies exist)
#' }
#'
#' All R package dependencies are bundled locally, making the build completely
#' self-contained with no external CDN dependencies. This ensures demos remain
#' stable and functional indefinitely.
#'
#' @return Invisibly returns the path to the output directory
#'
#' @export
#' @examples
#' \dontrun{
#' # Build a single-file app
#' sparkle_build("examples/counter.R", "build/counter")
#'
#' # Build a multi-file app
#' sparkle_build("examples/counter-multifile/", "build/multifile")
#'
#' # Build and open in browser
#' sparkle_build("examples/counter.R", "build/counter", open_browser = TRUE)
#'
#' # Serve the built app with Python
#' # cd build/counter && python3 -m http.server 8000
#' }
sparkle_build <- function(app_path, output_dir, minify = FALSE, open_browser = FALSE) {
  # Validate and normalize app_path
  if (!file.exists(app_path)) {
    stop("App path does not exist: ", app_path)
  }

  app_path <- normalizePath(app_path, mustWork = TRUE)

  # Get R files (single file or directory)
  r_files <- character(0)
  if (file.info(app_path)$isdir) {
    # Directory mode: get all .R files
    r_files <- list.files(app_path, pattern = "\\.R$", full.names = TRUE)
    r_files <- sort(r_files)  # Alphabetical order

    if (length(r_files) == 0) {
      stop("No .R files found in directory: ", app_path)
    }

    message("Found ", length(r_files), " R file(s): ", paste(basename(r_files), collapse = ", "))
  } else {
    # Single-file mode
    r_files <- c(app_path)
    message("Building single-file app: ", basename(app_path))
  }

  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    message("Creating output directory: ", output_dir)
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  output_dir <- normalizePath(output_dir, mustWork = TRUE)

  # Create bundle (handles serialization, dependencies, packages)
  message("\nCreating app bundle...")
  bundle_info <- create_app_bundle(r_files, output_dir)

  # Get www directory from package installation
  www_dir <- system.file("www", package = "sparkle")
  if (!dir.exists(www_dir)) {
    stop("Sparkle www directory not found. Is the package installed correctly?")
  }

  # Copy static assets
  message("\nCopying static assets...")

  bundle_js_src <- file.path(www_dir, "bundle.js")
  bundle_js_dest <- file.path(output_dir, "bundle.js")
  if (file.exists(bundle_js_src)) {
    file.copy(bundle_js_src, bundle_js_dest, overwrite = TRUE)
    message("Copied bundle.js")
  } else {
    stop("bundle.js not found in package installation")
  }

  # Copy source map if it exists
  bundle_map_src <- file.path(www_dir, "bundle.js.map")
  bundle_map_dest <- file.path(output_dir, "bundle.js.map")
  if (file.exists(bundle_map_src)) {
    file.copy(bundle_map_src, bundle_map_dest, overwrite = TRUE)
    message("Copied bundle.js.map")
  }

  # Generate static HTML
  message("\nGenerating index.html...")

  html_path <- file.path(www_dir, "index.html")
  if (!file.exists(html_path)) {
    stop("index.html template not found in package installation")
  }

  html_content <- paste(readLines(html_path), collapse = "\n")

  # Inject component code, name, and dependencies using jsonlite
  component_json <- jsonlite::toJSON(bundle_info$app_code, auto_unbox = TRUE)
  component_name_json <- jsonlite::toJSON(bundle_info$component_name, auto_unbox = TRUE)
  dependencies_json <- jsonlite::toJSON(as.character(bundle_info$dependencies), auto_unbox = FALSE)

  # Replace placeholders in HTML
  html_content <- sub(
    "window.SPARKLE_COMPONENT_CODE = '';",
    paste0(
      "window.SPARKLE_COMPONENT_CODE = ", component_json, ";\n",
      "        window.SPARKLE_COMPONENT_NAME = ", component_name_json, ";\n",
      "        window.SPARKLE_DEPENDENCIES = ", dependencies_json, ";"
    ),
    html_content,
    fixed = TRUE
  )

  # Inject flag to use local packages (always true for sparkle_build)
  html_content <- sub(
    "</head>",
    "<script>window.SPARKLE_USE_LOCAL_PACKAGES = true;</script>\n</head>",
    html_content,
    fixed = TRUE
  )

  # Minify if requested
  if (minify) {
    # Simple minification: remove extra whitespace
    html_content <- gsub("\\s+", " ", html_content)
    html_content <- gsub("> <", "><", html_content)
  }

  # Write HTML to output directory
  html_output_path <- file.path(output_dir, "index.html")
  writeLines(html_content, html_output_path)
  message("Generated index.html")

  # Calculate bundle size
  message("\n======================================")
  message("Build complete!")
  message("======================================")
  message("Output directory: ", output_dir)

  # Report file sizes
  html_size <- file.size(html_output_path)
  bundle_size <- file.size(bundle_js_dest)
  total_size <- html_size + bundle_size

  if (dir.exists(file.path(output_dir, "repo"))) {
    repo_files <- list.files(file.path(output_dir, "repo"), recursive = TRUE, full.names = TRUE)
    repo_size <- sum(file.size(repo_files))
    total_size <- total_size + repo_size

    message("Dependencies: ", length(bundle_info$dependencies),
            " package(s) - ", paste(bundle_info$dependencies, collapse = ", "))
    message("Package repo size: ", format(repo_size / 1024^2, digits = 2), " MB")
  } else {
    message("Dependencies: none")
  }

  message("Runtime size: ", format(bundle_size / 1024, digits = 2), " KB")
  message("Total bundle size: ", format(total_size / 1024^2, digits = 2), " MB")

  message("\nDeployment options:")
  message("  1. Serve locally: cd ", output_dir, " && python3 -m http.server 8000")
  message("  2. Deploy to GitHub Pages (push to gh-pages branch)")
  message("  3. Deploy to Netlify/Vercel (drag and drop)")
  message("\nNote: Built app works completely offline with all packages bundled locally.")

  # Open in browser if requested
  if (open_browser) {
    index_url <- file.path(output_dir, "index.html")
    message("\nOpening in browser...")
    browseURL(index_url)
  }

  invisible(output_dir)
}
