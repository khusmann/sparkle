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
├── layout.R             # Reusable layout components
├── stats-card.R         # StatsCard component
├── todo-item.R          # TodoItem component and StyledCheckbox
├── utils.R              # Helper functions
├── main.R               # Main App component
└── README.md            # This file
```

## How It Works

### File Loading Order

Files are loaded **alphabetically** by sparkle:
1. `aaa-libraries.R` - Loaded first (imports sparkle & zeallot)
2. `layout.R` - Reusable layout components
3. `main.R` - Main App component
4. `stats-card.R` - StatsCard component
5. `todo-item.R` - TodoItem and form components
6. `utils.R` - Helper utilities

All functions and libraries from all files are available in the global scope, so:
- Libraries only need to be loaded once in `aaa-libraries.R`
- `main.R` can use components from `layout.R`, `stats-card.R`, and `todo-item.R`
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

### layout.R
Contains reusable layout components using Sparkle's styled component system:
- `HeaderSection` - Centered header layout
- `TasksHeader` - Flex header with space-between layout (for title + actions)
- `CenterWrapper` - Centered content wrapper

These are **module-level** styled components (defined at the top level) because they have static styling and can be reused across the app.

### stats-card.R
Contains a reusable metric display component:
- `StatsCard(count, label, color)` - A parameterized component for displaying statistics
  - Creates internal styled components for container, number, and label
  - Accepts dynamic props (count, label, color)
  - Demonstrates **function-level** styled components (defined inside a function)

This shows the difference between:
- **Module-level**: Static styled components defined at the top level (like in `layout.R`)
- **Function-level**: Dynamic components that accept parameters and create styled components internally

### todo-item.R
Contains TODO-specific components:
- `StyledCheckbox` - A styled checkbox input (module-level)
- `TodoItem()` - A complete todo item component with dynamic styling based on completion state
  - Uses `styled_div()` for the container with hover effects
  - Uses `styled_span()` for the text with dynamic strikethrough
  - Integrates with design system components (`ui$Badge`, `ui$Button`)

This file demonstrates:
- Creating custom styled components with `styled_*` functions
- Using dynamic styling based on component state/props
- Combining styled components with design system components
- Defining complex CSS with pseudo-selectors (`:hover`)

### main.R
Contains the main `App` component that:
- Manages application state (todos list, input text)
- Calculates derived state (stats, counts)
- Defines event handlers for adding, toggling, and deleting todos
- Composes UI using the design system and styled components
- Uses layout components (`HeaderSection`, `TasksHeader`, `CenterWrapper`)
- Uses `StatsCard` for displaying metrics
- Uses `TodoItem` for rendering individual todos
- Uses utilities from `utils.R`

## Styled Components Pattern

This example highlights the **styled components** pattern in Sparkle:

1. **Definition**: Styled components are created using `styled_*()` functions (e.g., `styled_div()`, `styled_span()`)

2. **Module-level vs Function-level**:
   - **Module-level** (e.g., `layout.R`): Static styled components defined at the top level, reusable anywhere
   - **Function-level** (e.g., `stats-card.R`): Components that accept parameters and create styled components internally

3. **Dynamic Styling**: Props can be computed based on state:
   ```r
   styled_div(
     background_color = if (todo$completed) "#f9fafb" else "white",
     color = if (todo$completed) "#9ca3af" else "#111827"
   )
   ```

4. **CSS-in-R**: Advanced CSS with pseudo-selectors via the `css` parameter:
   ```r
   styled_div(
     css = "&:hover { border-color: #d1d5db; }"
   )
   ```

5. **Component-Centric Organization**: This example organizes components by their purpose:
   - **Reusable utilities** (`layout.R`, `stats-card.R`) - Can be used in any app
   - **Domain-specific** (`todo-item.R`) - Specific to TODO functionality
   - This makes it clear which components are general-purpose vs application-specific

## Benefits of This Organization

1. **Separation of Concerns**: Styling, logic, and utilities are cleanly separated
2. **Reusability**: Layout and stats components can be used in any app; domain-specific components are isolated
3. **Maintainability**: Easy to find and update components by their purpose (layout vs stats vs todo-specific)
4. **Scalability**: Component-centric pattern scales well as apps grow in complexity
5. **Clarity**: Main app logic is easier to read with semantic component names like `HeaderSection` and `StatsCard`
6. **Reduced Repetition**: `StatsCard` eliminates 35+ lines of duplicated inline styling code

## Key Takeaways

- Organize components by purpose: reusable utilities vs domain-specific
- Use **module-level** styled components for static, reusable layouts
- Use **function-level** styled components for parameterized, dynamic components
- Extract repeated patterns (like stats cards) into reusable components
- Use `styled_*()` functions for creating custom styled components
- Combine styled components with design system components (`ui$*`)
- Keep the main App component focused on composition and logic
- All files share a global scope after concatenation
