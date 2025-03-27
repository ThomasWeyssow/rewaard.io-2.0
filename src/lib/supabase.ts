import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Les variables d\'environnement Supabase sont manquantes. Veuillez cliquer sur le bouton "Connect to Supabase" en haut à droite.');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true
  },
  realtime: {
    params: {
      eventsPerSecond: 1
    }
  },
  global: {
    headers: { 'x-client-info': 'rewaard' }
  },
  // Ajout des options de retry pour gérer les erreurs de connexion
  db: {
    schema: 'public'
  },
  // Augmenter le timeout pour les requêtes
  timeout: 20000
});

// Fonction utilitaire pour gérer les erreurs Supabase avec retry
export const handleSupabaseError = async (error: unknown, retries = 3): Promise<Error> => {
  if (error instanceof Error) {
    // Erreurs de connexion
    if (error.message.includes('Failed to fetch')) {
      if (retries > 0) {
        // Attendre avant de réessayer
        await new Promise(resolve => setTimeout(resolve, 1000));
        try {
          // Tester la connexion
          await supabase.from('profiles').select('count').limit(1);
          return new Error('La connexion a été rétablie');
        } catch (retryError) {
          return handleSupabaseError(retryError, retries - 1);
        }
      }
      return new Error('La connexion à Supabase a échoué. Veuillez vérifier votre connexion internet et réessayer.');
    }
    // Autres types d'erreurs...
    return error;
  }
  return new Error('Une erreur inattendue est survenue. Veuillez réessayer.');
};

// Fonction pour vérifier la connexion à Supabase avec retry
export const checkSupabaseConnection = async (retries = 3, delay = 1000): Promise<boolean> => {
  for (let i = 0; i < retries; i++) {
    try {
      const { data, error } = await supabase.from('profiles').select('count').limit(1);
      if (error) throw error;
      return true;
    } catch (error) {
      console.error(`Tentative de connexion ${i + 1}/${retries} échouée:`, error);
      if (i < retries - 1) {
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
  return false;
};