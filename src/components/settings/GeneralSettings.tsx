import React, { useState } from 'react';
import { AlertCircle, RotateCw } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface GeneralSettingsProps {
  settings: {
    nomination_period: 'monthly' | 'bi-monthly';
    nomination_start_date: string;
  } | null;
  onUpdateSettings: (
    nominationPeriod: 'monthly' | 'bi-monthly',
    nominationStartDate: string
  ) => Promise<void>;
}

export function GeneralSettings({ settings, onUpdateSettings }: GeneralSettingsProps) {
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [updating, setUpdating] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSaving(true);
      setError(null);
      await onUpdateSettings(
        settings?.nomination_period || 'monthly',
        settings?.nomination_start_date || new Date().toISOString().split('T')[0]
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateCycle = async () => {
    try {
      setUpdating(true);
      setError(null);
      
      const { error: updateError } = await supabase.rpc('check_and_update_nomination_cycles');
      
      if (updateError) throw updateError;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update nomination cycles');
    } finally {
      setUpdating(false);
    }
  };

  return (   
    <div className="bg-white rounded-2xl">
      <div className="p-10">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">Settings</h1>
          <p className="text-sm text-gray-700">
            Configure your Hero of the Month recognition program
          </p>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2">
            <AlertCircle size={16} />
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          {saving && (
            <div className="flex justify-end gap-3 mt-6">
              <button
                type="submit"
                disabled={saving}
                className={`px-4 py-2 rounded-lg text-white transition-colors ${
                  saving
                    ? 'bg-indigo-400 cursor-not-allowed'
                    : 'bg-indigo-600 hover:bg-indigo-700'
                }`}
              >
                {saving ? 'Saving...' : 'Save'}
              </button>
            </div>
          )}
        </form>

        {/* Bouton pour mettre à jour manuellement les cycles */}
        <div className="mt-8 pt-6 border-t">
          <h3 className="text-lg font-medium text-gray-900 mb-2">Manual Action</h3>
          <p className="text-sm text-gray-700 mb-4">
            Manually trigger nomination cycle updates
          </p>
          <button
            onClick={handleUpdateCycle}
            disabled={updating}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-white transition-colors ${
              updating
                ? 'bg-[#4F03C1] cursor-not-allowed'
                : 'bg-[#4F03C1] hover:bg-[#3B0290]'
            }`}
          >
            <RotateCw size={20} className={updating ? 'animate-spin' : ''} />
            {updating ? 'Updating cycles...' : 'Update nomination cycles'}
          </button>
        </div>
      </div>
    </div>
  );
}