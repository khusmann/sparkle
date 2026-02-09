# Sparkle

A client-side reactive framework for R that runs entirely in the browser using
webR and React.

Sparkle brings React's explicit state management and component model to R.
Instead of Shiny's implicit reactive graph, write components as pure functions
with explicit state updates—making apps easier to reason about, debug, and
scale.

**Note**: Experimental weekend project. Not production-ready.

## Examples

Interactive demos running in your browser ([view source](examples/)):

### Core Concepts

- **[Counter](https://khusmann.github.io/sparkle/counter)** - State management
  basics

### Styling

- **[Design System](https://khusmann.github.io/sparkle/design-system-demo)** -
  Pre-built UI components
- **[Custom Styles](https://khusmann.github.io/sparkle/styled-demo)** - Styled
  components pattern

### Code Organization

- **[Multi-file TODO App](https://khusmann.github.io/sparkle/todo-multifile)** -
  Complex state management with multi-file organization and styled components

## Overview

Shiny already runs in the browser via
[shinylive](https://posit-dev.github.io/r-shinylive/), so this isn't about
making Shiny client-side. Instead, this explores whether React's programming
model can work in R.

**Shiny vs React:**

- Shiny: Implicit reactive graph, automatic dependency tracking. Convenient for
  simple apps, hard to debug at scale.
- React: Explicit state updates, components as pure functions. More predictable
  and easier to reason about.

**How it works:** Sparkle combines webR (R in WebAssembly) with React's
rendering engine. Write component functions in R that return virtual DOM
descriptions. State lives in React, R functions are called on every render, and
React handles the actual DOM updates.

## What Works

Client-side execution, R-native syntax (snake_case), React rendering, state
management via `useState`, and simple static deployment. See
[examples](https://khusmann.github.io/sparkle) running in your browser.

## Quick Start

### Prerequisites

- R (>= 4.0.0)
- Node.js (>= 16.0.0) for building the JavaScript runtime

### Installation

1. **Install JavaScript dependencies:**

   ```bash
   pnpm install
   ```

2. **Build the JavaScript bundle:**

   ```bash
   pnpm run build
   ```

3. **Load the R package:**
   ```r
   devtools::load_all()
   ```

### Your First Sparkle App

Create a file `counter.R` with your component:

```r
library(sparkle)
library(zeallot)  # Provides the %<-% operator for destructuring assignment

App <- function() {
  c(count, set_count) %<-% use_state(0)

  tags$div(
    tags$h1(paste("Count:", count)),
    tags$button(
      "Increment",
      on_click = \() set_count(\(c) c + 1)
    ),
    tags$button(
      "Decrement",
      on_click = \() set_count(\(c) c - 1)
    ),
    tags$button(
      "Reset",
      on_click = \() set_count(0)
    )
  )
}
```

Then launch it by passing the file path to `sparkle_app()`:

```r
sparkle::sparkle_app("counter.R")
```

This will:

1. Start a local development server on port 3000
2. Open your default browser
3. Initialize webR in the browser
4. Load your component code and render it

## How It Works

**Data flow:**

```
R Component (tags$*)
    ↓
Virtual DOM (R lists)
    ↓
Bridge (R ↔ JS)
    ↓
React Elements
    ↓
Browser DOM
    ↑
User Events → webR callbacks
```

**State management:** State lives in React (not R). Component functions are pure
render functions called on every render. Event handlers execute asynchronously
in webR.

**Optimistic updates:** Text inputs update locally first, then sync to R after
150ms debounce. This keeps the UI responsive despite webR overhead. See
[OPTIMISTIC_UPDATES.md](OPTIMISTIC_UPDATES.md) for details.

## API Reference

### Tags

Create HTML elements using `tags$*`:

```r
tags$div(...)      # <div>
tags$button(...)   # <button>
tags$h1(...)       # <h1>
tags$h2(...)       # <h2>
tags$p(...)        # <p>
tags$span(...)     # <span>
tags$input(...)    # <input>
```

**Usage:**

- Unnamed arguments become children
- Named arguments become props

```r
tags$div(
  class_name = "container",  # Props use snake_case
  tags$h1("Hello"),          # Children
  tags$p("Welcome to Sparkle!")
)
```

### Hooks

#### `use_state(initial_value)`

Creates a reactive state variable. Works like React's `useState` hook.

```r
library(zeallot)

# Destructure into value and setter (like React)
c(count, set_count) %<-% use_state(0)

# Access value directly (no function call needed)
count

# Update with new value
set_count(5)

# Or use functional update (setter receives previous value)
set_count(\(prev) prev + 1)
```

### Event Handlers

Event handlers are passed as lambda functions directly to element props.

```r
tags$button(
  "Click me",
  on_click = \() {
    print("Button clicked!")
  }
)

# Event handlers receive event objects
tags$input(
  type = "text",
  on_change = \(e) {
    new_value <- e$target$value
    print(new_value)
  }
)
```

**Supported events** (snake_case in R, automatically converted to camelCase):

- `on_click` → `onClick`
- `on_change` → `onChange`
- `on_submit` → `onSubmit`
- `on_input` → `onInput`
- `on_key_down` → `onKeyDown`
- And more...

### Styled Components

Adopts React's [styled-components](https://styled-components.com/) pattern with
automatic scoping, dynamic styling, and colocation. Create styled elements with
`styled_*` functions:

```r
PrimaryButton <- styled_button(
  background_color = "#3b82f6",
  color = "white",
  padding = "12px 24px",
  border_radius = "6px",
  css = "&:hover { opacity: 0.9; }"
)

PrimaryButton("Click me", on_click = handler)
```

Properties use snake_case and can be computed from state. See
[`styled-demo.R`](https://github.com/khusmann/sparkle/blob/main/examples/styled-demo.R).

### Design System

Pre-built UI components are available via the `ui` namespace:

```r
ui$Button("Submit", variant = "primary", size = "lg", on_click = handler)
ui$Card(tags$h2("Title"), tags$p("Content"))
ui$Input(type = "text", value = name, on_change = \(e) set_name(e$target$value))
ui$Badge("New", variant = "success")
ui$Alert("Success message", variant = "success")
ui$Stack(direction = "horizontal", spacing = "md", ...)
ui$Container(max_width = "800px", ...)
```

Components support variants (`primary`, `secondary`, `success`, `danger`,
`warning`, `info`) and spacing tokens (`xs`, `sm`, `md`, `lg`, `xl`). Requires
`create_style_tag()` like styled components. See
[`design-system-demo.R`](https://github.com/khusmann/sparkle/blob/main/examples/design-system-demo.R).

### App Launching and Building

#### `sparkle_app(path, port = 3000)`

Launches a development server for live editing. Accepts either a single `.R`
file or a directory containing multiple `.R` files.

```r
# Single-file app
sparkle_app("counter.R")

# Multi-file app (folder)
sparkle_app("my-app/")

# Current directory
sparkle_app()
```

**Important:** Your root component must be named `App`. For multi-file apps,
define `App <- function() { ... }` in any of your `.R` files.

#### `sparkle_build(app_path, output_dir)`

Creates a static build for deployment to GitHub Pages, Netlify, or any static
hosting. Bundles all R package dependencies locally for complete offline
functionality.

```r
# Build single-file app
sparkle_build("counter.R", "build/counter")

# Build multi-file app
sparkle_build("my-app/", "build/my-app")

# Build and open in browser
sparkle_build("counter.R", "build/counter", open_browser = TRUE)
```

The output directory contains a self-contained static website with no external
CDN dependencies.

## Status and Limitations

**Proof-of-concept** exploring whether React's programming model can work in R.
Basic architecture works (rendering, `use_state`, event handlers), but has
significant limitations:

### No Async/Await in R

R doesn't have async/await. Long-running computations in the webR worker run to
completion without yielding—blocking progress updates, cancellation, or other
callbacks. Component functions must be fast since they run on every render.

**Future work:** Experiment with an R API to spawn background workers for
expensive computations, allowing the main thread to remain responsive during
long-running operations.

### Missing Features

Additional hooks (`use_effect`, `use_memo`, `use_callback`, `use_ref`),
comprehensive event support, form input handling.

## Technical Details

### Dependencies

**R Dependencies:**

- `jsonlite` - JSON serialization
- `httpuv` - Local development server

**JavaScript Dependencies (bundled):**

- `react` (^18.2.0)
- `react-dom` (^18.2.0)
- `@r-wasm/webr` - WebAssembly R runtime (loaded from CDN)

## Contributing

This is an experimental project. If you're interested in exploring these ideas
or have thoughts on how to address the limitations, contributions and feedback
are welcome.

## License

MIT License - see LICENSE file for details
