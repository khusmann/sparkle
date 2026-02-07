#' Launch a Sparkle Application
#'
#' Start a local development server and launch a Sparkle app in the browser.
#' Similar to Shiny's \code{runApp()}.
#'
#' @param component An R function that returns a Sparkle component (created with tags$*)
#' @param port The port number for the development server (default: 3000)
#' @param host The host address (default: "127.0.0.1")
#' @param launch_browser Whether to automatically open the browser (default: TRUE)
#' @export
#' @examples
#' \dontrun{
#' Counter <- function() {
#'   count <- use_state(0)
#'   tags$div(
#'     tags$h1(paste("Count:", count$value)),
#'     tags$button("Increment", on_click = \() count$set(count$value + 1))
#'   )
#' }
#'
#' sparkle_app(Counter)
#' }
sparkle_app <- function(component, port = 3000, host = "127.0.0.1", launch_browser = TRUE) {
  if (!is.function(component)) {
    stop("component must be a function that returns a Sparkle element")
  }

  # Get the component name from the call
  component_name <- deparse(substitute(component))

  # Serialize the component function with assignment
  component_fn <- deparse(component)
  component_code_str <- paste0(
    component_name, " <- ",
    paste(component_fn, collapse = "\n")
  )

  # Get the path to the www directory
  # When installed: system.file finds files in inst/ promoted to package root
  # When not installed (dev mode): we need to find inst/www in the source tree

  www_dir <- system.file("www", package = "sparkle")

  if (www_dir == "" || !dir.exists(www_dir)) {
    # Development mode: look for inst/www relative to package root
    # Try to find the package root by looking for DESCRIPTION file
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

  # Create a httpuv server
  app <- list(
    call = function(req) {
      path <- req$PATH_INFO

      # Handle root path
      if (path == "/" || path == "/index.html") {
        # Read and modify index.html to inject component code
        html_path <- file.path(www_dir, "index.html")
        html_content <- paste(readLines(html_path), collapse = "\n")

        # Inject the component code and name
        component_json <- jsonlite::toJSON(component_code_str, auto_unbox = TRUE)
        component_name_json <- jsonlite::toJSON(component_name, auto_unbox = TRUE)

        html_content <- sub(
          "window.SPARKLE_COMPONENT_CODE = '';",
          paste0(
            "window.SPARKLE_COMPONENT_CODE = ", component_json, ";\n",
            "        window.SPARKLE_COMPONENT_NAME = ", component_name_json, ";"
          ),
          html_content,
          fixed = TRUE
        )

        return(list(
          status = 200L,
          headers = list("Content-Type" = "text/html; charset=UTF-8"),
          body = html_content
        ))
      }

      # Handle static files
      file_path <- file.path(www_dir, substring(path, 2))  # Remove leading /

      if (file.exists(file_path) && !file.info(file_path)$isdir) {
        # Determine content type
        content_type <- if (grepl("\\.js$", file_path)) {
          "application/javascript"
        } else if (grepl("\\.css$", file_path)) {
          "text/css"
        } else if (grepl("\\.html$", file_path)) {
          "text/html"
        } else {
          "application/octet-stream"
        }

        return(list(
          status = 200L,
          headers = list("Content-Type" = content_type),
          body = readBin(file_path, "raw", file.info(file_path)$size)
        ))
      }

      # 404 for everything else
      return(list(
        status = 404L,
        headers = list("Content-Type" = "text/plain"),
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

  # Keep R session alive
  on.exit(httpuv::stopServer(server))

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
