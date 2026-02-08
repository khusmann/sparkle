/**
 * Converts R virtual DOM descriptions to React elements
 */

import React from 'react';
import { transformProps } from './prop-transformer.js';

/**
 * Optimistic Input Wrapper for Controlled Text Inputs
 *
 * This component provides instant UI feedback for text inputs while R state syncs in the background.
 * It prevents race conditions where stale R responses could overwrite newer local state.
 *
 * ## How It Works:
 *
 * 1. **Local State**: Maintains immediate UI state for instant feedback on every keystroke
 * 2. **Debouncing**: Batches rapid keystrokes into a single R update (50ms window)
 * 3. **Sequence Numbers**: Each debounced update gets a unique, incrementing sequence number
 * 4. **Sequence Checking**: Only accepts R values from renders with sequence >= latest sent
 *
 * ## The Race Condition Problem:
 *
 * Without sequence numbers, this scenario causes lost characters:
 *
 * ```
 * t=0ms:   User types "a" → send to R (slow network/processing)
 * t=50ms:  User types "bcd" → send "abcd" to R
 * t=100ms: R responds with "a" (late!) → overwrites local "abcd" → data loss!
 * ```
 *
 * With sequence numbers:
 *
 * ```
 * t=0ms:   User types "a" → send seq=1 to R
 * t=50ms:  User types "bcd" → send seq=2 to R, latestSeq=2
 * t=100ms: R responds with "a" (seq=1) → REJECTED (1 < 2) → no data loss!
 * ```
 *
 * ## Extending to Other Control Types:
 *
 * To add optimistic updates for other controls (checkboxes, selects, etc.), follow this pattern:
 *
 * ```javascript
 * function OptimisticCheckbox({ checked: rChecked, renderSequence, onChange: rOnChange, ...otherProps }) {
 *   const [localChecked, setLocalChecked] = React.useState(rChecked);
 *   const sequenceNumber = React.useRef(0);
 *   const latestSequence = React.useRef(0);
 *   const debounceTimer = React.useRef(null);
 *
 *   // Accept R value if no sequence (programmatic) or sequence >= latest sent
 *   React.useEffect(() => {
 *     if (renderSequence === undefined || renderSequence >= latestSequence.current) {
 *       setLocalChecked(rChecked);
 *     }
 *   }, [rChecked, renderSequence]);
 *
 *   const handleChange = (event) => {
 *     const newChecked = event.target.checked;
 *     setLocalChecked(newChecked); // Optimistic update
 *
 *     // Assign sequence and send to R (with or without debouncing)
 *     const currentSeq = ++sequenceNumber.current;
 *     latestSequence.current = currentSeq;
 *
 *     if (rOnChange) {
 *       rOnChange({
 *         target: { checked: newChecked },
 *         __sparkle_sequence: currentSeq
 *       });
 *     }
 *   };
 *
 *   return React.createElement('input', {
 *     ...otherProps,
 *     type: 'checkbox',
 *     checked: localChecked,
 *     onChange: handleChange
 *   });
 * }
 * ```
 *
 * Then register it in ComponentFactory.toReactElement() like OptimisticInput.
 *
 * @param {*} value - The controlled value from R's state
 * @param {number} renderSequence - Sequence number from the render (used to detect stale responses)
 * @param {Function} onChange - Callback to notify R of changes
 * @param {Object} otherProps - Other HTML input props (placeholder, disabled, etc.)
 */
function OptimisticInput({ value: rValue, renderSequence, onChange: rOnChange, ...otherProps }) {
  // Local state for optimistic updates
  const [localValue, setLocalValue] = React.useState(rValue);
  const debounceTimer = React.useRef(null);
  const sequenceNumber = React.useRef(0);
  const latestSequence = React.useRef(0);

  // Update local value when R value changes
  // Accept if: no sequence (programmatic change) OR sequence >= latest sent
  React.useEffect(() => {
    if (renderSequence === undefined || renderSequence >= latestSequence.current) {
      setLocalValue(rValue);
    }
  }, [rValue, renderSequence]);

  // Handle change with optimistic update
  const handleChange = (event) => {
    const newValue = event.target.value;

    // Assign sequence number IMMEDIATELY (before debounce)
    // This ensures latestSequence always reflects what's in localValue
    const currentSeq = ++sequenceNumber.current;
    latestSequence.current = currentSeq;

    // Update local state immediately (optimistic)
    setLocalValue(newValue);

    // Clear existing timer
    if (debounceTimer.current) {
      clearTimeout(debounceTimer.current);
    }

    // Debounce R callback to batch rapid keystrokes
    debounceTimer.current = setTimeout(() => {
      // Create a synthetic event with the sequence number we assigned above
      const syntheticEvent = {
        target: {
          value: newValue,
          name: event.target.name,
          type: event.target.type,
          id: event.target.id
        },
        type: event.type,
        __sparkle_sequence: currentSeq
      };

      if (rOnChange) {
        rOnChange(syntheticEvent);
      }
    }, 50); // 50ms debounce
  };

  // Cleanup on unmount
  React.useEffect(() => {
    return () => {
      if (debounceTimer.current) {
        clearTimeout(debounceTimer.current);
      }
    };
  }, []);

  return React.createElement('input', {
    ...otherProps,
    value: localValue,
    onChange: handleChange
  });
}

class ComponentFactory {
  constructor(eventHandler) {
    this.eventHandler = eventHandler;
  }

  /**
   * Convert an R virtual DOM description to a React element
   *
   * @param {Object|string|number} rDescription - R object describing the virtual DOM
   * @param {number|null} renderSequence - Optional sequence number from the render
   * @returns {React.ReactElement|string|number} - React element
   */
  toReactElement(rDescription, renderSequence = null) {
    // Handle primitives (text nodes)
    if (
      typeof rDescription === 'string' ||
      typeof rDescription === 'number' ||
      typeof rDescription === 'boolean'
    ) {
      return String(rDescription);
    }

    // Handle null/undefined
    if (rDescription === null || rDescription === undefined) {
      return null;
    }

    // Handle arrays
    if (Array.isArray(rDescription)) {
      return rDescription.map((child, index) =>
        this.toReactElement(child, renderSequence)
      );
    }

    // Handle sparkle_element objects
    if (typeof rDescription === 'object' && rDescription.tag) {
      const { tag, props = {}, children = [] } = rDescription;

      // Transform props (snake_case -> camelCase)
      let transformedProps = transformProps(props);

      // Process event handlers
      transformedProps = this.processProps(transformedProps);

      // Convert children recursively
      const reactChildren = Array.isArray(children)
        ? children.map((child, index) =>
            React.createElement(
              React.Fragment,
              { key: index },
              this.toReactElement(child, renderSequence)
            )
          )
        : this.toReactElement(children, renderSequence);

      // Check if this is a controlled text input that needs optimistic updates
      // Include text-like input types: text, email, url, tel, search, password
      const textInputTypes = ['text', 'email', 'url', 'tel', 'search', 'password'];
      const isControlledTextInput =
        tag === 'input' &&
        (!transformedProps.type || textInputTypes.includes(transformedProps.type)) &&
        transformedProps.value !== undefined &&
        transformedProps.onChange !== undefined;

      // Use OptimisticInput wrapper for controlled text inputs
      if (isControlledTextInput) {
        // Ensure stable key to prevent remounting
        const inputKey = transformedProps.key || transformedProps.id || transformedProps.name;
        return React.createElement(OptimisticInput, {
          ...transformedProps,
          renderSequence: renderSequence,
          key: inputKey
        });
      }

      // Create React element normally
      return React.createElement(tag, transformedProps, ...reactChildren);
    }

    // Fallback: convert to string
    console.warn('Unexpected R object type:', rDescription);
    return String(rDescription);
  }

  /**
   * Process props to handle callbacks and special values
   */
  processProps(props) {
    const processed = { ...props };

    for (const [key, value] of Object.entries(processed)) {
      // Check if this is an event handler prop
      if (key.startsWith('on') && key[2] === key[2].toUpperCase()) {
        // Process callback
        processed[key] = this.eventHandler.processCallback(value);
      }
    }

    return processed;
  }
}

/**
 * Create a component factory
 */
export function createComponentFactory(eventHandler) {
  return new ComponentFactory(eventHandler);
}
