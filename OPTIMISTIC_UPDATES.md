# Optimistic Updates in Sparkle

## The Problem

Traditional reactive frameworks (like Shiny) follow a simple request-response model:

1. User types in an input field
2. Browser sends the change to the server
3. Server processes the change and updates state
4. Server sends the new UI back to the browser
5. Browser displays the updated input value

This works fine on a local server, but webR runs entirely in the browser using WebAssembly. Each R render cycle involves:
- Crossing the JavaScript ↔ WebAssembly boundary (slow)
- Executing R code (slower than native JavaScript)
- Converting data structures between JS and R (adds overhead)

The result? Even simple text inputs can feel sluggish and unresponsive, with noticeable lag between keystrokes and the displayed text.

## The Solution: Optimistic Updates

Sparkle implements **optimistic updates** for text inputs, making them feel instantly responsive:

1. User types in an input field
2. **Browser updates the input immediately** (optimistic)
3. Browser debounces and sends the change to R (after 50ms of no typing)
4. R processes the change and sends back updated UI
5. Browser accepts the update only if it's not stale

This is called "optimistic" because we optimistically assume the user's input is valid and display it immediately, before R has confirmed it.

## How It Works

### 1. **Immediate Local Updates**

When you type in a text input, the value updates instantly in the UI. No waiting for R.

```r
ui$Input(
  value = name,
  on_change = \(e) set_name(e$target$value)
)
```

Behind the scenes, the input maintains two values:
- **Local value**: What's displayed (updates immediately)
- **R value**: What R knows about (updates after debounce + R processing)

### 2. **Debouncing**

Instead of sending every keystroke to R immediately, Sparkle waits for a 150ms pause in typing before firing the `on_change` callback. This batches rapid keystrokes together:

```
User types "hello" rapidly
├─ h (local: "h", no R call yet)
├─ e (local: "he", no R call yet)
├─ l (local: "hel", no R call yet)
├─ l (local: "hell", no R call yet)
├─ o (local: "hello", no R call yet)
└─ [150ms pause]
   └─ R receives "hello" (one call instead of five)
```

### 3. **Sequence Numbers**

Each user interaction gets a sequence number to track the order of events:

```
User action seq=1 → R processes → Response tagged seq=1
User action seq=2 → R processes → Response tagged seq=2
User action seq=3 → R processes → Response tagged seq=3
```

If R is slow and responses arrive out of order, Sparkle uses these sequence numbers to reject stale updates. An input only accepts updates with sequence numbers ≥ the last change the user made.

**Example scenario:**
1. User types "hello" (seq=1) → sent to R
2. User types "hello world" (seq=2) → sent to R
3. R responds with "hello world" (seq=2) → **ACCEPTED** (seq=2 ≥ seq=2)
4. R responds with "hello" (seq=1) → **REJECTED** (seq=1 < seq=2, stale)

### 4. **Render Serialization**

R's global state (hooks, state values) isn't thread-safe. If multiple renders run concurrently, they can clobber each other's state. Sparkle solves this by queuing renders:

```
Render A starts
  ├─ Render B arrives → queued (waits for A)
  ├─ Render C arrives → replaces B in queue (only latest matters)
  └─ Render A finishes
      └─ Render C starts
```

Only one render executes at a time, but only the latest queued render is kept (earlier ones are skipped since they're outdated).

## What Inputs Get Optimistic Updates?

Optimistic updates are applied to controlled text-like inputs:
- `type="text"`
- `type="email"`
- `type="url"`
- `type="tel"`
- `type="search"`
- `type="password"`

Other input types (checkboxes, radio buttons, selects) don't need optimistic updates because they don't have the same rapid keystroke problem.

## Programmatic Updates (Reset Buttons)

When your R code programmatically changes an input value (like a reset button), Sparkle needs to override the optimistic local value:

```r
handleReset <- function() {
  set_name("")  # This should clear the input immediately
}
```

Programmatic updates are detected by the absence of a sequence number. When received, Sparkle:
1. Clears any pending debounced callbacks (prevents them from restoring old values)
2. Updates the local value immediately
3. Syncs sequence numbers to accept future user changes

## Benefits

✅ **Instant feedback** - Inputs feel native and responsive
✅ **Reduced R load** - Debouncing batches rapid changes
✅ **Correct ordering** - Sequence numbers prevent stale updates
✅ **Handles slow R** - Works even when R processing is slow
✅ **Smooth reset** - Programmatic state changes work correctly

## Tradeoffs

⚠️ **Complexity** - More moving parts than simple request-response
⚠️ **Memory overhead** - Tracking sequence numbers and pending renders
⚠️ **Validation challenges** - Invalid input might be displayed briefly before R rejects it

The tradeoffs are worth it: Sparkle apps feel as responsive as native JavaScript apps, even though they're powered by R running in WebAssembly.

## Example: See It In Action

Try the [design system demo](examples/design-system-demo.R):

```r
sparkle_app("examples/design-system-demo.R")
```

Type rapidly in the name and email fields. Notice how:
- The text appears instantly as you type (optimistic update)
- The UI stays responsive even with fast typing (debouncing)
- Reset button clears the inputs immediately (programmatic update)
- Everything stays in sync (sequence numbers)

## Technical Details

For implementation details and the bugs we fixed along the way, see [OPTIMISTIC_UPDATE_FIX.md](OPTIMISTIC_UPDATE_FIX.md).
