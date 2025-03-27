import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [react()],
  optimizeDeps: {
    exclude: ['lucide-react'],
  },
  // Chargement des variables d'environnement selon le mode
  envDir: '.',
  // Définir les fichiers .env à utiliser
  envPrefix: 'VITE_',
  // Mode development : .env.development
  // Mode production : .env.production
  mode: mode === 'production' ? 'production' : 'development'
}));