# Sparkle Design System Demo
# Demonstrates using pre-built UI components from the sparkle design system
#
# Run with: sparkle_app("examples/design-system-demo.R")

library(sparkle)
library(zeallot)

App <- function() {
  c(name, set_name) %<-% use_state("")
  c(email, set_email) %<-% use_state("")
  c(message, set_message) %<-% use_state("")
  c(show_success, set_show_success) %<-% use_state(FALSE)

  handleSubmit <- function() {
    if (nchar(name) > 0 && nchar(email) > 0) {
      set_message(paste("Welcome,", name, "! We'll contact you at", email))
      set_show_success(TRUE)
    } else {
      set_message("Please fill in all fields")
      set_show_success(FALSE)
    }
  }

  handleReset <- function() {
    set_name("")
    set_email("")
    set_message("")
    set_show_success(FALSE)
  }

  # Render with injected styles
  result <- ui$Container(
      max_width = "800px",

      # Header section
      tags$div(
        style = list(text_align = "center", margin_bottom = "40px"),
        tags$h1("Sparkle Design System ✨"),
        tags$p("Pre-built, beautifully styled components")
      ),

      # Main card with form
      ui$Card(
        tags$h2("Sign Up Form", style = list(margin_top = "0")),

        ui$Stack(
          direction = "vertical",
          spacing = "md",

          # Name input
          tags$div(
            tags$label("Name", style = list(
              display = "block",
              margin_bottom = "8px",
              font_weight = "500",
              color = "#374151"
            )),
            ui$Input(
              type = "text",
              placeholder = "Enter your name",
              value = name,
              on_change = \(e) set_name(e$target$value)
            )
          ),

          # Email input
          tags$div(
            tags$label("Email", style = list(
              display = "block",
              margin_bottom = "8px",
              font_weight = "500",
              color = "#374151"
            )),
            ui$Input(
              type = "email",
              placeholder = "your.email@example.com",
              value = email,
              on_change = \(e) set_email(e$target$value)
            )
          ),

          # Buttons
          ui$Stack(
            direction = "horizontal",
            spacing = "sm",

            ui$Button(
              "Create Account",
              variant = "primary",
              size = "lg",
              on_click = handleSubmit
            ),

            ui$Button(
              "Reset",
              variant = "secondary",
              on_click = handleReset
            )
          ),

          # Feedback message
          if (nchar(message) > 0) {
            ui$Alert(
              message,
              variant = if (show_success) "success" else "warning"
            )
          }
        )
      ),

      # Component showcase
      tags$div(
        style = list(margin_top = "40px"),

        tags$h2("Component Gallery"),

        ui$Card(
          tags$h3("Buttons", style = list(margin_top = "0")),

          ui$Stack(
            direction = "horizontal",
            spacing = "sm",

            ui$Button("Primary", variant = "primary"),
            ui$Button("Secondary", variant = "secondary"),
            ui$Button("Success", variant = "success"),
            ui$Button("Danger", variant = "danger"),
            ui$Button("Warning", variant = "warning")
          )
        ),

        ui$Card(
          tags$h3("Button Sizes", style = list(margin_top = "0")),

          ui$Stack(
            direction = "horizontal",
            spacing = "sm",

            ui$Button("Small", variant = "primary", size = "sm"),
            ui$Button("Medium", variant = "primary", size = "md"),
            ui$Button("Large", variant = "primary", size = "lg")
          )
        ),

        ui$Card(
          tags$h3("Badges", style = list(margin_top = "0")),

          ui$Stack(
            direction = "horizontal",
            spacing = "sm",

            ui$Badge("New", variant = "primary"),
            ui$Badge("Beta", variant = "warning"),
            ui$Badge("Stable", variant = "success"),
            ui$Badge("Deprecated", variant = "danger")
          )
        ),

        ui$Card(
          tags$h3("Alerts", style = list(margin_top = "0")),

          ui$Stack(
            direction = "vertical",
            spacing = "sm",

            ui$Alert("This is an informational message", variant = "info"),
            ui$Alert("Operation completed successfully!", variant = "success"),
            ui$Alert("Please check your input", variant = "warning"),
            ui$Alert("An error occurred", variant = "danger")
          )
        )
      ),

      # Source code link
      tags$div(
        style = list(
          margin_top = "40px",
          padding_top = "20px",
          border_top = "1px solid #e5e7eb",
          text_align = "center",
          font_size = "14px",
          color = "#6b7280"
        ),
        tags$a(
          "View source on GitHub",
          href = "https://github.com/khusmann/sparkle/blob/main/examples/design-system-demo.R",
          target = "_blank",
          style = list(color = "#3b82f6", text_decoration = "none")
        )
      )
    )

  # Wrap with style tag AFTER all components have registered their styles
  tags$div(
    result,
    create_style_tag()  # Inject CSS at the end
  )
}
