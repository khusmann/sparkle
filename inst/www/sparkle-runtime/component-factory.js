/**
 * Converts R virtual DOM descriptions to React elements
 */

import React from 'react';
import { transformProps } from './prop-transformer.js';

/**
 * Optimistic input wrapper for controlled text inputs
 * Maintains local state for instant updates while R state syncs in background
 */
function OptimisticInput({ value: rValue, onChange: rOnChange, ...otherProps }) {
  // Local state for optimistic updates
  const [localValue, setLocalValue] = React.useState(rValue);
  const debounceTimer = React.useRef(null);

  // Update local value when R value changes (e.g., programmatic clear)
  React.useEffect(() => {
    setLocalValue(rValue);
  }, [rValue]);

  // Handle change with optimistic update
  const handleChange = (event) => {
    const newValue = event.target.value;

    // Update local state immediately (optimistic)
    setLocalValue(newValue);

    // Create a synthetic event to pass later (React events are pooled)
    const syntheticEvent = {
      target: {
        value: newValue,
        name: event.target.name,
        type: event.target.type,
        id: event.target.id
      },
      type: event.type
    };

    // Clear existing timer
    if (debounceTimer.current) {
      clearTimeout(debounceTimer.current);
    }

    // Debounce R callback to batch rapid keystrokes
    debounceTimer.current = setTimeout(() => {
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
   * @returns {React.ReactElement|string|number} - React element
   */
  toReactElement(rDescription) {
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
        this.toReactElement(child, index)
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
              this.toReactElement(child)
            )
          )
        : this.toReactElement(children);

      // Check if this is a controlled text input that needs optimistic updates
      const isControlledTextInput =
        tag === 'input' &&
        (!transformedProps.type || transformedProps.type === 'text') &&
        transformedProps.value !== undefined &&
        transformedProps.onChange !== undefined;

      // Use OptimisticInput wrapper for controlled text inputs
      if (isControlledTextInput) {
        return React.createElement(OptimisticInput, transformedProps);
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
