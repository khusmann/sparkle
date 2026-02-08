# Multi-File TODO List Example

This example demonstrates how to organize a Sparkle app across multiple files, with a focus on separating styled components from business logic.

## Running the App

```r
sparkle::sparkle_app("examples/todo-multifile/")
```

## File Structure

```
todo-multifile/
├── aaa-libraries.R      # Library imports (loaded first)
├── styled-components.R  # Styled UI components
├── utils.R              # Helper functions
├── main.R               # Main App component
└── README.md            # This file
```

## How It Works

### File Loading Order

Files are loaded **alphabetically** by sparkle:
1. `aaa-libraries.R` - Loaded first (imports sparkle & zeallot)
2. `main.R` - Main App component
3. `styled-components.R` - Styled component definitions
4. `utils.R` - Helper utilities

All functions and libraries from all files are available in the global scope, so:
- Libraries only need to be loaded once in `aaa-libraries.R`
- `main.R` can use components from `styled-components.R`
- Components can use utilities from `utils.R`
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
- `create_todo()` - Factory function for creating new todo items with unique IDs

### styled-components.R
Contains styled UI components using Sparkle's styled component system:
- `TodoItem()` - A complete todo item component with dynamic styling based on completion state
  - Uses `styled_div()` for the container with hover effects
  - Uses `styled_span()` for the text with dynamic strikethrough
  - Integrates with design system components (`ui$Badge`, `ui$Button`)

This file demonstrates how to:
- Create custom styled components with `styled_*` functions
- Use dynamic styling based on component state/props
- Combine styled components with design system components
- Define complex CSS with pseudo-selectors (`:hover`)

### main.R
Contains the main `App` component that:
- Manages application state (todos list, input text)
- Calculates derived state (stats, counts)
- Defines event handlers for adding, toggling, and deleting todos
- Composes UI using the design system and styled components
- Uses utilities from `utils.R` and components from `styled-components.R`

## Styled Components Pattern

This example highlights the **styled components** pattern in Sparkle:

1. **Definition**: Styled components are created using `styled_*()` functions (e.g., `styled_div()`, `styled_span()`)

2. **Dynamic Styling**: Props can be computed based on state:
   ```r
   styled_div(
     background_color = if (todo$completed) "#f9fafb" else "white",
     color = if (todo$completed) "#9ca3af" else "#111827"
   )
   ```

3. **CSS-in-R**: Advanced CSS with pseudo-selectors via the `css` parameter:
   ```r
   styled_div(
     css = "&:hover { border-color: #d1d5db; }"
   )
   ```

4. **Separation**: By putting all styled components in a dedicated file, you:
   - Keep styling logic separate from business logic
   - Make components easily reusable
   - Improve maintainability and readability

## Benefits of This Organization

1. **Separation of Concerns**: Styling, logic, and utilities are cleanly separated
2. **Reusability**: Styled components can be easily reused and modified
3. **Maintainability**: Easy to find and update styles without touching business logic
4. **Scalability**: Pattern scales well as apps grow in complexity
5. **Clarity**: Main app logic is easier to read without styling details mixed in

## Key Takeaways

- Separate styled components into their own file for better organization
- Use `styled_*()` functions for creating reusable, dynamically styled components
- Combine styled components with design system components (`ui$*`)
- The `App` function orchestrates everything from `main.R`
- All files share a global scope after concatenation
