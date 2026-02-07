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
      this.eventHandler = createEventHandler(this.webR);
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
        callback_id <- paste0("cb_", as.integer(as.numeric(Sys.time()) * 1000))
        assign(callback_id, fn, envir = .sparkle_callbacks)
        list(callback_id = callback_id)
      }

      # Define use_state for R code
      # For POC: simplified version that stores state in R
      # TODO: Bridge to React's useState for proper reactivity
      use_state <- function(initial_value) {
        # Get current hook index
        hook_idx <- .sparkle_hook_state$hook_index
        .sparkle_hook_state$hook_index <- hook_idx + 1L

        # Initialize state if first call
        state_key <- paste0("state_", hook_idx)
        if (!exists(state_key, envir = .sparkle_hook_state)) {
          assign(state_key, initial_value, envir = .sparkle_hook_state)
        }

        # Get current value
        current_value <- get(state_key, envir = .sparkle_hook_state)

        # Return state object with value and setter
        list(
          value = current_value,
          set = function(new_value) {
            assign(state_key, new_value, envir = .sparkle_hook_state)
            # TODO: Trigger re-render via React
          }
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
   * Render the Sparkle app
   */
  render() {
    const SparkleApp = () => {
      const [renderCount, setRenderCount] = React.useState(0);

      // Create a React component that calls the R function
      const RComponent = () => {
        // Reset hook index before rendering
        this.hookManager.reset();

        // We need to create a mechanism to call R and get the virtual DOM
        // For POC, we'll use a ref to store the current R component output
        const [rOutput, setROutput] = React.useState(null);
        const [loading, setLoading] = React.useState(true);

        React.useEffect(() => {
          // Call the R component function
          this.callRComponent()
            .then(output => {
              setROutput(output);
              setLoading(false);
            })
            .catch(error => {
              console.error('Error calling R component:', error);
              setLoading(false);
            });
        }, [renderCount]);

        if (loading) {
          return React.createElement('div', null, 'Loading component...');
        }

        if (!rOutput) {
          return React.createElement('div', null, 'No output from component');
        }

        // Convert R output to React elements
        return this.componentFactory.toReactElement(rOutput);
      };

      return React.createElement(RComponent);
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
