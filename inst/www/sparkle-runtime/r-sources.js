/**
 * R source files bundled for webR
 * These are imported as raw text and injected into webR
 */

import tagsSource from '../../../R/tags.R';
import hooksSource from '../../../R/hooks.R';
import callbacksSource from '../../../R/callbacks.R';

export const rSources = {
  tags: tagsSource,
  hooks: hooksSource,
  callbacks: callbacksSource,
};

/**
 * Get the combined R source code
 */
export function getCombinedRSource() {
  return [
    '# Sparkle R Runtime',
    '# Loaded from package source files',
    '',
    rSources.tags,
    '',
    rSources.hooks,
    '',
    rSources.callbacks,
  ].join('\n');
}
