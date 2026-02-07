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

        // Create R list structure using webR's RObject API
        const listData = {
          type: eventData.type || null
        };

        // Add target data if present
        if (eventData.target) {
          const targetList = await new this.webR.RList({
            value: eventData.target.value || null,
            checked: eventData.target.checked !== null ? eventData.target.checked : null,
            name: eventData.target.name || null,
            type: eventData.target.type || null,
            id: eventData.target.id || null
          });
          listData.target = targetList;
        }

        // Add keyboard event properties if present
        if (eventData.key !== undefined) {
          listData.key = eventData.key;
          listData.keyCode = eventData.keyCode;
          listData.shiftKey = eventData.shiftKey;
          listData.ctrlKey = eventData.ctrlKey;
          listData.altKey = eventData.altKey;
          listData.metaKey = eventData.metaKey;
        }

        // Add mouse event properties if present
        if (eventData.clientX !== undefined) {
          listData.clientX = eventData.clientX;
          listData.clientY = eventData.clientY;
          listData.button = eventData.button;
        }

        const eventList = await new this.webR.RList(listData);

        // Execute the R callback via webR with event data
        const result = await this.webR.evalR(`
          invoke_callback("${callbackId}", list(e = .GlobalEnv$.webr_event_data))
        `, { env: { '.webr_event_data': eventList } });

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
