/**
 * Transforms prop names from R's snake_case to React's camelCase
 */

const PROP_MAPPINGS = {
  // Event handlers
  on_click: 'onClick',
  on_change: 'onChange',
  on_submit: 'onSubmit',
  on_input: 'onInput',
  on_focus: 'onFocus',
  on_blur: 'onBlur',
  on_key_down: 'onKeyDown',
  on_key_up: 'onKeyUp',
  on_key_press: 'onKeyPress',
  on_mouse_down: 'onMouseDown',
  on_mouse_up: 'onMouseUp',
  on_mouse_enter: 'onMouseEnter',
  on_mouse_leave: 'onMouseLeave',
  on_mouse_over: 'onMouseOver',
  on_mouse_out: 'onMouseOut',

  // Common attributes
  class_name: 'className',
  html_for: 'htmlFor',
  max_length: 'maxLength',
  read_only: 'readOnly',
  tab_index: 'tabIndex',
  auto_focus: 'autoFocus',
  auto_complete: 'autoComplete',

  // Aria attributes (aria_label -> aria-label)
  // These will be handled by the regex below
};

/**
 * Convert snake_case to camelCase
 */
function snakeToCamel(str) {
  return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

/**
 * Convert snake_case to kebab-case (for aria and data attributes)
 */
function snakeToKebab(str) {
  return str.replace(/_/g, '-');
}

/**
 * Transform a single prop name from R convention to React convention
 */
export function transformPropName(propName) {
  // Check explicit mappings first
  if (PROP_MAPPINGS[propName]) {
    return PROP_MAPPINGS[propName];
  }

  // Handle aria_* attributes -> aria-*
  if (propName.startsWith('aria_')) {
    return snakeToKebab(propName);
  }

  // Handle data_* attributes -> data-*
  if (propName.startsWith('data_')) {
    return snakeToKebab(propName);
  }

  // Default: convert snake_case to camelCase
  return snakeToCamel(propName);
}

/**
 * Transform style object properties from snake_case to camelCase
 */
function transformStyleObject(styleObj) {
  if (!styleObj || typeof styleObj !== 'object') {
    return styleObj;
  }

  const transformed = {};

  for (const [key, value] of Object.entries(styleObj)) {
    // Convert snake_case to camelCase for CSS properties
    const transformedKey = snakeToCamel(key);
    transformed[transformedKey] = value;
  }

  return transformed;
}

/**
 * Transform all props in an object
 */
export function transformProps(props) {
  if (!props || typeof props !== 'object') {
    return props;
  }

  const transformed = {};

  for (const [key, value] of Object.entries(props)) {
    const transformedKey = transformPropName(key);

    // Special handling for style prop - transform nested properties
    if (key === 'style' && typeof value === 'object' && value !== null) {
      transformed[transformedKey] = transformStyleObject(value);
    } else {
      transformed[transformedKey] = value;
    }
  }

  return transformed;
}
