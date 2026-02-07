# Sparkle Design System Demo
# Demonstrates using pre-built UI components from the sparkle design system

library(sparkle)
library(zeallot)

DesignSystemDemo <- function() {
  c(name, setName) %<-% use_state("")
  c(email, setEmail) %<-% use_state("")
  c(message, setMessage) %<-% use_state("")
  c(showSuccess, setShowSuccess) %<-% use_state(FALSE)

  handleSubmit <- function() {
    if (nchar(name()) > 0 && nchar(email()) > 0) {
      setMessage(paste("Welcome,", name(), "! We'll contact you at", email()))
      setShowSuccess(TRUE)
    } else {
      setMessage("Please fill in all fields")
      setShowSuccess(FALSE)
    }
  }

  handleReset <- function() {
    setName("")
    setEmail("")
    setMessage("")
    setShowSuccess(FALSE)
  }

  # Render with injected styles
  tags$div(
    create_style_tag(),  # Inject all registered CSS

    ui$Container(
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
              value = name(),
              on_change = \(e) setName(e$target$value)
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
              value = email(),
              on_change = \(e) setEmail(e$target$value)
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
          if (nchar(message()) > 0) {
            ui$Alert(
              message(),
              variant = if (showSuccess()) "success" else "warning"
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
      )
    )
  )
}

# Launch the app
sparkle_app(DesignSystemDemo, port = 3000)
