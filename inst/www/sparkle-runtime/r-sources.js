/**
 * R source files bundled for webR
 * These are imported as raw text and injected into webR
 */

import tagsSource from '../../../R/tags.R';
import hooksSource from '../../../R/hooks.R';
import callbacksSource from '../../../R/callbacks.R';
import styledCoreSource from '../../../R/styled-core.R';
import styledSource from '../../../R/styled.R';
import uiComponentsSource from '../../../R/ui-components.R';

export const rSources = {
  tags: tagsSource,
  hooks: hooksSource,
  callbacks: callbacksSource,
  styledCore: styledCoreSource,
  styled: styledSource,
  uiComponents: uiComponentsSource,
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
    '',
    rSources.styledCore,
    '',
    rSources.styled,
    '',
    rSources.uiComponents,
  ].join('\n');
}
