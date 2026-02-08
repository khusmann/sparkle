# Multi-File Counter Example

This example demonstrates how to organize a Sparkle app across multiple files for better code organization and maintainability.

## Running the App

```r
sparkle::sparkle_app("examples/counter-multifile/")
```

## File Structure

```
counter-multifile/
├── aaa-libraries.R  # Library imports (loaded first)
├── components.R    # Reusable UI components
├── main.R          # Main App component
├── utils.R         # Helper functions
└── README.md       # This file
```

## How It Works

### File Loading Order

Files are loaded **alphabetically** by sparkle:
1. `aaa-libraries.R` - Loaded first (imports sparkle & zeallot)
2. `components.R` - Loaded second
3. `main.R` - Loaded third
4. `utils.R` - Loaded fourth

All functions and libraries from all files are available in the global scope, so:
- Libraries only need to be loaded once in `aaa-libraries.R`
- `main.R` can use components from `components.R`
- `components.R` can use utilities from `utils.R`
- Order doesn't matter as long as the `App` function is defined

### App Component

The `App` function **must** be defined in one of your files (can be any file). By convention, Sparkle looks for a function named `App` and uses it as the entry point.

## Code Organization

### aaa-libraries.R
Loads all required packages:
- `library(sparkle)` - Sparkle framework
- `library(zeallot)` - For destructuring assignment (`%<-%`)

**Why prefix with `aaa-`?** Files are loaded alphabetically, so `aaa-` ensures libraries are loaded before any other code that depends on them.

### utils.R
Contains pure helper functions that don't render UI:
- `format_count()` - Format numbers with signs
- `get_status_message()` - Generate status messages based on count
- `get_count_color()` - Determine colors for different count values

### components.R
Contains reusable UI component functions:
- `CounterDisplay()` - Shows the current count with dynamic styling
- `ActionButton()` - Styled button with variants
- `StatsCard()` - Statistics display card

### main.R
Contains the main `App` component that:
- Manages application state
- Defines event handlers
- Composes UI using components from `components.R`
- Uses utilities from `utils.R`

## Benefits of Multi-File Organization

1. **Separation of Concerns**: Logic, UI components, and utilities are separated
2. **Reusability**: Components can be easily reused across different parts of the app
3. **Maintainability**: Easier to find and modify specific functionality
4. **Collaboration**: Multiple developers can work on different files
5. **Testing**: Individual functions can be tested in isolation

## Key Takeaways

- Use multiple files to organize complex apps
- Split code by concern (UI components, utilities, state management)
- The `App` function is your entry point
- All files are concatenated and sourced together
- Functions from any file can be used in any other file
