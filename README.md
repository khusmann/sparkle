# Sparkle

A client-side reactive framework for R that runs entirely in the browser using
webR and React.

**Note**: This is exploratory work. Not suitable for production use.

## Examples

Live interactive demos are available at [khusmann.github.io/sparkle](https://khusmann.github.io/sparkle)

See the `examples/` directory for source code:

- [`counter.R`](https://khusmann.github.io/sparkle/counter) - Basic counter with increment/decrement
- [`todo.R`](https://khusmann.github.io/sparkle/todo) - Task manager with complex state management
- [`design-system-demo.R`](https://khusmann.github.io/sparkle/design-system-demo) - Pre-built UI components showcase
- [`styled-demo.R`](https://khusmann.github.io/sparkle/styled-demo) - Custom styled components with CSS-in-R
- [`counter-multifile/`](https://khusmann.github.io/sparkle/counter-multifile) - Multi-file app organization best practices

Each example runs entirely in your browser via webR with no server required.

## Overview

Shiny already runs in the browser via
[shinylive](https://posit-dev.github.io/r-shinylive/), so this isn't about
making Shiny client-side. Instead, this explores whether React's programming
model - component functions, hooks like `useState`, explicit state management -
can work in R.

Shiny uses reactive programming with reactive expressions and observers, where
dependencies are tracked automatically. This is convenient for simple apps but
becomes hard to debug as complexity grows. React's explicit state model is
simpler: components are just functions called on every render, state updates are
explicit, and re-rendering is predictable. This makes React's model easier to
reason about, debug, and scale. But how well does this approach work in R?

Sparkle is an experimental proof-of-concept exploring what React-style
programming looks like in R. It combines webR (R compiled to WebAssembly) with
React's component model and rendering engine. Component functions are written in
R, return virtual DOM descriptions, and React handles the rendering. State lives
in React, and R component functions are called on every render to produce UI.

The experiment explores three questions: Can React's programming model translate
to R? What does `useState`, `useEffect`, and component-based architecture look
like with R syntax? And is the performance acceptable when R computes component
renders while React handles the virtual DOM reconciliation?

## What Works

- **Client-side execution** - Everything runs in the browser via webR
- **R-native syntax** - Write components in R with familiar snake_case
  conventions
- **React rendering** - Uses React's rendering engine and virtual DOM
- **State management** - Hooks into React's `useState` via a JavaScript bridge
- **Simple deployment** - No server infrastructure needed

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
library(zeallot)

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

### Architecture

```
R Component Function → Virtual DOM Description → Sparkle Bridge → React Elements → Browser DOM
     ↑                                                                                    ↓
     └──────────────────── Event Callbacks (async via webR) ────────────────────────────┘
```

1. **R Component**: You write a function that returns virtual DOM descriptions
   using `tags$*`
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

#### `sparkle_app(file_path, port = 3000)`

Launches a Sparkle application from an R file.

```r
sparkle_app(
  "counter.R",       # Path to component file
  port = 3000,       # Server port (default: 3000)
  host = "127.0.0.1" # Host address
)
```

## Status and Limitations

**This is a proof-of-concept**, built to answer the question: "Can React's
programming model work in R?"

The basic architecture works:

- HTML tag rendering
- State management (`use_state`)
- Event handlers
- R-first development workflow

But there are significant limitations:

### No Async/Await in R

This is the most significant limitation. R doesn't have async/await, and webR
executes R code synchronously. This means:

- **Long-running computations block everything** - If you run an expensive
  calculation in an event handler, the entire R environment is blocked until it
  completes. You can't update progress, cancel operations, or run other
  callbacks during that time.

- **Component functions must be fast** - These are called on every render (like
  React function components). Any expensive computation here will make the UI
  unresponsive.

- **No way to yield control mid-execution** - Unlike JavaScript's `async/await`
  or `setTimeout`, you can't break up work into chunks that yield back to the
  event loop.

**Workarounds** are possible but awkward:

- Cache expensive results in state and only recompute when inputs change
- Show loading states with no progress indication
- Break work into multiple event handler calls (each triggers a re-render)
- Extend the JavaScript bridge to orchestrate chunked R execution

This is a fundamental architectural constraint, not something that can be easily
fixed. A production version would need bridge-level support for
interruptible/chunkable R computations.

### Other Missing Features

- Additional hooks (`use_effect`, `use_memo`, `use_callback`, `use_ref`)
- Comprehensive event support
- Form input handling

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

This is an experimental project. If you're interested in exploring these ideas
or have thoughts on how to address the limitations, contributions and feedback
are welcome.

## License

MIT License - see LICENSE file for details
