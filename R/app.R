#' Serve a static file with appropriate headers
#'
#' @param file_path Path to file to serve
#' @param extra_headers Additional headers to include
#' @return httpuv response list
#' @keywords internal
serve_static_file <- function(file_path, extra_headers = list()) {
  # Determine content type
  ext <- tools::file_ext(file_path)
  content_type <- switch(ext,
    "html" = "text/html",
    "js" = "application/javascript",
    "css" = "text/css",
    "json" = "application/json",
    "tgz" = "application/gzip",
    "gz" = "application/gzip",
    "data" = "application/octet-stream",
    "metadata" = "application/json",
    "rds" = "application/octet-stream",
    "application/octet-stream"
  )

  # Read file
  content <- readBin(file_path, "raw", file.info(file_path)$size)

  # Combine headers
  headers <- c(
    list("Content-Type" = content_type),
    extra_headers
  )

  list(
    status = 200L,
    headers = headers,
    body = content
  )
}

#' Launch a Sparkle Application
#'
#' Start a local development server and launch a Sparkle app in the browser.
#' Supports both folder-based apps (multiple .R files) and single-file apps.
#'
#' @param path Path to app folder or single .R file. Default: "." (current directory)
#' @param port The port number for the development server (default: 3000)
#' @param host The host address (default: "127.0.0.1")
#' @param launch_browser Whether to automatically open the browser (default: TRUE)
#' @export
#' @examples
#' \dontrun{
#' # Folder-based app
#' sparkle_app("my-app/")
#'
#' # Single-file app
#' sparkle_app("counter.R")
#'
#' # Current directory (must contain .R files with App function)
#' sparkle_app()
#' }
sparkle_app <- function(path = ".", port = 3000, host = "127.0.0.1", launch_browser = TRUE) {
  # Default to current directory if no path provided
  # This allows: sparkle_app() when you're already in the app directory

  # Normalize path
  path <- normalizePath(path, mustWork = TRUE)

  # Determine if it's a file or folder
  r_files <- character(0)
  if (file.info(path)$isdir) {
    # Folder mode: source all .R files
    r_files <- list.files(path, pattern = "\\.R$", full.names = TRUE)
    r_files <- sort(r_files)  # Alphabetical order

    if (length(r_files) == 0) {
      stop("No .R files found in directory: ", path)
    }

    message("Found ", length(r_files), " R file(s): ", paste(basename(r_files), collapse = ", "))
  } else {
    # Single-file mode
    r_files <- c(path)
    message("Loading single-file app: ", basename(path))
  }

  # Create temporary bundle directory
  bundle_dir <- tempfile("sparkle-bundle-")
  dir.create(bundle_dir, recursive = TRUE)

  # Create app bundle (detects dependencies, downloads packages, etc.)
  message("Creating app bundle...")
  bundle_info <- create_app_bundle(r_files, bundle_dir)

  # Get the path to the www directory
  www_dir <- system.file("www", package = "sparkle")

  if (www_dir == "" || !dir.exists(www_dir)) {
    # Development mode: look for inst/www relative to package root
    pkg_root <- getwd()

    # Walk up directory tree to find DESCRIPTION file
    max_depth <- 5
    for (i in 1:max_depth) {
      if (file.exists(file.path(pkg_root, "DESCRIPTION"))) {
        www_dir <- file.path(pkg_root, "inst", "www")
        break
      }
      pkg_root <- dirname(pkg_root)
    }

    if (!dir.exists(www_dir)) {
      stop("Web assets directory not found: ", www_dir,
           "\nMake sure the package is properly installed or you're in the package directory.",
           "\nCurrent working directory: ", getwd())
    }
  }

  # Check if bundle.js exists
  bundle_path <- file.path(www_dir, "bundle.js")
  if (!file.exists(bundle_path)) {
    stop("JavaScript bundle not found. Please run: pnpm install && pnpm run build")
  }

  message("Starting Sparkle app on http://", host, ":", port)

  # CORS headers (required for webR package loading)
  cors_headers <- list(
    "Access-Control-Allow-Origin" = "*",
    "Access-Control-Allow-Methods" = "GET, OPTIONS",
    "Access-Control-Allow-Headers" = "Content-Type"
  )

  # Create a httpuv server
  app <- list(
    call = function(req) {
      path <- req$PATH_INFO

      # Handle OPTIONS preflight requests
      if (req$REQUEST_METHOD == "OPTIONS") {
        return(list(
          status = 200L,
          headers = cors_headers,
          body = ""
        ))
      }

      # Handle root path
      if (path == "/" || path == "/index.html") {
        # Read and modify index.html to inject bundle info
        html_path <- file.path(www_dir, "index.html")
        html_content <- paste(readLines(html_path), collapse = "\n")

        # Inject the component code, name, and dependencies
        component_json <- jsonlite::toJSON(bundle_info$app_code, auto_unbox = TRUE)
        component_name_json <- jsonlite::toJSON(bundle_info$component_name, auto_unbox = TRUE)
        # Ensure dependencies is serialized as an array, not an object
        message("DEBUG: dependencies = ", paste(bundle_info$dependencies, collapse = ", "))
        message("DEBUG: class = ", class(bundle_info$dependencies))
        message("DEBUG: length = ", length(bundle_info$dependencies))
        dependencies_json <- jsonlite::toJSON(as.character(bundle_info$dependencies), auto_unbox = FALSE)

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

        # Inject flag to use local packages
        html_content <- sub(
          "</head>",
          "<script>window.SPARKLE_USE_LOCAL_PACKAGES = true;</script>\n</head>",
          html_content,
          fixed = TRUE
        )

        return(list(
          status = 200L,
          headers = c(list("Content-Type" = "text/html; charset=UTF-8"), cors_headers),
          body = html_content
        ))
      }

      # Handle /repo/ route for bundled packages
      if (startsWith(path, "/repo/")) {
        file_path <- file.path(bundle_info$bundle_dir, substring(path, 2))

        if (file.exists(file_path) && !file.info(file_path)$isdir) {
          message("DEBUG: Serving repo file: ", basename(file_path))
          return(serve_static_file(file_path, cors_headers))
        } else {
          message("DEBUG: File not found: ", file_path)
          message("DEBUG: bundle_dir = ", bundle_info$bundle_dir)
          message("DEBUG: Files in repo dir: ", paste(list.files(file.path(bundle_info$bundle_dir, "repo"), recursive = TRUE), collapse = ", "))
          return(list(
            status = 404L,
            headers = cors_headers,
            body = "Package file not found"
          ))
        }
      }

      # Handle static files from www/
      file_path <- file.path(www_dir, substring(path, 2))

      if (file.exists(file_path) && !file.info(file_path)$isdir) {
        return(serve_static_file(file_path, cors_headers))
      }

      # 404 for everything else
      return(list(
        status = 404L,
        headers = c(list("Content-Type" = "text/plain"), cors_headers),
        body = "Not Found"
      ))
    }
  )

  # Start the server
  server <- httpuv::startServer(host, port, app)

  # Open browser
  if (launch_browser) {
    url <- paste0("http://", host, ":", port)
    utils::browseURL(url)
  }

  message("Sparkle is running. Press Ctrl+C to stop.")

  # Clean up bundle directory on exit
  on.exit({
    httpuv::stopServer(server)
    unlink(bundle_dir, recursive = TRUE)
  })

  # Run the event loop
  tryCatch({
    while (TRUE) {
      httpuv::service()
      Sys.sleep(0.001)
    }
  }, interrupt = function(e) {
    message("\nStopping Sparkle app...")
  })

  invisible(NULL)
}
