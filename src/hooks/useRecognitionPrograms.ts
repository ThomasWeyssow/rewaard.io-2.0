import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { RecognitionProgram } from '../types';

interface CreateProgramParams {
  name: string;
  startDate: string;
  endDate: string;
  pointsPerUser: number;
}

export function useRecognitionPrograms() {
  const [programs, setPrograms] = useState<RecognitionProgram[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchPrograms();

    // Subscribe to changes
    const channel = supabase
      .channel('program-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'recognition_programs'
        },
        () => {
          fetchPrograms();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchPrograms = async () => {
    try {
      setError(null);
      const { data, error: fetchError } = await supabase
        .from('recognition_programs')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setPrograms(data || []);
    } catch (err) {
      console.error('Error fetching programs:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch programs');
    } finally {
      setLoading(false);
    }
  };

  const createProgram = async ({
    name,
    startDate,
    endDate,
    pointsPerUser
  }: CreateProgramParams) => {
    try {
      setError(null);

      // Check for overlapping programs
      const { data: existing, error: checkError } = await supabase
        .from('recognition_programs')
        .select('id')
        .or(`start_date.lte.${endDate},end_date.gte.${startDate}`);

      if (checkError) throw checkError;
      if (existing && existing.length > 0) {
        throw new Error('A recognition program already exists during this period');
      }

      // Create program
      const { error: insertError } = await supabase
        .from('recognition_programs')
        .insert([{
          name,
          start_date: startDate,
          end_date: endDate,
          points_per_user: pointsPerUser
        }]);

      if (insertError) throw insertError;

      await fetchPrograms();
    } catch (err) {
      console.error('Error creating program:', err);
      throw err;
    }
  };

  return {
    programs,
    loading,
    error,
    createProgram,
    refetch: fetchPrograms
  };
}