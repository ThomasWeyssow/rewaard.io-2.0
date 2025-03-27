import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { Recognition } from '../types';

interface CreateRecognitionParams {
  receiverId: string;
  message: string;
  points: number;
  tags: string[];
  isPrivate: boolean;
  imageUrl?: string;
}

export function useRecognitions() {
  const [recognitions, setRecognitions] = useState<Recognition[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchRecognitions();

    // Subscribe to changes
    const channel = supabase
      .channel('recognition-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'recognitions'
        },
        () => {
          fetchRecognitions();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchRecognitions = async () => {
    try {
      setError(null);
      const { data, error: fetchError } = await supabase
        .from('recognitions')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setRecognitions(data || []);
    } catch (err) {
      console.error('Error fetching recognitions:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch recognitions');
    } finally {
      setLoading(false);
    }
  };

  const createRecognition = async ({
    receiverId,
    message,
    points,
    tags,
    isPrivate,
    imageUrl
  }: CreateRecognitionParams) => {
    try {
      setError(null);

      // Get active program
      const { data: programs, error: programError } = await supabase
        .from('recognition_programs')
        .select('id')
        .gte('end_date', new Date().toISOString())
        .lte('start_date', new Date().toISOString())
        .limit(1)
        .single();

      if (programError) throw programError;
      if (!programs) throw new Error('No active recognition program found');

      // Get current user
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError) throw userError;
      if (!user) throw new Error('No authenticated user found');

      // Create recognition
      const { error: insertError } = await supabase
        .from('recognitions')
        .insert([{
          program_id: programs.id,
          sender_id: user.id,
          receiver_id: receiverId,
          message,
          points,
          tags,
          is_private: isPrivate,
          image_url: imageUrl
        }]);

      if (insertError) throw insertError;

      await fetchRecognitions();
    } catch (err) {
      console.error('Error creating recognition:', err);
      throw err;
    }
  };

  return {
    recognitions,
    loading,
    error,
    createRecognition,
    refetch: fetchRecognitions
  };
}