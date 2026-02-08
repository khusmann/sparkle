# Sparkle ✨

A client-side reactive framework for R that runs entirely in the browser using webR and React.

## Overview

Sparkle enables R developers to create interactive web applications using familiar R syntax, without needing a server. It combines:
- **R** for application logic
- **webR** to run R in the browser
- **React** for rendering
- **Zero server requirements** - everything runs client-side

## Features

- 🚀 **Client-side only** - No server required, deploy anywhere
- 🎯 **R-first API** - Write components in R with snake_case conventions
- ⚛️  **React powered** - Leverage React's rendering and ecosystem
- 🔗 **State management** - Uses React's `useState` hook via webR bridge
- 📦 **Shiny-like experience** - `install.packages()` and go

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

```r
library(sparkle)
library(zeallot)

Counter <- function() {
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

sparkle_app(Counter)
```

This will:
1. Start a local development server on port 3000
2. Open your default browser
3. Initialize webR in the browser
4. Render your Sparkle component

## How It Works

### Architecture

```
R Component Function → Virtual DOM Description → Sparkle Bridge → React Elements → Browser DOM
     ↑                                                                                    ↓
     └──────────────────── Event Callbacks (async via webR) ────────────────────────────┘
```

1. **R Component**: You write a function that returns virtual DOM descriptions using `tags$*`
2. **Virtual DOM**: R creates list structures describing the UI
3. **Bridge Layer**: JavaScript translates R structures to React elements
4. **React**: Renders to the browser DOM
5. **Events**: User interactions trigger R callbacks via webR

### State Management

Sparkle hooks into React's `useState` directly:
- State lives in React/JavaScript (not synchronized to R)
- R component functions are pure render functions
- Called on every render (like React function components)
- Event handlers execute asynchronously in webR

### Example: Counter Component Flow

1. User clicks "Increment" button
2. React fires `onClick` event
3. Event handler queues R callback to webR worker
4. webR executes: `set_count(\(c) c + 1)`
5. React's `setState` called with new value
6. React re-renders → calls `Counter()` function again
7. New virtual DOM generated with updated count
8. React updates browser DOM

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

### App Launcher

#### `sparkle_app(component, port = 3000)`

Launches a Sparkle application.

```r
sparkle_app(
  Counter,           # Component function
  port = 3000,       # Server port (default: 3000)
  host = "127.0.0.1" # Host address
)
```

## Examples

See the `examples/` directory for more examples:

- `examples/counter.R` - Basic counter with increment/decrement
- `examples/todo.R` - Todo list (coming soon)
- `examples/form.R` - Form with validation (coming soon)

## Development Status

**Current Status**: Proof of Concept (POC) ✨

This is an early POC demonstrating the core architecture:
- ✅ Basic tag rendering
- ✅ State management (`use_state`)
- ✅ Event handlers (`on_click`)
- ✅ R-first deployment model

**Coming Soon**:
- More hooks: `use_effect`, `use_memo`, `use_callback`, `use_ref`
- More events: `on_change`, `on_submit`, etc.
- Form inputs with two-way binding
- React-first mode (import Sparkle into existing React apps)
- Performance optimizations
- TypeScript runtime
- Comprehensive documentation

## Technical Details

### Project Structure

```
sparkle/
├── R/                          # R package code
│   ├── tags.R                  # HTML tag builders
│   ├── hooks.R                 # React hooks interface
│   ├── callbacks.R             # Event callback wrapping
│   └── app.R                   # App launcher with dev server
├── inst/
│   └── www/                    # Web assets
│       ├── index.html          # Base HTML template
│       ├── bundle.js           # Bundled JavaScript runtime (generated)
│       └── sparkle-runtime/    # JavaScript source
│           ├── bridge.js       # Main webR ↔ React coordinator
│           ├── component-factory.js  # R virtual DOM → React elements
│           ├── hook-manager.js       # React hooks bridge
│           ├── event-handler.js      # Event callback execution
│           └── prop-transformer.js   # snake_case → camelCase
├── DESCRIPTION                 # R package metadata
├── NAMESPACE                   # R package exports
├── package.json                # JavaScript dependencies
└── build.js                    # JavaScript build script
```

### Dependencies

**R Dependencies:**
- `jsonlite` - JSON serialization
- `httpuv` - Local development server

**JavaScript Dependencies (bundled):**
- `react` (^18.2.0)
- `react-dom` (^18.2.0)
- `@r-wasm/webr` - WebAssembly R runtime (loaded from CDN)

## Contributing

This is an experimental project. Contributions, ideas, and feedback are welcome!

## Inspiration

Sparkle is inspired by:
- **Shiny** - The pioneering R web framework
- **React** - For its elegant component model
- **webR** - Making R run in the browser
- **Svelte** - For compiler-driven approaches to reactivity

## License

MIT License - see LICENSE file for details

---

**Note**: This is a proof-of-concept. Not recommended for production use yet.
