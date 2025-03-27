import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

interface NominationHistory {
  id: string;
  cycle_id: string;
  voter_id: string;
  nominee_id: string;
  selected_areas: string[];
  justification: string;
  remarks?: string;
  nomination_area_id: string;
  created_at: string;
}

interface NominationValidation {
  id: string;
  validator_id: string;
  nominee_id: string;
  cycle_id: string;
  created_at: string;
}

export function useNominationHistory() {
  const [nominations, setNominations] = useState<NominationHistory[]>([]);
  const [validations, setValidations] = useState<NominationValidation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [latestCycleId, setLatestCycleId] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([fetchNominations(), fetchValidations()]);
  }, []);

  const fetchNominations = async () => {
    try {
      setError(null);
      
      // Get the latest completed cycle
      const { data: latestCycle, error: cycleError } = await supabase
        .from('nomination_cycles')
        .select('*')
        .eq('status', 'completed')
        .order('end_date', { ascending: false })
        .limit(1)
        .single();

      if (cycleError) {
        console.error('Error fetching latest cycle:', cycleError);
        throw cycleError;
      }
      
      // Store the cycle ID for use in other functions
      setLatestCycleId(latestCycle.id);
      
      // Get nominations from history for this cycle
      const { data: nominations, error: nominationsError } = await supabase
        .from('nomination_history')
        .select(`
          id,
          cycle_id,
          voter_id,
          nominee_id,
          selected_areas,
          justification,
          remarks,
          nomination_area_id,
          created_at
        `)
        .eq('cycle_id', latestCycle.id)
        .order('created_at', { ascending: false });

      if (nominationsError) {
        console.error('Error fetching nominations:', nominationsError);
        throw nominationsError;
      }

      setNominations(nominations || []);
    } catch (error) {
      console.error('Error in fetchNominations:', error);
      setError(error instanceof Error ? error.message : 'Failed to fetch nominations');
    } finally {
      setLoading(false);
    }
  };

  const fetchValidations = async () => {
    try {
      setError(null);

      // Get the latest completed cycle
      const { data: latestCycle, error: cycleError } = await supabase
        .from('nomination_cycles')
        .select('*')
        .eq('status', 'completed')
        .order('end_date', { ascending: false })
        .limit(1)
        .single();

      if (cycleError) {
        console.error('Error fetching latest cycle:', cycleError);
        throw cycleError;
      }

      // Get validations for the latest completed cycle
      const { data: validations, error: validationsError } = await supabase
        .from('nomination_validations')
        .select('*')
        .eq('cycle_id', latestCycle.id)
        .order('created_at', { ascending: false });

      if (validationsError) {
        console.error('Error fetching validations:', validationsError);
        throw validationsError;
      }

      setValidations(validations || []);
    } catch (error) {
      console.error('Error in fetchValidations:', error);
      setError(error instanceof Error ? error.message : 'Failed to fetch validations');
    }
  };

  const validateNomination = async (validatorId: string, nomineeId: string) => {
    try {
      setError(null);

      // Get the latest completed cycle
      const { data: latestCycle, error: cycleError } = await supabase
        .from('nomination_cycles')
        .select('*')
        .eq('status', 'completed')
        .order('end_date', { ascending: false })
        .limit(1)
        .single();

      if (cycleError) throw cycleError;
      if (!latestCycle) throw new Error('No completed cycle found');

      // Check if the user has already validated for this cycle
      const existingValidation = validations.find(
        v => v.validator_id === validatorId
      );

      if (existingValidation) {
        // Remove validation locally first
        setValidations(prev => prev.filter(v => 
          v.validator_id !== validatorId
        ));

        // Then remove from database
        const { error: deleteError } = await supabase
          .from('nomination_validations')
          .delete()
          .eq('validator_id', validatorId)
          .eq('cycle_id', latestCycle.id);

        if (deleteError) {
          // Revert local state on error
          setValidations(prev => [...prev, existingValidation]);
          throw deleteError;
        }
      } else {
        // Create new validation object
        const newValidation = {
          validator_id: validatorId,
          nominee_id: nomineeId,
          cycle_id: latestCycle.id,
          created_at: new Date().toISOString()
        };

        // Add new validation locally
        setValidations(prev => [...prev, newValidation]);

        try {
          // Add new validation to database
          const { data, error: insertError } = await supabase
            .from('nomination_validations')
            .insert([{
              validator_id: validatorId,
              nominee_id: nomineeId,
              cycle_id: latestCycle.id
            }])
            .select()
            .single();

          if (insertError) throw insertError;

          // Update local state with actual data from database
          setValidations(prev => [
            ...prev.filter(v => v.validator_id !== validatorId),
            data
          ]);
        } catch (error) {
          // Revert local state on error
          setValidations(prev => prev.filter(v => v.validator_id !== validatorId));
          throw error;
        }
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
    validateNomination,
    getValidationsCount,
    hasValidated,
    refetch: fetchNominations
  };
}