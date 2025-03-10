/// <reference types="vitest" />
import path from 'path';
import react from '@vitejs/plugin-react';
import { TanStackRouterVite } from '@tanstack/router-plugin/vite';
import { defineConfig } from 'vite';

export default defineConfig({
    plugins: [react(), TanStackRouterVite()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src')
        }
    },
    test: {},
    build: {
        sourcemap: true
    },
    server: {
        fs: {
            strict: false
        }
    },
    optimizeDeps: {
        esbuildOptions: {
            target: 'esnext'
        }
    }
});
