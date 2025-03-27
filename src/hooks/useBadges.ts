import { useState } from 'react';
import { supabase, handleSupabaseError } from '../lib/supabase';
import type { Badge } from '../types';

export function useBadges() {
  const [error, setError] = useState<Error | null>(null);

  const addBadge = async (profileId: string, badgeId: string): Promise<Badge> => {
    try {
      setError(null);

      // Vérification si le badge existe déjà
      const { data: existingBadge, error: checkError } = await supabase
        .from('profile_badges')
        .select('*')
        .eq('profile_id', profileId)
        .eq('badge_id', badgeId)
        .maybeSingle();

      if (checkError) throw checkError;
      if (existingBadge) throw new Error('Ce badge est déjà attribué à cet employé');

      // Récupérer les informations du badge
      const { data: badgeData, error: badgeError } = await supabase
        .from('badges')
        .select('*')
        .eq('id', badgeId)
        .single();

      if (badgeError) throw badgeError;

      // Ajout du badge en base de données
      const { error } = await supabase
        .from('profile_badges')
        .insert([{ profile_id: profileId, badge_id: badgeId }]);

      if (error) throw error;

      return {
        id: badgeData.id,
        name: badgeData.name,
        icon: badgeData.icon,
        description: badgeData.description,
        color: badgeData.color
      };
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      throw formattedError;
    }
  };

  const removeBadge = async (profileId: string, badgeId: string): Promise<void> => {
    try {
      setError(null);

      const { error } = await supabase
        .from('profile_badges')
        .delete()
        .eq('profile_id', profileId)
        .eq('badge_id', badgeId);

      if (error) throw error;
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      throw formattedError;
    }
  };

  return {
    error,
    addBadge,
    removeBadge
  };
}