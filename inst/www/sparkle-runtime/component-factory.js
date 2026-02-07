/**
 * Converts R virtual DOM descriptions to React elements
 */

import React from 'react';
import { transformProps } from './prop-transformer.js';

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

      // Create React element
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
