import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import RubyPlugin from 'vite-plugin-ruby'

// vite-plugin-ruby sets root to app/frontend, so a cache under the project-level
// node_modules becomes /@fs/C:/... URLs that Chromium/Brave fail to load.
const projectRoot = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  plugins: [
    react(),
    RubyPlugin(),
  ],
  // Keep the dep cache inside the Vite root (app/frontend) to avoid Windows @fs URLs.
  cacheDir: path.join(projectRoot, 'app/frontend/.vite'),
  // Bind IPv4 explicitly so Windows launchers/probes using 127.0.0.1 succeed
  // (default localhost can be IPv6-only [::1]).
  // HMR must target the Vite port directly when skipProxy is enabled.
  server: {
    host: '127.0.0.1',
    fs: {
      allow: [projectRoot],
    },
    hmr: {
      host: '127.0.0.1',
      port: 3036,
      clientPort: 3036,
    },
  },
  optimizeDeps: {
    // Force common deps into the in-root cache so browsers don't request @fs/C: paths.
    include: [
      'react',
      'react-dom',
      'react-dom/client',
      'react/jsx-dev-runtime',
      'react-router-dom',
    ],
  },
  resolve: {
    alias: {
      '@': path.join(projectRoot, 'app/frontend'),
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['test/setup.ts'],
    include: ['**/*.test.{ts,tsx}'],
  },
})
