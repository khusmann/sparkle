# Sparkle Setup Guide

This guide will help you get Sparkle running on your system.

## Current Status

The Sparkle POC has been fully implemented with the following structure:

### ✅ Completed Components

1. **R Package Structure**
   - [DESCRIPTION](DESCRIPTION) - Package metadata
   - [NAMESPACE](NAMESPACE) - Package exports
   - [LICENSE](LICENSE) - MIT license

2. **R API Layer** (`/R/`)
   - [tags.R](R/tags.R) - HTML tag builders (`tags$div`, `tags$button`, etc.)
   - [hooks.R](R/hooks.R) - React hooks interface (`use_state`)
   - [callbacks.R](R/callbacks.R) - Event callback wrapping (`wrap_fn`)
   - [app.R](R/app.R) - Application launcher (`sparkle_app`)

3. **JavaScript Bridge Layer** (`/inst/www/sparkle-runtime/`)
   - [bridge.js](inst/www/sparkle-runtime/bridge.js) - Main coordinator
   - [component-factory.js](inst/www/sparkle-runtime/component-factory.js) - R virtual DOM → React elements
   - [hook-manager.js](inst/www/sparkle-runtime/hook-manager.js) - React hooks bridge
   - [event-handler.js](inst/www/sparkle-runtime/event-handler.js) - Async event callbacks
   - [prop-transformer.js](inst/www/sparkle-runtime/prop-transformer.js) - snake_case → camelCase

4. **Build System**
   - [build.js](build.js) - esbuild bundler for JavaScript
   - [package.json](package.json) - npm dependencies

5. **Web Assets**
   - [inst/www/index.html](inst/www/index.html) - Base HTML template

6. **Examples**
   - [examples/counter.R](examples/counter.R) - Counter POC example

## Next Steps to Run Sparkle

### Step 1: Install Node.js and pnpm

Sparkle requires Node.js and pnpm to build the JavaScript bundle.

**Option A: Using package manager**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nodejs

# macOS (using Homebrew)
brew install node

# Fedora
sudo dnf install nodejs
```

**Option B: Using nvm (recommended)**

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Node.js LTS
nvm install --lts
nvm use --lts
```

**Then install pnpm:**

```bash
# Using npm
npm install -g pnpm

# Or using corepack (Node.js 16.13+)
corepack enable
corepack prepare pnpm@latest --activate
```

Verify installation:
```bash
node --version  # Should show v16+ or higher
pnpm --version
```

### Step 2: Install JavaScript Dependencies

From the sparkle project directory:

```bash
cd /home/khusmann/Projects/sparkle
pnpm install
```

This will install:
- `react` (^18.2.0)
- `react-dom` (^18.2.0)
- `esbuild` (^0.19.0)

### Step 3: Build the JavaScript Bundle

```bash
pnpm run build
```

This will create `/inst/www/bundle.js` containing the Sparkle runtime.

### Step 4: Load the R Package

In R:

```r
# Install R dependencies (if not already installed)
install.packages(c("jsonlite", "httpuv", "devtools"))

# Load the Sparkle package
devtools::load_all("/home/khusmann/Projects/sparkle")
```

### Step 5: Run the Counter Example

```r
# Source and run the example
source("/home/khusmann/Projects/sparkle/examples/counter.R")

# Or define it inline:
library(sparkle)

Counter <- function() {
  count <- use_state(0)

  tags$div(
    tags$h1(paste("Count:", count$value)),
    tags$button(
      "Increment",
      on_click = wrap_fn(\() count$set(count$value + 1))
    ),
    tags$button(
      "Decrement",
      on_click = wrap_fn(\() count$set(count$value - 1))
    )
  )
}

sparkle_app(Counter)
```

This will:
1. Start a dev server on http://127.0.0.1:3000
2. Open your browser automatically
3. Initialize webR (this may take 10-30 seconds the first time)
4. Render the counter app

## Troubleshooting

### "pnpm: command not found"
pnpm is not installed. Follow Step 1 above to install pnpm.

### "bundle.js not found"
The JavaScript bundle hasn't been built yet. Run `pnpm run build`.

### "Cannot find module 'esbuild'"
Dependencies not installed. Run `pnpm install`.

### webR initialization is slow
The first time webR loads, it downloads the WebAssembly runtime (~30MB). This is cached by the browser for subsequent loads.

### R package won't load
Make sure you have the required R packages:
```r
install.packages(c("jsonlite", "httpuv", "devtools"))
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  R (Component Definition)                                │
│  Counter <- function() {                                 │
│    count <- use_state(0)                                 │
│    tags$button("Click", on_click = wrap_fn(...))         │
│  }                                                        │
└────────────────┬────────────────────────────────────────┘
                 │
                 v
┌─────────────────────────────────────────────────────────┐
│  sparkle_app(Counter)                                    │
│  • Starts httpuv dev server                              │
│  • Serves index.html + bundle.js                         │
│  • Injects component code                                │
└────────────────┬────────────────────────────────────────┘
                 │
                 v
┌─────────────────────────────────────────────────────────┐
│  Browser                                                 │
│  ┌─────────────────────────────────────────────────┐   │
│  │  JavaScript Runtime (bundle.js)                  │   │
│  │  • Loads webR                                    │   │
│  │  • Initializes Sparkle bridge                    │   │
│  │  • Creates React root                            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  webR (R running in browser)                     │   │
│  │  • Evaluates Counter() function                  │   │
│  │  • Returns virtual DOM description               │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Sparkle Bridge                                  │   │
│  │  • Translates R virtual DOM to React elements    │   │
│  │  • Manages hook state                            │   │
│  │  • Handles event callbacks                       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  React                                           │   │
│  │  • Renders to DOM                                │   │
│  │  • Manages component lifecycle                   │   │
│  │  • Triggers re-renders on state change           │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## What Works in the POC

✅ **Basic HTML Tags**: `div`, `button`, `h1`, `h2`, `h3`, `p`, `span`, `input`, `label`

✅ **State Management**: `use_state(initial_value)` with `.value` and `.set()`

✅ **Event Handlers**: `on_click` wrapped with `wrap_fn()`

✅ **Prop Transformation**: Automatic snake_case → camelCase conversion

✅ **Dev Server**: Local httpuv server with hot reload

✅ **R-first Workflow**: Write R code, launch with `sparkle_app()`

## What's Not Implemented Yet

⚠️ **Actual webR Integration**: The current implementation has the structure but needs the actual webR binding code. The `use_state` hook currently returns mock data when not in browser context.

⚠️ **Full Hook Bridge**: The JavaScript hook manager is implemented but needs proper webR JS interop setup.

⚠️ **Testing**: No automated tests yet - verification is manual only.

⚠️ **More Hooks**: Only `use_state` is implemented. Need `use_effect`, `use_memo`, etc.

⚠️ **More Events**: Only `on_click` is tested. Other events should work but are untested.

⚠️ **Error Handling**: Limited error handling and user feedback.

## Known Limitations

1. **webR Loading Time**: First load takes 10-30 seconds while webR downloads
2. **Performance**: R code runs in webR worker, so there's overhead on each render
3. **Debugging**: Limited debugging tools for the R-React bridge
4. **Browser Support**: Requires modern browsers with WebAssembly support

## Development Workflow

### Modifying R Code
1. Edit files in `/R/`
2. Reload package: `devtools::load_all()`
3. Test changes

### Modifying JavaScript Code
1. Edit files in `/inst/www/sparkle-runtime/`
2. Rebuild: `pnpm run build`
3. Refresh browser

### Adding New Tags
Edit `R/tags.R` and add new tag functions following the pattern:
```r
tags$newtag <- function(...) create_element("newtag", ...)
```

### Adding New Event Handlers
Event handler props are automatically supported via the prop transformer. Just use snake_case versions:
```r
tags$input(on_change = wrap_fn(\(e) ...))
tags$form(on_submit = wrap_fn(\(e) ...))
```

## Next Development Steps

To complete the POC and make it fully functional:

1. **Complete webR Integration**
   - Set up proper JS-to-R communication channel
   - Implement bidirectional data passing
   - Test hook state synchronization

2. **Test Counter Example End-to-End**
   - Verify state updates work
   - Verify event handlers fire
   - Test multiple rapid clicks

3. **Add More Examples**
   - Form with validation
   - Todo list with add/remove
   - Data visualization component

4. **Documentation**
   - API reference
   - Architecture deep dive
   - Contribution guide

5. **Optimize**
   - Profile render performance
   - Add memoization
   - Minimize webR overhead

## Resources

- [webR Documentation](https://docs.r-wasm.org/webr/latest/)
- [React Documentation](https://react.dev/)
- [Shiny Documentation](https://shiny.rstudio.com/)

---

Ready to build? Start with Step 1 above! 🚀
