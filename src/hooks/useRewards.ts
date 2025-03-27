import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { Reward } from '../types';

export function useRewards() {
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchRewards();

    // Subscribe to changes
    const channel = supabase
      .channel('rewards-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'rewards'
        },
        () => {
          fetchRewards();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchRewards = async () => {
    try {
      setError(null);
      const { data, error: fetchError } = await supabase
        .from('rewards')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;

      // Map database fields to Reward type
      const formattedRewards: Reward[] = (data || []).map(reward => ({
        id: reward.id,
        name: reward.name,
        description: reward.description || '',
        pointsCost: reward.points_cost,
        image: reward.image_url
      }));

      setRewards(formattedRewards);
    } catch (err) {
      console.error('Error fetching rewards:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch rewards');
    } finally {
      setLoading(false);
    }
  };

  const createReward = async (name: string, description: string, pointsCost: number, imageUrl: string) => {
    try {
      setError(null);
      const { data, error: insertError } = await supabase
        .from('rewards')
        .insert([{ 
          name, 
          description, 
          points_cost: pointsCost, 
          image_url: imageUrl 
        }])
        .select()
        .single();

      if (insertError) throw insertError;
      return data;
    } catch (err) {
      console.error('Error creating reward:', err);
      throw err;
    }
  };

  const updateReward = async (id: string, name: string, description: string, pointsCost: number, imageUrl: string) => {
    try {
      setError(null);
      const { data, error: updateError } = await supabase
        .from('rewards')
        .update({ 
          name, 
          description, 
          points_cost: pointsCost, 
          image_url: imageUrl 
        })
        .eq('id', id)
        .select()
        .single();

      if (updateError) throw updateError;
      return data;
    } catch (err) {
      console.error('Error updating reward:', err);
      throw err;
    }
  };

  const deleteReward = async (id: string) => {
    try {
      setError(null);
      const { error: deleteError } = await supabase
        .from('rewards')
        .delete()
        .eq('id', id);

      if (deleteError) throw deleteError;
    } catch (err) {
      console.error('Error deleting reward:', err);
      throw err;
    }
  };

  const unlockReward = async (rewardId: string) => {
    try {
      setError(null);
      
      // Get current user
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      // Get reward details
      const { data: reward } = await supabase
        .from('rewards')
        .select('points_cost')
        .eq('id', rewardId)
        .single();

      if (!reward) throw new Error('Reward not found');

      // Get user's points
      const { data: userPoints } = await supabase
        .from('recognition_points')
        .select('earned_points')
        .eq('profile_id', user.id)
        .single();

      if (!userPoints || userPoints.earned_points < reward.points_cost) {
        throw new Error('Insufficient points');
      }

      // Start a transaction using RPC
      const { error: rpcError } = await supabase.rpc('unlock_reward', {
        p_user_id: user.id,
        p_reward_id: rewardId,
        p_points_cost: reward.points_cost
      });

      if (rpcError) throw rpcError;

    } catch (err) {
      console.error('Error unlocking reward:', err);
      throw err;
    }
  };

  const getUnlockedRewards = async (userId: string): Promise<Reward[]> => {
    try {
      setError(null);
      const { data, error: fetchError } = await supabase
        .from('unlocked_rewards')
        .select(`
          rewards (
            id,
            name,
            description,
            points_cost,
            image_url
          )
        `)
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;

      // Map database fields to Reward type
      return (data || []).map(ur => ({
        id: ur.rewards.id,
        name: ur.rewards.name,
        description: ur.rewards.description || '',
        pointsCost: ur.rewards.points_cost,
        image: ur.rewards.image_url
      }));
    } catch (err) {
      console.error('Error fetching unlocked rewards:', err);
      throw err;
    }
  };

  return {
    rewards,
    loading,
    error,
    createReward,
    updateReward,
    deleteReward,
    unlockReward,
    getUnlockedRewards,
    refetch: fetchRewards
  };
}