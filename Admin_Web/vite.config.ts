import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'https://apialbareq.al-earth.ly',
        changeOrigin: true,
      },
      '/uploads': {
        target: 'https://apialbareq.al-earth.ly',
        changeOrigin: true,
      },
      '/hubs': {
        target: 'https://apialbareq.al-earth.ly',
        changeOrigin: true,
        ws: true,
      },
    },
  },
})
