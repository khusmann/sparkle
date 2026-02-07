/**
 * Manages React hooks called from R code
 */

import React from 'react';

class HookManager {
  constructor() {
    // Maps hook indices to their React hook values
    this.hooks = new Map();
    this.currentIndex = 0;
  }

  /**
   * Reset hook index before each render
   * This is called at the start of each component render
   */
  reset() {
    this.currentIndex = 0;
  }

  /**
   * Bridge for React's useState hook
   * Called from R via webR
   *
   * @param {*} initialValue - The initial state value
   * @param {number} hookIndex - The index of this hook call
   * @returns {{value: *, set: Function}} - Object with current value and setter
   */
  useState(initialValue, hookIndex) {
    // Use React's useState
    const [value, setValue] = React.useState(initialValue);

    // Store the setter for later use
    this.hooks.set(hookIndex, { value, setValue });

    // Return an object that R can use
    return {
      value: value,
      set: (newValue) => {
        // Handle both direct values and updater functions
        if (typeof newValue === 'function') {
          setValue(prevValue => newValue(prevValue));
        } else {
          setValue(newValue);
        }
      }
    };
  }

  /**
   * Get a hook's current value by index
   */
  getHook(hookIndex) {
    return this.hooks.get(hookIndex);
  }

  /**
   * Update state from R
   * This is called when R code wants to update state
   */
  setStateFromR(hookIndex, newValue) {
    const hook = this.hooks.get(hookIndex);
    if (!hook) {
      console.error(`Hook not found at index ${hookIndex}`);
      return;
    }

    hook.setValue(newValue);
  }
}

// Global hook manager instance
let globalHookManager = null;

/**
 * Get the global hook manager (creates if doesn't exist)
 */
export function getHookManager() {
  if (!globalHookManager) {
    globalHookManager = new HookManager();
  }
  return globalHookManager;
}

/**
 * Create a useState bridge for R
 * This will be exposed to the R environment
 */
export function createUseStateBridge(webR) {
  const hookManager = getHookManager();

  return {
    use_state: async (initialValue, hookIndex) => {
      const state = hookManager.useState(initialValue, hookIndex);
      return state;
    },

    set_state: async (hookIndex, newValue) => {
      hookManager.setStateFromR(hookIndex, newValue);
    }
  };
}
