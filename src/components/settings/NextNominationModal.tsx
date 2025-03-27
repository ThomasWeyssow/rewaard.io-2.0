import React, { useState, useEffect } from 'react';
import { AlertCircle } from 'lucide-react';
import type { NominationArea } from '../../types';

interface NextNominationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (startDate: string, areaId: string, period: 'monthly' | 'bi-monthly') => Promise<void>;
  areas: NominationArea[];
  selectedAreaId: string | null;
  currentStartDate: string;
  nominationPeriod: 'monthly' | 'bi-monthly' | null;
  error?: string | null;
}

export function NextNominationModal({
  isOpen,
  onClose,
  onSubmit,
  areas,
  selectedAreaId,
  currentStartDate,
  nominationPeriod: initialNominationPeriod,
  error: initialError
}: NextNominationModalProps) {
  const [startDate, setStartDate] = useState(currentStartDate || '');
  const [areaId, setAreaId] = useState(selectedAreaId || '');
  const [nominationPeriod, setNominationPeriod] = useState<'monthly' | 'bi-monthly'>(initialNominationPeriod || 'monthly');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(initialError || null);
  const [calculatedEndDate, setCalculatedEndDate] = useState<Date | null>(null);

  // Calculate end date when start date or period changes
  useEffect(() => {
    if (startDate) {
      const start = new Date(startDate);
      if (isNaN(start.getTime())) return;

      const end = new Date(start);
      if (nominationPeriod === 'monthly') {
        end.setMonth(end.getMonth() + 1);
      } else {
        end.setMonth(end.getMonth() + 2);
      }
      end.setDate(end.getDate() - 1);
      setCalculatedEndDate(end);
    }
  }, [startDate, nominationPeriod]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!startDate || !areaId) return;

    try {
      setSaving(true);
      setError(null);
      
      // Create the date string in UTC
      const startDateTime = new Date(startDate);
      startDateTime.setUTCHours(0, 1, 0, 0);
      const utcStartDate = startDateTime.toISOString();
      
      await onSubmit(utcStartDate, areaId, nominationPeriod);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-2xl p-10 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <h3 className="text-2xl text-center font-semibold mb-6">
          Set up next nomination
        </h3>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2">
            <AlertCircle size={16} />
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nomination frequency<span className="text-red-500 ml-1">*</span>
            </label>
            <select
              value={nominationPeriod}
              onChange={(e) => setNominationPeriod(e.target.value as 'monthly' | 'bi-monthly')}
              className="block w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1]"
              required           
            >
              <option value="monthly">Monthly</option>
              <option value="bi-monthly">Bi-monthly</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Next nomination start date
              <span className="text-red-500 ml-1">*</span>
            </label>
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1]"
              required
            />
          </div>

          {calculatedEndDate && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Next nomination end date
              </label>
              <div className="block w-full px-3 py-2 border border-gray-200 bg-gray-50 rounded-md text-gray-700">
                {calculatedEndDate.toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                })}
              </div>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Skill to reward
              <span className="text-red-500 ml-1">*</span>
            </label>
            <select
              value={areaId}
              onChange={(e) => setAreaId(e.target.value)}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1]"
              required
            >
              <option value="">Select skill</option>
              {areas.map(area => (
                <option key={area.id} value={area.id}>
                  {area.category}
                </option>
              ))}
            </select>
          </div>

          <div className="flex justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              disabled={saving}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || !startDate || !areaId}
              className={`px-4 py-2 text-white rounded-lg transition-colors ${
                saving || !startDate || !areaId
                  ? 'bg-[#7E58C2] cursor-not-allowed'
                  : 'bg-[#4F03C1] hover:bg-[#3B0290]'
              }`}
            >
              {saving ? 'Saving...' : 'Save'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}