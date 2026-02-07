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
#'     tags$button("Increment", on_click = wrap_fn(\() count$set(count$value + 1)))
#'   )
#' }
#'
#' sparkle_app(Counter)
#' }
sparkle_app <- function(component, port = 3000, host = "127.0.0.1", launch_browser = TRUE) {
  if (!is.function(component)) {
    stop("component must be a function that returns a Sparkle element")
  }

  # Serialize the component function to pass to JavaScript
  component_code <- deparse(component)
  component_code_str <- paste(component_code, collapse = "\n")

  # Get the path to the inst/www directory
  package_path <- system.file(package = "sparkle")
  if (package_path == "") {
    # Development mode: use the current package directory
    package_path <- getwd()
  }

  www_dir <- file.path(package_path, "inst", "www")

  if (!dir.exists(www_dir)) {
    stop("Web assets directory not found: ", www_dir,
         "\nMake sure the package is properly installed or you're in the package directory.")
  }

  # Check if bundle.js exists
  bundle_path <- file.path(www_dir, "bundle.js")
  if (!file.exists(bundle_path)) {
    stop("JavaScript bundle not found. Please run: npm install && npm run build")
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

        # Inject the component code
        component_json <- jsonlite::toJSON(component_code_str, auto_unbox = TRUE)
        html_content <- sub(
          "window.SPARKLE_COMPONENT_CODE = '';",
          paste0("window.SPARKLE_COMPONENT_CODE = ", component_json, ";"),
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
