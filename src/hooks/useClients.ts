import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { Client } from '../types';

export function useClients() {
  const [clients, setClients] = useState<Client[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchClients();
  }, []);

  const fetchClients = async () => {
    try {
      setError(null);
      const { data, error: fetchError } = await supabase
        .from('clients')
        .select('*')
        .order('name');

      if (fetchError) throw fetchError;
      setClients(data || []);
    } catch (err) {
      console.error('Error fetching clients:', err);
      setError(err instanceof Error ? err.message : 'Failed to load clients');
    } finally {
      setLoading(false);
    }
  };

  const addClient = async (name: string, userIds: string[] = []) => {
    try {
      setError(null);
      
      // Create the client first
      const { data: client, error: insertError } = await supabase
        .from('clients')
        .insert([{ name }])
        .select()
        .single();

      if (insertError) throw insertError;

      // Update profiles with the new client_id
      if (userIds.length > 0) {
        const { error: updateError } = await supabase
          .from('profiles')
          .update({ client_id: client.id })
          .in('id', userIds);

        if (updateError) {
          // If profile update fails, delete the client to maintain consistency
          await supabase.from('clients').delete().eq('id', client.id);
          throw updateError;
        }
      }

      setClients(prev => [...prev, client]);
      return client;
    } catch (err) {
      console.error('Error adding client:', err);
      setError(err instanceof Error ? err.message : 'Failed to add client');
      throw err;
    }
  };

  const updateClient = async (id: string, name: string, userIds: string[] = []) => {
    try {
      setError(null);

      // First, update the client name
      const { data: client, error: updateError } = await supabase
        .from('clients')
        .update({ name })
        .eq('id', id)
        .select()
        .single();

      if (updateError) throw updateError;

      // Get current users for this client
      const { data: currentUsers } = await supabase
        .from('profiles')
        .select('id, client_id')
        .eq('client_id', id);

      const currentUserIds = currentUsers?.map(u => u.id) || [];

      // Find users to remove and add
      const usersToRemove = currentUserIds.filter(uid => !userIds.includes(uid));
      const usersToAdd = userIds.filter(uid => !currentUserIds.includes(uid));

      // Remove users from current client by setting client_id to null
      if (usersToRemove.length > 0) {
        const { error: removeError } = await supabase
          .from('profiles')
          .update({ client_id: null })
          .in('id', usersToRemove);

        if (removeError) throw removeError;
      }

      // Add new users to this client
      if (usersToAdd.length > 0) {
        const { error: addError } = await supabase
          .from('profiles')
          .update({ client_id: id })
          .in('id', usersToAdd);

        if (addError) throw addError;
      }

      setClients(prev => prev.map(c => 
        c.id === id ? client : c
      ));
      return client;
    } catch (err) {
      console.error('Error updating client:', err);
      setError(err instanceof Error ? err.message : 'Failed to update client');
      throw err;
    }
  };

  const deleteClient = async (id: string) => {
    try {
      setError(null);

      // Set client_id to null for all associated users
      const { error: updateError } = await supabase
        .from('profiles')
        .update({ client_id: null })
        .eq('client_id', id);

      if (updateError) throw updateError;

      // Delete the client
      const { error: deleteError } = await supabase
        .from('clients')
        .delete()
        .eq('id', id);

      if (deleteError) throw deleteError;

      setClients(prev => prev.filter(client => client.id !== id));
    } catch (err) {
      console.error('Error deleting client:', err);
      setError(err instanceof Error ? err.message : 'Failed to delete client');
      throw err;
    }
  };

  return {
    clients,
    loading,
    error,
    addClient,
    updateClient,
    deleteClient,
    refetch: fetchClients
  };
}