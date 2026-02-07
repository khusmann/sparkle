/**
 * Build script for Sparkle JavaScript runtime
 * Bundles React, ReactDOM, webR, and Sparkle bridge into a single file
 */

const esbuild = require('esbuild');
const path = require('path');
const fs = require('fs');

const outDir = path.join(__dirname, 'inst', 'www');
const outFile = path.join(outDir, 'bundle.js');

// Ensure output directory exists
if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

async function build() {
  try {
    console.log('Building Sparkle runtime...');

    await esbuild.build({
      entryPoints: [path.join(__dirname, 'inst', 'www', 'sparkle-runtime', 'bridge.js')],
      bundle: true,
      outfile: outFile,
      format: 'esm',  // Use ES modules to support dynamic imports
      platform: 'browser',
      target: 'es2020',
      minify: false, // Set to true for production
      sourcemap: true,
      define: {
        'process.env.NODE_ENV': '"production"'
      },
      banner: {
        js: '// Sparkle Runtime Bundle\n// Generated: ' + new Date().toISOString()
      }
    });

    console.log('✓ Bundle created:', outFile);

    // Get bundle size
    const stats = fs.statSync(outFile);
    const sizeMB = (stats.size / 1024 / 1024).toFixed(2);
    console.log(`  Size: ${sizeMB} MB`);

  } catch (error) {
    console.error('Build failed:', error);
    process.exit(1);
  }
}

build();
