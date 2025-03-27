import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

// Liste des pages disponibles dans l'application
export const AVAILABLE_PAGES = [
  'hero-program',
  'employees',
  'rewards',
  'voting',
  'review',
  'history',
  'users',
  'settings'
] as const;

export type PageName = typeof AVAILABLE_PAGES[number];

export function usePages() {
  const [enabledPages, setEnabledPages] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadPageSettings();
  }, []);

  const loadPageSettings = async () => {
    try {
      const { data, error } = await supabase
        .from('page_settings')
        .select('*');

      if (error) throw error;

      const enabled = new Set(
        data?.filter(page => page.is_enabled).map(page => page.page_name)
      );
      setEnabledPages(enabled);
    } catch (err) {
      console.error('Error loading page settings:', err);
      setError(err instanceof Error ? err.message : 'Failed to load page settings');
    } finally {
      setLoading(false);
    }
  };

  const togglePage = async (pageName: PageName, enabled: boolean) => {
    try {
      setError(null);

      const { error: upsertError } = await supabase
        .from('page_settings')
        .upsert(
          {
            page_name: pageName,
            is_enabled: enabled
          },
          {
            onConflict: 'page_name'
          }
        );

      if (upsertError) throw upsertError;

      setEnabledPages(prev => {
        const next = new Set(prev);
        if (enabled) {
          next.add(pageName);
        } else {
          next.delete(pageName);
        }
        return next;
      });
    } catch (err) {
      console.error('Error toggling page:', err);
      setError(err instanceof Error ? err.message : 'Failed to update page settings');
      await loadPageSettings();
    }
  };

  const isPageEnabled = (pageName: string): boolean => {
    return enabledPages.has(pageName);
  };

  return {
    enabledPages,
    loading,
    error,
    togglePage,
    isPageEnabled,
    refresh: loadPageSettings
  };
}