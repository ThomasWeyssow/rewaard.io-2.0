import { useState, useEffect } from 'react';
import { supabase, handleSupabaseError } from '../lib/supabase';

interface Vote {
  id: string;
  voter_id: string;
  nominee_id: string;
  nomination_cycle_start: string;
  nomination_cycle_end: string;
  selected_areas: string[];
  justification: string;
  remarks?: string;
  created_at: string;
}

export function useVotes() {
  const [votes, setVotes] = useState<Vote[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchVotes();

    // Subscribe to real-time changes
    const channel = supabase
      .channel('nominations-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'nominations'
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setVotes(prev => [...prev, payload.new as Vote]);
          } else if (payload.eventType === 'DELETE') {
            setVotes(prev => prev.filter(vote => vote.id !== payload.old.id));
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchVotes = async () => {
    try {
      setError(null);
      const { data, error: fetchError } = await supabase
        .from('nominations')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setVotes(data || []);
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError.message);
    } finally {
      setLoading(false);
    }
  };

  const getCurrentVote = (voterId: string, cycleStart: string, cycleEnd: string): Vote | undefined => {
    // Assurez-vous que les dates sont au même format pour la comparaison
    const formattedCycleStart = new Date(cycleStart).toISOString().split('T')[0];
    const formattedCycleEnd = new Date(cycleEnd).toISOString().split('T')[0];

    return votes.find(vote => 
      vote.voter_id === voterId && 
      new Date(vote.nomination_cycle_start).toISOString().split('T')[0] === formattedCycleStart &&
      new Date(vote.nomination_cycle_end).toISOString().split('T')[0] === formattedCycleEnd
    );
  };

  const createVote = async (
    voterId: string,
    votedForId: string,
    cycleStart: string,
    cycleEnd: string,
    selectedAreas: string[],
    justification: string,
    remarks?: string
  ) => {
    try {
      setError(null);
      const { data, error: insertError } = await supabase
        .from('nominations')
        .insert([{
          voter_id: voterId,
          nominee_id: votedForId,
          nomination_cycle_start: cycleStart,
          nomination_cycle_end: cycleEnd,
          selected_areas: selectedAreas,
          justification,
          remarks
        }])
        .select()
        .single();

      if (insertError) throw insertError;
      return data;
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError.message);
      throw formattedError;
    }
  };

  const deleteVote = async (voterId: string, cycleStart: string, cycleEnd: string) => {
    try {
      setError(null);
      const { error: deleteError } = await supabase
        .from('nominations')
        .delete()
        .match({
          voter_id: voterId,
          nomination_cycle_start: cycleStart,
          nomination_cycle_end: cycleEnd
        });

      if (deleteError) throw deleteError;
    } catch (error) {
      const formattedError = handleSupabaseError(error);
      setError(formattedError.message);
      throw formattedError;
    }
  };

  return {
    votes,
    loading,
    error,
    createVote,
    deleteVote,
    getCurrentVote,
    refetch: fetchVotes
  };
}