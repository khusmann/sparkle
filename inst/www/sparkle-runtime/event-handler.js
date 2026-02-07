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
   * Extract serializable event data from JavaScript Event object
   * @param {Event} event - The JavaScript event object
   * @returns {Object} - Serializable event data
   */
  extractEventData(event) {
    const eventData = {
      type: event.type || null
    };

    // Extract target properties if available
    if (event.target) {
      eventData.target = {
        value: event.target.value !== undefined ? event.target.value : null,
        checked: event.target.checked !== undefined ? event.target.checked : null,
        name: event.target.name || null,
        type: event.target.type || null,
        id: event.target.id || null
      };
    }

    // Extract keyboard event properties
    if (event.key !== undefined) {
      eventData.key = event.key;
      eventData.keyCode = event.keyCode;
      eventData.shiftKey = event.shiftKey;
      eventData.ctrlKey = event.ctrlKey;
      eventData.altKey = event.altKey;
      eventData.metaKey = event.metaKey;
    }

    // Extract mouse event properties
    if (event.clientX !== undefined) {
      eventData.clientX = event.clientX;
      eventData.clientY = event.clientY;
      eventData.button = event.button;
    }

    return eventData;
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

        // Extract serializable event data
        const eventData = this.extractEventData(event);

        // Build R list structure directly using evalR for proper type conversion
        // Escape strings for R
        const escapeForR = (str) => {
          if (str === null || str === undefined) return 'NULL';
          return `"${String(str).replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
        };

        // Build R code to create the event list
        let rCode = 'list(';
        const parts = [];

        // Add type
        parts.push(`type = ${escapeForR(eventData.type)}`);

        // Add target data if present
        if (eventData.target) {
          const targetParts = [];
          if (eventData.target.value !== null && eventData.target.value !== undefined) {
            targetParts.push(`value = ${escapeForR(eventData.target.value)}`);
          } else {
            targetParts.push('value = NULL');
          }
          if (eventData.target.checked !== null && eventData.target.checked !== undefined) {
            targetParts.push(`checked = ${eventData.target.checked ? 'TRUE' : 'FALSE'}`);
          } else {
            targetParts.push('checked = NULL');
          }
          targetParts.push(`name = ${escapeForR(eventData.target.name)}`);
          targetParts.push(`type = ${escapeForR(eventData.target.type)}`);
          targetParts.push(`id = ${escapeForR(eventData.target.id)}`);
          parts.push(`target = list(${targetParts.join(', ')})`);
        }

        // Add keyboard event properties if present
        if (eventData.key !== undefined) {
          parts.push(`key = ${escapeForR(eventData.key)}`);
          parts.push(`keyCode = ${eventData.keyCode || 'NULL'}`);
          parts.push(`shiftKey = ${eventData.shiftKey ? 'TRUE' : 'FALSE'}`);
          parts.push(`ctrlKey = ${eventData.ctrlKey ? 'TRUE' : 'FALSE'}`);
          parts.push(`altKey = ${eventData.altKey ? 'TRUE' : 'FALSE'}`);
          parts.push(`metaKey = ${eventData.metaKey ? 'TRUE' : 'FALSE'}`);
        }

        // Add mouse event properties if present
        if (eventData.clientX !== undefined) {
          parts.push(`clientX = ${eventData.clientX}`);
          parts.push(`clientY = ${eventData.clientY}`);
          parts.push(`button = ${eventData.button}`);
        }

        rCode += parts.join(', ') + ')';

        // Execute the R callback with the constructed event data
        const result = await this.webR.evalR(`
          e <- ${rCode}
          invoke_callback("${callbackId}", list(e = e))
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
