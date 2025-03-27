import { useEffect, useState } from 'react';
import { supabase, handleSupabaseError } from '../lib/supabase';
import type { Employee } from '../types';

interface Winner {
  cycle_id: string;
  nominee_id: string;
  created_at: string;
}

export function useProfiles() {
  const [profiles, setProfiles] = useState<Employee[]>([]);
  const [winners, setWinners] = useState<Winner[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let mounted = true;

    const initializeProfiles = async () => {
      try {
        setError(null);

        // Initial fetch
        await Promise.all([fetchProfiles(), fetchWinners()]);

        // Subscribe to realtime changes
        const profilesSubscription = supabase
          .channel('profiles-changes')
          .on(
            'postgres_changes',
            { event: '*', schema: 'public', table: 'profiles' },
            () => {
              if (mounted) {
                fetchProfiles();
              }
            }
          )
          .subscribe();

        // Subscribe to winners changes
        const winnersSubscription = supabase
          .channel('winners-changes')
          .on(
            'postgres_changes',
            { event: '*', schema: 'public', table: 'cycle_winner' },
            () => {
              if (mounted) {
                fetchWinners();
              }
            }
          )
          .subscribe();

        // Cleanup
        return () => {
          mounted = false;
          profilesSubscription.unsubscribe();
          winnersSubscription.unsubscribe();
        };
      } catch (err) {
        const formattedError = handleSupabaseError(err);
        if (mounted) {
          setError(formattedError);
          setProfiles([]);
          setWinners([]);
        }
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    };

    initializeProfiles();
  }, []);

  const fetchProfiles = async () => {
    try {
      setError(null);
      const { data, error: fetchError } = await supabase
        .from('profiles')
        .select(`
          *,
          profile_badges (
            badges (
              id,
              name,
              icon,
              description,
              color
            )
          ),
          profile_roles (
            roles (
              id,
              name,
              created_at
            )
          ),
          clients (
            id,
            name
          ),
          recognition_points (
            distributable_points,
            earned_points
          )
        `);

      if (fetchError) throw fetchError;
      if (!data) throw new Error('No data received');

      const formattedProfiles: Employee[] = data.map(profile => ({
        id: profile.id,
        first_name: profile.first_name,
        last_name: profile.last_name,
        name: `${profile.first_name} ${profile.last_name}`.trim(),
        email: profile.email,
        points: profile.points || 0,
        department: profile.department,
        avatar: profile.avatar_url,
        client_id: profile.client_id,
        badges: profile.profile_badges
          ?.map((pb: any) => pb.badges)
          .filter(Boolean) || [],
        roles: profile.profile_roles
          ?.map((pr: any) => pr.roles)
          .filter(Boolean) || [],
        recognition_points: profile.recognition_points?.[0] || null
      }));

      setProfiles(formattedProfiles);
      return formattedProfiles;
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      return [];
    }
  };

  const fetchWinners = async () => {
    try {
      setError(null);
      const { data, error: fetchError } = await supabase
        .from('cycle_winner')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setWinners(data || []);
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      setWinners([]);
    }
  };

  const updatePoints = async (id: string, points: number) => {
    try {
      setError(null);
      
      setProfiles(prevProfiles => 
        prevProfiles.map(profile => 
          profile.id === id 
            ? { ...profile, points } 
            : profile
        )
      );

      const { error: updateError } = await supabase
        .from('profiles')
        .update({ points })
        .eq('id', id);

      if (updateError) {
        await fetchProfiles();
        throw updateError;
      }
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      throw formattedError;
    }
  };

  const updateAvatar = async (userId: string, avatarUrl: string) => {
    try {
      setError(null);

      const { error: updateError } = await supabase
        .from('profiles')
        .update({ avatar_url: avatarUrl })
        .eq('id', userId);

      if (updateError) throw updateError;

      setProfiles(prevProfiles => 
        prevProfiles.map(profile => 
          profile.id === userId 
            ? { ...profile, avatar: avatarUrl } 
            : profile
        )
      );
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      throw formattedError;
    }
  };

  const addRole = async (userId: string, roleName: 'ExCom' | 'Admin') => {
    try {
      setError(null);

      const { data: roleData, error: roleError } = await supabase
        .from('roles')
        .select('id')
        .eq('name', roleName)
        .single();

      if (roleError) throw roleError;

      const { error: insertError } = await supabase
        .from('profile_roles')
        .insert([{ profile_id: userId, role_id: roleData.id }]);

      if (insertError) throw insertError;

      await fetchProfiles();
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      throw formattedError;
    }
  };

  const removeRole = async (userId: string, roleName: 'ExCom' | 'Admin') => {
    try {
      setError(null);

      const { data: roleData, error: roleError } = await supabase
        .from('roles')
        .select('id')
        .eq('name', roleName)
        .single();

      if (roleError) throw roleError;

      const { error: deleteError } = await supabase
        .from('profile_roles')
        .delete()
        .eq('profile_id', userId)
        .eq('role_id', roleData.id);

      if (deleteError) throw deleteError;

      await fetchProfiles();
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      throw formattedError;
    }
  };

  const addBadge = async (profileId: string, badgeId: string) => {
    try {
      setError(null);
      
      const { error: insertError } = await supabase
        .from('profile_badges')
        .insert([{ profile_id: profileId, badge_id: badgeId }]);

      if (insertError) throw insertError;

      await fetchProfiles();
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      throw formattedError;
    }
  };

  const removeBadge = async (profileId: string, badgeId: string) => {
    try {
      setError(null);
      
      const { error: deleteError } = await supabase
        .from('profile_badges')
        .delete()
        .eq('profile_id', profileId)
        .eq('badge_id', badgeId);

      if (deleteError) throw deleteError;

      await fetchProfiles();
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError);
      throw formattedError;
    }
  };

  return {
    profiles,
    winners,
    loading,
    error,
    updatePoints,
    updateAvatar,
    addBadge,
    removeBadge,
    addRole,
    removeRole,
    fetchProfiles,
    refetch: fetchProfiles
  };
}