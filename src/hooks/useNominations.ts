import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

interface Nomination {
  id: string;
  voter_id: string;
  nominee_id: string;
  cycle_id: string;
  selected_areas: string[];
  justification: string;
  remarks?: string;
  created_at: string;
}

interface NominationValidation {
  id: string;
  validator_id: string;
  nominee_id: string;
  cycle_id: string;
  created_at: string;
}

export function useNominations() {
  const [nominations, setNominations] = useState<Nomination[]>([]);
  const [validations, setValidations] = useState<NominationValidation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([fetchNominations(), fetchValidations()]);
  }, []);

  const fetchNominations = async () => {
    try {
      setError(null);
      
      // Get nominations from the active cycle
      const { data, error: fetchError } = await supabase
        .from('nominations')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setNominations(data || []);
    } catch (error) {
      console.error('Error fetching nominations:', error);
      setError(error instanceof Error ? error.message : 'Failed to fetch nominations');
    } finally {
      setLoading(false);
    }
  };

  const fetchValidations = async () => {
    try {
      setError(null);
      
      // Get validations from the active cycle
      const { data, error: fetchError } = await supabase
        .from('nomination_validations')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setValidations(data || []);
    } catch (error) {
      console.error('Error fetching validations:', error);
      setError(error instanceof Error ? error.message : 'Failed to fetch validations');
    }
  };

  const createNomination = async (
    voterId: string,
    nomineeId: string,
    selectedAreas: string[],
    justification: string,
    remarks?: string
  ) => {
    try {
      setError(null);

      // Get current settings to get cycle_id
      const { data: settings, error: settingsError } = await supabase
        .from('settings')
        .select('ongoing_cycle_id')
        .single();

      if (settingsError) throw settingsError;
      if (!settings.ongoing_cycle_id) throw new Error('No active nomination cycle');

      // Create new nomination
      const { data, error: insertError } = await supabase
        .from('nominations')
        .insert([{
          voter_id: voterId,
          nominee_id: nomineeId,
          cycle_id: settings.ongoing_cycle_id,
          selected_areas: selectedAreas,
          justification,
          remarks
        }])
        .select()
        .single();

      if (insertError) throw insertError;

      // Update local state
      setNominations(prev => [...prev, data]);

      return data;
    } catch (error) {
      console.error('Error creating nomination:', error);
      const errorMessage = error instanceof Error ? error.message : 'Failed to create nomination';
      setError(errorMessage);
      throw new Error(errorMessage);
    }
  };

  const deleteNomination = async (voterId: string) => {
    try {
      setError(null);

      const { error: deleteError } = await supabase
        .from('nominations')
        .delete()
        .eq('voter_id', voterId);

      if (deleteError) throw deleteError;

      // Update local state
      setNominations(prev => prev.filter(n => n.voter_id !== voterId));
    } catch (error) {
      console.error('Error deleting nomination:', error);
      const errorMessage = error instanceof Error ? error.message : 'Failed to delete nomination';
      setError(errorMessage);
      throw new Error(errorMessage);
    }
  };

  const validateNomination = async (validatorId: string, nomineeId: string) => {
    try {
      setError(null);

      // Get current settings to get cycle_id
      const { data: settings, error: settingsError } = await supabase
        .from('settings')
        .select('ongoing_cycle_id')
        .single();

      if (settingsError) throw settingsError;
      if (!settings.ongoing_cycle_id) throw new Error('No active nomination cycle');

      // Check if the user has already validated for this nominee
      const existingValidation = validations.find(
        v => v.validator_id === validatorId && v.nominee_id === nomineeId
      );

      if (existingValidation) {
        // If clicking on the same nominee, remove the validation
        const { error: deleteError } = await supabase
          .from('nomination_validations')
          .delete()
          .eq('validator_id', validatorId)
          .eq('nominee_id', nomineeId);

        if (deleteError) throw deleteError;

        // Update local state
        setValidations(prev => prev.filter(v => 
          !(v.validator_id === validatorId && v.nominee_id === nomineeId)
        ));
      } else {
        // First, remove any existing validation for this validator
        const { error: deleteError } = await supabase
          .from('nomination_validations')
          .delete()
          .eq('validator_id', validatorId);

        if (deleteError) throw deleteError;

        // Then create new validation
        const { data, error: insertError } = await supabase
          .from('nomination_validations')
          .insert([{
            validator_id: validatorId,
            nominee_id: nomineeId,
            cycle_id: settings.ongoing_cycle_id
          }])
          .select()
          .single();

        if (insertError) throw insertError;

        // Update local state
        setValidations(prev => [
          ...prev.filter(v => v.validator_id !== validatorId),
          data
        ]);
      }
    } catch (error) {
      console.error('Error validating nomination:', error);
      const errorMessage = error instanceof Error ? error.message : 'Failed to validate nomination';
      setError(errorMessage);
      throw new Error(errorMessage);
    }
  };

  const getValidationsCount = (nomineeId: string): number => {
    return validations.filter(v => v.nominee_id === nomineeId).length;
  };

  const hasValidated = (validatorId: string): string | null => {
    const validation = validations.find(v => v.validator_id === validatorId);
    return validation ? validation.nominee_id : null;
  };

  return {
    nominations,
    loading,
    error,
    createNomination,
    deleteNomination,
    validateNomination,
    getValidationsCount,
    hasValidated,
    refetch: fetchNominations
  };
}