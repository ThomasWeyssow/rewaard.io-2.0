import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

export interface Settings {
  id: string;
  next_nomination_period: 'monthly' | 'bi-monthly' | null;
  ongoing_nomination_period: 'monthly' | 'bi-monthly' | null;
  next_nomination_area_id: string | null;
  next_nomination_start_date: string;
  next_nomination_end_date: string;
  ongoing_nomination_area_id: string | null;
  ongoing_nomination_start_date: string | null;
  ongoing_nomination_end_date: string | null;
  hero_banner_url: string;
  logo_url: string | null;
  favicon_url: string | null;
}

export interface Incentive {
  id: string;
  title: string;
  description: string;
  icon: string;
}

export interface Area {
  id: string;
  title: string;
  description: string;
}

export interface NominationArea {
  id: string;
  category: string;
  areas: Area[];
  icon: string;
}

export function useSettings() {
  const [settings, setSettings] = useState<Settings | null>(null);
  const [incentives, setIncentives] = useState<Incentive[]>([]);
  const [nominationAreas, setNominationAreas] = useState<NominationArea[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([fetchSettings(), fetchIncentives(), fetchNominationAreas()]).finally(() => {
      setLoading(false);
    });
  }, []);

  const fetchSettings = async () => {
    try {
      const { data, error } = await supabase
        .from('settings')
        .select('*')
        .single();

      if (error) throw error;
      setSettings(data);
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to fetch settings';
      console.error('Error fetching settings:', formattedError);
    }
  };

  const fetchIncentives = async () => {
    try {
      const { data, error } = await supabase
        .from('incentives')
        .select('*')
        .order('created_at', { ascending: true });

      if (error) throw error;
      setIncentives(data || []);
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to fetch incentives';
      console.error('Error fetching incentives:', formattedError);
    }
  };

  const fetchNominationAreas = async () => {
    try {
      const { data, error } = await supabase
        .from('nomination_areas')
        .select('*')
        .order('created_at', { ascending: true });

      if (error) throw error;
      setNominationAreas(data || []);
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to fetch nomination areas';
      console.error('Error fetching nomination areas:', formattedError);
    }
  };

  const updateHeroBanner = async (url: string) => {
    try {
      const { error } = await supabase
        .from('settings')
        .update({ hero_banner_url: url })
        .eq('id', settings?.id);

      if (error) throw error;
      
      // Update local state
      if (settings) {
        setSettings({
          ...settings,
          hero_banner_url: url
        });
      }
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to update hero banner';
      throw formattedError;
    }
  };

  const updateLogoUrl = async (url: string) => {
    try {
      const { error } = await supabase
        .from('settings')
        .update({ logo_url: url })
        .eq('id', settings?.id);

      if (error) throw error;
      
      // Update local state
      if (settings) {
        setSettings({
          ...settings,
          logo_url: url
        });
      }
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to update logo';
      throw formattedError;
    }
  };

  const updateFaviconUrl = async (url: string) => {
    try {
      const { error } = await supabase
        .from('settings')
        .update({ favicon_url: url })
        .eq('id', settings?.id);

      if (error) throw error;
      
      // Update local state
      if (settings) {
        setSettings({
          ...settings,
          favicon_url: url
        });
      }

      // Update favicon in the document
      const link = document.querySelector("link[rel*='icon']") || document.createElement('link');
      link.type = 'image/x-icon';
      link.rel = 'shortcut icon';
      link.href = url;
      document.getElementsByTagName('head')[0].appendChild(link);
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to update favicon';
      throw formattedError;
    }
  };

  const addIncentive = async (title: string, description: string, icon: string) => {
    try {
      const { data, error } = await supabase
        .from('incentives')
        .insert([{ title, description, icon }])
        .select()
        .single();

      if (error) throw error;
      setIncentives(prev => [...prev, data]);
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to add incentive';
      throw formattedError;
    }
  };

  const updateIncentive = async (id: string, title: string, description: string, icon: string) => {
    try {
      const { data, error } = await supabase
        .from('incentives')
        .update({ title, description, icon })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      setIncentives(prev => prev.map(i => i.id === id ? data : i));
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to update incentive';
      throw formattedError;
    }
  };

  const deleteIncentive = async (id: string) => {
    try {
      const { error } = await supabase
        .from('incentives')
        .delete()
        .eq('id', id);

      if (error) throw error;
      setIncentives(prev => prev.filter(i => i.id !== id));
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to delete incentive';
      throw formattedError;
    }
  };

  const addNominationArea = async (category: string, areas: Area[], icon: string) => {
    try {
      const { data, error } = await supabase
        .from('nomination_areas')
        .insert([{ category, areas, icon }])
        .select()
        .single();

      if (error) throw error;
      setNominationAreas(prev => [...prev, data]);
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to add nomination area';
      throw formattedError;
    }
  };

  const updateNominationArea = async (id: string, category: string, areas: Area[], icon: string) => {
    try {
      const { data, error } = await supabase
        .from('nomination_areas')
        .update({ category, areas, icon })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      setNominationAreas(prev => prev.map(a => a.id === id ? data : a));
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to update nomination area';
      throw formattedError;
    }
  };

  const deleteNominationArea = async (id: string) => {
    try {
      const { error } = await supabase
        .from('nomination_areas')
        .delete()
        .eq('id', id);

      if (error) throw error;
      setNominationAreas(prev => prev.filter(a => a.id !== id));
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to delete nomination area';
      throw formattedError;
    }
  };

  const selectNextNominationArea = async (
    areaId: string, 
    startDate: string,
    nominationPeriod: 'monthly' | 'bi-monthly'
  ) => {
    try {
      if (!settings?.id) {
        const { error: insertError } = await supabase
          .from('settings')
          .insert([{
            next_nomination_period: nominationPeriod,
            next_nomination_area_id: areaId,
            next_nomination_start_date: startDate
          }]);

        if (insertError) throw insertError;
      } else {
        const { error: updateError } = await supabase
          .from('settings')
          .update({
            next_nomination_period: nominationPeriod,
            next_nomination_area_id: areaId,
            next_nomination_start_date: startDate
          })
          .eq('id', settings.id);

        if (updateError) throw updateError;
      }

      await fetchSettings();
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to select next nomination area';
      throw formattedError;
    }
  };

  const deleteOngoingNominationCycle = async () => {
    try {
      if (!settings?.id) return;

      const { error: updateError } = await supabase
        .from('settings')
        .update({
          ongoing_nomination_area_id: null,
          ongoing_nomination_start_date: null,
          ongoing_nomination_end_date: null,
          ongoing_nomination_period: null
        })
        .eq('id', settings.id);

      if (updateError) throw updateError;
      await fetchSettings();
    } catch (error) {
      const formattedError = error instanceof Error ? error.message : 'Failed to delete ongoing nomination cycle';
      throw formattedError;
    }
  };

  const getNextNominationDate = (): string => {
    if (!settings?.next_nomination_start_date) return new Date().toISOString();
    return settings.next_nomination_start_date;
  };

  const getNominationCycleDates = () => {
    if (!settings) return { start: '', end: '' };
    
    return {
      start: settings.next_nomination_start_date,
      end: settings.next_nomination_end_date
    };
  };

  const getOngoingCycleDates = () => {
    if (!settings?.ongoing_nomination_start_date) return null;
    
    return {
      start: settings.ongoing_nomination_start_date,
      end: settings.ongoing_nomination_end_date
    };
  };

  const getOngoingArea = (): NominationArea | null => {
    if (!settings?.ongoing_nomination_area_id) return null;
    return nominationAreas.find(area => area.id === settings.ongoing_nomination_area_id) || null;
  };

  return {
    settings,
    incentives,
    nominationAreas,
    loading,
    error,
    selectNextNominationArea,
    deleteOngoingNominationCycle,
    getNextNominationDate,
    getNominationCycleDates,
    getOngoingCycleDates,
    getOngoingArea,
    addIncentive,
    updateIncentive,
    deleteIncentive,
    addNominationArea,
    updateNominationArea,
    deleteNominationArea,
    updateHeroBanner,
    updateLogoUrl,
    updateFaviconUrl
  };
}