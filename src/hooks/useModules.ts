import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

interface Module {
  id: string;
  name: string;
  description: string;
  pages: string[];
}

export function useModules() {
  const [modules, setModules] = useState<Module[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadModules();
  }, []);

  const loadModules = async () => {
    try {
      setError(null);
      const { data: modulesData, error: modulesError } = await supabase
        .from('modules')
        .select(`
          id,
          name,
          description,
          module_pages (
            page_name
          )
        `);

      if (modulesError) throw modulesError;

      const formattedModules: Module[] = modulesData?.map(module => ({
        id: module.id,
        name: module.name,
        description: module.description,
        pages: module.module_pages.map((mp: { page_name: string }) => mp.page_name)
      })) || [];

      setModules(formattedModules);
    } catch (err) {
      console.error('Error loading modules:', err);
      setError(err instanceof Error ? err.message : 'Failed to load modules');
    } finally {
      setLoading(false);
    }
  };

  const updateModule = async (moduleId: string, name: string, description: string) => {
    try {
      setError(null);
      const { error: updateError } = await supabase
        .from('modules')
        .update({ name, description })
        .eq('id', moduleId);

      if (updateError) throw updateError;

      setModules(prev => prev.map(module => 
        module.id === moduleId 
          ? { ...module, name, description }
          : module
      ));
    } catch (err) {
      console.error('Error updating module:', err);
      setError(err instanceof Error ? err.message : 'Failed to update module');
      throw err;
    }
  };

  const movePage = async (pageName: string, fromModuleId: string, toModuleId: string) => {
    try {
      setError(null);

      // Optimistic update
      setModules(prev => prev.map(module => {
        if (module.id === fromModuleId) {
          return { ...module, pages: module.pages.filter(p => p !== pageName) };
        }
        if (module.id === toModuleId) {
          return { ...module, pages: [...module.pages, pageName] };
        }
        return module;
      }));

      // Delete from old module
      const { error: deleteError } = await supabase
        .from('module_pages')
        .delete()
        .eq('module_id', fromModuleId)
        .eq('page_name', pageName);

      if (deleteError) throw deleteError;

      // Add to new module
      const { error: insertError } = await supabase
        .from('module_pages')
        .insert({ module_id: toModuleId, page_name: pageName });

      if (insertError) throw insertError;
    } catch (err) {
      console.error('Error moving page:', err);
      setError(err instanceof Error ? err.message : 'Failed to move page');
      // Revert optimistic update on error
      await loadModules();
      throw err;
    }
  };

  return {
    modules,
    loading,
    error,
    updateModule,
    movePage,
    refresh: loadModules
  };
}