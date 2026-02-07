/**
 * Sparkle Bridge: Main coordinator between webR and React
 * This is the entry point for the Sparkle runtime
 */

import React from 'react';
import ReactDOM from 'react-dom/client';
import { createComponentFactory } from './component-factory.js';
import { createEventHandler } from './event-handler.js';
import { getHookManager, createUseStateBridge } from './hook-manager.js';

// WebR will be loaded from CDN and available globally

class SparkleBridge {
  constructor() {
    this.webR = null;
    this.componentFactory = null;
    this.eventHandler = null;
    this.hookManager = null;
    this.root = null;
    this.componentFunction = null;
  }

  /**
   * Initialize the Sparkle runtime
   */
  async init(rootElement) {
    try {
      console.log('Initializing Sparkle...');

      // Show loading message
      rootElement.innerHTML = '<div id="loading">Initializing webR...</div>';

      // Initialize webR - load it dynamically from CDN
      console.log('Loading webR...');

      // Import webR as an ES module
      const { WebR } = await import('https://webr.r-wasm.org/latest/webr.mjs');

      this.webR = new WebR({
        baseUrl: 'https://webr.r-wasm.org/latest/',
      });

      await this.webR.init();
      console.log('webR initialized');

      // Create managers
      this.eventHandler = createEventHandler(this.webR, this);
      this.componentFactory = createComponentFactory(this.eventHandler);
      this.hookManager = getHookManager();

      // Set up R environment
      await this.setupREnvironment();

      // Load component code and name from window
      const componentCode = window.SPARKLE_COMPONENT_CODE;
      const componentName = window.SPARKLE_COMPONENT_NAME;

      if (!componentCode) {
        throw new Error('No component code provided');
      }
      if (!componentName) {
        throw new Error('No component name provided');
      }

      this.componentName = componentName;

      console.log('Loading component code...');
      await this.loadComponent(componentCode);

      // Create React root
      this.root = ReactDOM.createRoot(rootElement);

      // Render the app
      this.render();

      console.log('Sparkle initialized successfully!');
    } catch (error) {
      console.error('Failed to initialize Sparkle:', error);
      rootElement.innerHTML = `
        <div style="color: red; padding: 20px;">
          <h2>Failed to initialize Sparkle</h2>
          <pre>${error.message}</pre>
        </div>
      `;
    }
  }

  /**
   * Set up the R environment with necessary functions and state
   */
  async setupREnvironment() {
    // Install required packages (in production, these would be pre-bundled)
    // For POC, we'll use base R only

    // Load the sparkle R code
    // In a real implementation, we'd load from the package
    // For POC, we'll define essential functions directly

    await this.webR.evalR(`
      # Initialize sparkle environment
      .sparkle_callbacks <- new.env(parent = emptyenv())
      .sparkle_hook_state <- new.env(parent = emptyenv())
      .sparkle_hook_state$hook_index <- 0L
      .sparkle_hook_state$state_values <- list()

      # Define invoke_callback for JS to call
      invoke_callback <- function(callback_id, args = list()) {
        if (!exists(callback_id, envir = .sparkle_callbacks)) {
          stop("Callback not found: ", callback_id)
        }
        fn <- get(callback_id, envir = .sparkle_callbacks)
        do.call(fn, args)
      }

      # Define wrap_fn for R code to use
      wrap_fn <- function(fn) {
        callback_id <- paste0("cb_", as.integer(as.numeric(Sys.time()) * 1000), "_", sample.int(10000, 1))
        assign(callback_id, fn, envir = .sparkle_callbacks)
        list(callback_id = callback_id)
      }

      # Global state accessor functions (for use in callbacks)
      sparkle_get_state <- function(index) {
        .sparkle_hook_state$state_values[[index + 1]]
      }

      sparkle_set_state <- function(index, value) {
        .sparkle_hook_state$state_values[[index + 1]] <- value
        # Signal to JS that state changed - return special marker
        list(
          sparkle_state_update = TRUE,
          index = index,
          value = value
        )
      }

      # Define use_state for R code
      use_state <- function(initial_value) {
        # Get current hook index
        hook_idx <- .sparkle_hook_state$hook_index
        .sparkle_hook_state$hook_index <- hook_idx + 1L

        # Initialize state if first call
        if (length(.sparkle_hook_state$state_values) < hook_idx + 1) {
          .sparkle_hook_state$state_values[[hook_idx + 1]] <- initial_value
        }

        # Get current value
        current_value <- .sparkle_hook_state$state_values[[hook_idx + 1]]

        # Return state index for use in callbacks
        list(
          index = hook_idx,
          value = current_value
        )
      }

      # Reset hook index before each render
      reset_hooks <- function() {
        .sparkle_hook_state$hook_index <- 0L
      }

      # Define tags
      create_element <- function(tag, ...) {
        args <- list(...)
        prop_names <- names(args)
        if (is.null(prop_names)) prop_names <- rep("", length(args))

        props <- list()
        children <- list()

        for (i in seq_along(args)) {
          if (prop_names[i] != "") {
            props[[prop_names[i]]] <- args[[i]]
          } else {
            children <- append(children, list(args[[i]]))
          }
        }

        list(tag = tag, props = props, children = children)
      }

      tags <- list(
        div = function(...) create_element("div", ...),
        button = function(...) create_element("button", ...),
        h1 = function(...) create_element("h1", ...),
        h2 = function(...) create_element("h2", ...),
        h3 = function(...) create_element("h3", ...),
        p = function(...) create_element("p", ...),
        span = function(...) create_element("span", ...)
      )
    `);

    // Expose the hook bridge to R
    // This is a simplified version - in production, we'd use webR's JS proxy
    console.log('R environment set up');
  }

  /**
   * Load and evaluate the component code
   */
  async loadComponent(componentCode) {
    // Evaluate the component function in R
    await this.webR.evalR(componentCode);

    // The component function is now defined in R's global environment
    // We'll call it during render
  }

  /**
   * Trigger a re-render of the component
   */
  triggerRerender() {
    if (this.rerenderCallback) {
      this.rerenderCallback();
    }
  }

  /**
   * Render the Sparkle app
   */
  render() {
    const SparkleApp = () => {
      const [renderCount, setRenderCount] = React.useState(0);
      const [rOutput, setROutput] = React.useState(null);
      const [isUpdating, setIsUpdating] = React.useState(false);
      const isFirstRender = React.useRef(true);

      // Store rerender callback for state updates
      this.rerenderCallback = () => {
        setRenderCount(c => c + 1);
      };

      React.useEffect(() => {
        // Reset hook index before rendering
        this.hookManager.reset();

        // Set updating state (but not on first render where we want true loading)
        if (!isFirstRender.current) {
          setIsUpdating(true);
        }

        // Call the R component function
        this.callRComponent()
          .then(output => {
            setROutput(output);
            setIsUpdating(false);
            isFirstRender.current = false;
          })
          .catch(error => {
            console.error('Error calling R component:', error);
            setIsUpdating(false);
            isFirstRender.current = false;
          });
      }, [renderCount]);

      if (!rOutput) {
        return React.createElement('div', null, 'Loading component...');
      }

      // Convert R output to React elements
      const content = this.componentFactory.toReactElement(rOutput);

      // Wrap in a div with opacity transition during updates
      return React.createElement('div', {
        style: {
          opacity: isUpdating ? 0.6 : 1,
          transition: 'opacity 0.15s ease-in-out'
        }
      }, content);
    };

    // Render the app
    this.root.render(React.createElement(SparkleApp));
  }

  /**
   * Recursively convert webR objects to plain JavaScript objects
   */
  async convertRObject(rObj) {
    // Handle primitives
    if (!rObj || typeof rObj !== 'object') {
      return rObj;
    }

    // Check if it's a webR proxy (has .toJs method)
    let jsObj;
    if (typeof rObj.toJs === 'function') {
      jsObj = await rObj.toJs();
    } else {
      // Already a plain JavaScript object
      jsObj = rObj;
    }

    // Check if it's an R object with type property
    if (jsObj && typeof jsObj === 'object') {
      // Handle R atomic types (character, numeric, integer, logical)
      if (jsObj.type && jsObj.values && Array.isArray(jsObj.values)) {
        if (jsObj.type === 'list') {
          // It's an R list - convert to plain object or array
          const result = {};
          if (jsObj.names && Array.isArray(jsObj.names)) {
            // Named list
            for (let i = 0; i < jsObj.names.length; i++) {
              const name = jsObj.names[i];
              const value = jsObj.values[i];
              // Recursively convert nested values
              result[name] = await this.convertRObject(value);
            }
            return result;
          } else {
            // Unnamed list - convert to array
            const arr = [];
            for (const value of jsObj.values) {
              arr.push(await this.convertRObject(value));
            }
            return arr;
          }
        } else if (['character', 'string', 'numeric', 'integer', 'double', 'logical'].includes(jsObj.type)) {
          // It's an R vector - return the single value if length 1, otherwise return array
          if (jsObj.values.length === 1) {
            return jsObj.values[0];
          } else {
            return jsObj.values;
          }
        }
      } else if (Array.isArray(jsObj)) {
        // It's already an array - recursively convert items
        const arr = [];
        for (const item of jsObj) {
          arr.push(await this.convertRObject(item));
        }
        return arr;
      }
    }

    return jsObj;
  }

  /**
   * Call the R component function and get its output
   */
  async callRComponent() {
    try {
      // Reset hook index before rendering
      await this.webR.evalR('reset_hooks()');

      // Execute the component function using the stored component name
      const result = await this.webR.evalR(`${this.componentName}()`);

      // Convert the result to plain JavaScript
      const jsResult = await this.convertRObject(result);

      return jsResult;
    } catch (error) {
      console.error('Error calling R component:', error);
      throw error;
    }
  }
}

// Global Sparkle instance
let sparkleInstance = null;

/**
 * Initialize Sparkle (called from index.html)
 */
export function init(rootElement) {
  if (!sparkleInstance) {
    sparkleInstance = new SparkleBridge();
  }
  return sparkleInstance.init(rootElement);
}

// Expose to window for index.html
window.Sparkle = { init };

export default { init };
