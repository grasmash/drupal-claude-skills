# Vue Build Security (Vite/Webpack)

**OWASP Reference**: A05:2021 - Security Misconfiguration
**Severity**: High
**Target**: Vite 4.x, Webpack 5.x

## Overview

Build configuration security ensures that development tools, source maps, and sensitive information are not exposed in production builds.

---

## Vite Security Configuration

### ✅ SAFE: Production Vite Config

```javascript
// vite.config.js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig(({ mode }) => {
  const isDev = mode === 'development'
  
  return {
    plugins: [vue()],
    
    // Build configuration
    build: {
      // Disable source maps in production
      sourcemap: isDev ? true : false,
      
      // Minify in production
      minify: isDev ? false : 'terser',
      
      terserOptions: {
        compress: {
          // Remove console logs in production
          drop_console: !isDev,
          drop_debugger: true,
          pure_funcs: isDev ? [] : ['console.log', 'console.info']
        },
        format: {
          // Remove comments
          comments: false
        }
      },
      
      // Chunk size warnings
      chunkSizeWarningLimit: 500,
      
      rollupOptions: {
        output: {
          // Obfuscate chunk names
          manualChunks: (id) => {
            if (id.includes('node_modules')) {
              return 'vendor'
            }
          },
          // Hash filenames
          entryFileNames: 'js/[name].[hash].js',
          chunkFileNames: 'js/[name].[hash].js',
          assetFileNames: 'assets/[name].[hash].[ext]'
        }
      }
    },
    
    // Define safe environment variables
    define: {
      // Only expose necessary env vars
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
      __BUILD_TIME__: JSON.stringify(new Date().toISOString())
    },
    
    // Server security
    server: {
      // Disable directory listing
      fs: {
        strict: true,
        allow: [resolve(__dirname, 'src')]
      },
      
      // HTTPS in development (recommended)
      https: false, // Set to true with cert in production-like dev
      
      // Cors configuration
      cors: {
        origin: isDev ? '*' : 'https://yourdomain.com',
        credentials: true
      }
    },
    
    // Preview server (for testing builds)
    preview: {
      port: 4173,
      strictPort: true,
      headers: {
        'X-Frame-Options': 'DENY',
        'X-Content-Type-Options': 'nosniff',
        'Referrer-Policy': 'strict-origin-when-cross-origin'
      }
    }
  }
})
```

### ✅ SAFE: Environment Variables

```javascript
// .env.example (commit this)
VITE_API_URL=http://localhost:8080
VITE_APP_NAME=MyDrupalTheme

// .env (never commit this)
VITE_API_URL=https://api.example.com
VITE_DRUPAL_BASE_URL=https://example.com

// .env.production
VITE_API_URL=https://api.production.com
VITE_ENABLE_ANALYTICS=true
```

```javascript
// utils/env.js
export const getEnvVar = (key, defaultValue = '') => {
  const value = import.meta.env[key]
  
  if (value === undefined) {
    console.warn(`Environment variable ${key} is not defined`)
    return defaultValue
  }
  
  return value
}

// Validate required env vars at app startup
export const validateEnv = () => {
  const required = [
    'VITE_API_URL',
    'VITE_DRUPAL_BASE_URL'
  ]
  
  const missing = required.filter(key => !import.meta.env[key])
  
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`)
  }
}
```

---

## Webpack Security Configuration

### ✅ SAFE: Production Webpack Config

```javascript
// webpack.config.js
const webpack = require('webpack')
const TerserPlugin = require('terser-webpack-plugin')

module.exports = (env, argv) => {
  const isDev = argv.mode === 'development'
  
  return {
    mode: isDev ? 'development' : 'production',
    
    // Disable source maps in production
    devtool: isDev ? 'eval-source-map' : false,
    
    output: {
      filename: isDev ? '[name].js' : '[name].[contenthash].js',
      chunkFilename: isDev ? '[name].chunk.js' : '[name].[contenthash].chunk.js',
      publicPath: '/themes/custom/mytheme/dist/',
      clean: true
    },
    
    optimization: {
      minimize: !isDev,
      minimizer: [
        new TerserPlugin({
          terserOptions: {
            compress: {
              drop_console: !isDev,
              drop_debugger: true,
              pure_funcs: isDev ? [] : ['console.log']
            },
            format: {
              comments: false
            }
          },
          extractComments: false
        })
      ],
      
      // Split chunks securely
      splitChunks: {
        chunks: 'all',
        cacheGroups: {
          vendor: {
            test: /[\\/]node_modules[\\/]/,
            name: 'vendor',
            priority: 10
          }
        }
      }
    },
    
    plugins: [
      new webpack.DefinePlugin({
        'process.env.NODE_ENV': JSON.stringify(argv.mode),
        __VUE_OPTIONS_API__: true,
        __VUE_PROD_DEVTOOLS__: isDev
      }),
      
      // Don't expose webpack module IDs
      new webpack.ids.HashedModuleIdsPlugin()
    ],
    
    devServer: {
      https: false, // Enable with proper certs
      headers: {
        'X-Frame-Options': 'DENY',
        'X-Content-Type-Options': 'nosniff'
      },
      allowedHosts: isDev ? 'all' : ['example.com', 'www.example.com']
    }
  }
}
```

---

## Anti-Patterns (Vulnerabilities)

### ❌ DANGEROUS: Source Maps in Production

```javascript
// VULNERABLE
export default defineConfig({
  build: {
    sourcemap: true // Exposes source code in production!
  }
})
```

### ❌ DANGEROUS: API Keys in Build

```javascript
// VULNERABLE: Hardcoded secrets
export default defineConfig({
  define: {
    API_KEY: JSON.stringify('sk_live_abc123'), // Exposed in bundle!
    SECRET_TOKEN: JSON.stringify('secret')
  }
})
```

### ❌ DANGEROUS: Development Tools in Production

```javascript
// VULNERABLE: DevTools enabled
import { createApp } from 'vue'

const app = createApp(App)

// Enables Vue DevTools in production
app.config.devtools = true // Should be false in production!
```

### ❌ DANGEROUS: Exposed Error Details

```javascript
// VULNERABLE: Detailed errors in production
app.config.errorHandler = (err, instance, info) => {
  // Exposes stack traces to users
  alert(`Error: ${err.stack}`)
}
```

---

## Drupal Theme Integration

### ✅ SAFE: Drupal libraries.yml Configuration

```yaml
# mytheme.libraries.yml
vue-app:
  version: 1.x
  js:
    dist/js/main.[hash].js: { minified: true, preprocess: false }
  css:
    theme:
      dist/css/main.[hash].css: { minified: true, preprocess: false }
  dependencies:
    - core/drupal
    - core/drupalSettings

vue-app-dev:
  version: 1.x
  js:
    dist/js/main.js: { minified: false, preprocess: false }
  css:
    theme:
      dist/css/main.css: { minified: false, preprocess: false }
```

### ✅ SAFE: Dynamic Library Loading

```php
// mytheme.theme
function mytheme_preprocess_page(&$variables) {
  $is_dev = \Drupal::config('system.performance')->get('js.preprocess') === FALSE;
  
  // Load appropriate library based on environment
  $library = $is_dev ? 'mytheme/vue-app-dev' : 'mytheme/vue-app';
  $variables['#attached']['library'][] = $library;
  
  // Pass only safe settings to JavaScript
  $variables['#attached']['drupalSettings']['mytheme'] = [
    'apiUrl' => Url::fromRoute('mytheme.api')->toString(),
    'csrfToken' => \Drupal::csrfToken()->get('rest'),
    // Never pass secrets or sensitive config
  ];
}
```

---

## Content Security Policy (CSP)

### ✅ SAFE: CSP-Compatible Build

```javascript
// vite.config.js
export default defineConfig({
  build: {
    // Generate nonce-compatible code
    cssCodeSplit: true,
    
    rollupOptions: {
      output: {
        // Ensure CSP compatibility
        inlineDynamicImports: false
      }
    }
  },
  
  // Configure for nonce-based CSP
  plugins: [
    vue({
      template: {
        compilerOptions: {
          // Add nonce to inline styles
          isCustomElement: tag => tag.includes('-')
        }
      }
    })
  ]
})
```

---

## Audit Checklist

- [ ] Source maps disabled in production builds
- [ ] Console logs removed in production
- [ ] No API keys or secrets in build config
- [ ] Environment variables properly scoped (VITE_ prefix)
- [ ] Vue DevTools disabled in production
- [ ] Minification enabled for production
- [ ] Chunk names obfuscated/hashed
- [ ] File names include content hashes
- [ ] Development dependencies not in production bundle
- [ ] Error messages don't expose stack traces
- [ ] Build artifacts in .gitignore
- [ ] Security headers configured
- [ ] CSP compatibility maintained
- [ ] No source code comments in production

---

## Security Scripts

```json
// package.json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "build:analyze": "vite build --mode analyze",
    "preview": "vite preview",
    "security:audit": "npm audit --production",
    "security:check": "node scripts/security-check.js"
  }
}
```

```javascript
// scripts/security-check.js
const fs = require('fs')
const path = require('path')

const distPath = path.resolve(__dirname, '../dist')

// Check for source maps
const hasSourceMaps = fs.existsSync(path.join(distPath, 'js')) &&
  fs.readdirSync(path.join(distPath, 'js'))
    .some(file => file.endsWith('.map'))

if (hasSourceMaps) {
  console.error('❌ Source maps found in production build!')
  process.exit(1)
}

// Check for console.log in production
const jsFiles = fs.readdirSync(path.join(distPath, 'js'))
  .filter(file => file.endsWith('.js'))

jsFiles.forEach(file => {
  const content = fs.readFileSync(path.join(distPath, 'js', file), 'utf-8')
  if (content.includes('console.log')) {
    console.warn(`⚠️  console.log found in ${file}`)
  }
})

console.log('✅ Security checks passed')
```

---

## Testing Strategy

```javascript
// tests/build-security.test.js
import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('Build Security', () => {
  it('should not include source maps in production', () => {
    const distPath = path.resolve(__dirname, '../dist')
    const files = fs.readdirSync(distPath, { recursive: true })
    
    const sourceMaps = files.filter(f => f.endsWith('.map'))
    expect(sourceMaps).toHaveLength(0)
  })
  
  it('should not expose environment variables', () => {
    const mainJs = fs.readFileSync(
      path.resolve(__dirname, '../dist/js/main.js'),
      'utf-8'
    )
    
    expect(mainJs).not.toContain('VITE_API_SECRET')
    expect(mainJs).not.toContain('process.env')
  })
})
```

---

## References

- [Vite Security](https://vitejs.dev/guide/build.html)
- [Webpack Production Best Practices](https://webpack.js.org/guides/production/)
- [OWASP Secure Configuration](https://owasp.org/www-project-top-ten/2017/A6_2017-Security_Misconfiguration)

