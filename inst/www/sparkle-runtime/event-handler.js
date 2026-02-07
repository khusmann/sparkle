/**
 * Handles event callbacks from React to R via webR
 */

class EventHandler {
  constructor(webR, bridge) {
    this.webR = webR;
    this.bridge = bridge;
    this.pendingCallbacks = new Map();
    this.callbackCounter = 0;
  }

  /**
   * Create a JavaScript event handler that calls an R function
   *
   * @param {Object} callbackObj - The sparkle_callback object from R
   * @returns {Function} - JavaScript event handler
   */
  createHandler(callbackObj) {
    if (!callbackObj || !callbackObj.callback_id) {
      console.error('Invalid callback object:', callbackObj);
      return () => {};
    }

    const callbackId = callbackObj.callback_id;

    // Return an async event handler
    return async (event) => {
      try {
        // Prevent default for some events (can be made configurable)
        // event.preventDefault();

        // Execute the R callback via webR
        const result = await this.webR.evalR(`
          invoke_callback("${callbackId}", list())
        `);

        // Convert the result to JS
        const jsResult = await this.bridge.convertRObject(result);

        // Check if this is a state update signal
        if (jsResult && jsResult.sparkle_state_update === true) {
          console.log('State update detected:', jsResult);
          // Trigger a re-render
          this.bridge.triggerRerender();
        }

        return jsResult;
      } catch (error) {
        console.error('Error executing R callback:', error);
        throw error;
      }
    };
  }

  /**
   * Process a callback object from R
   * If it's a sparkle_callback, create a handler
   * Otherwise return as-is
   */
  processCallback(value) {
    if (value && typeof value === 'object' && value.callback_id) {
      return this.createHandler(value);
    }
    return value;
  }
}

/**
 * Create an event handler manager
 */
export function createEventHandler(webR, bridge) {
  return new EventHandler(webR, bridge);
}
