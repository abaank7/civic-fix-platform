import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true, // If 5173 is busy, Vite will throw an error instead of secretly changing ports
    host: true, // Allows the server to listen on all local IPs (useful if you ever test this site on your mobile phone via WiFi)
  },
})