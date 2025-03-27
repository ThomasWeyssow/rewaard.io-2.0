import React, { useState } from 'react';
import { Calendar, Pencil, AlertCircle, Clock, Award, Plus } from 'lucide-react';
import type { NominationArea } from '../../types';
import { NextNominationModal } from './NextNominationModal';
import { formatDateToParisEN } from '../../utils/dateUtils';

interface NextNominationAreaProps {
  areas: NominationArea[];
  selectedAreaId: string | null;
  onSelect: (areaId: string, startDate: string, period: 'monthly' | 'bi-monthly') => Promise<void>;
  nextNominationDate: string;
  nominationCycleDates: {
    start: string;
    end: string;
  };
  nominationPeriod: 'monthly' | 'bi-monthly' | null;
  readOnly?: boolean;
}

export function NextNominationArea({ 
  areas, 
  selectedAreaId, 
  onSelect,
  nextNominationDate,
  nominationCycleDates,
  nominationPeriod,
  readOnly
}: NextNominationAreaProps) {
  const [selectedEmployee, setSelectedEmployee] = useState<string | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (startDate: string, areaId: string, period: 'monthly' | 'bi-monthly') => {
    try {
      setError(null);
      await onSelect(areaId, startDate, period);
      setShowModal(false);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An error occurred';
      setError(errorMessage);
      throw err;
    }
  };

  const selectedArea = areas.find(area => area.id === selectedAreaId);

  return (
    <div className="bg-gradient-to-br from-[#3B0290] to-[#AA00FF] rounded-2xl shadow-sm overflow-hidden group">
      <div className="p-10">
        <div className="flex items-start justify-between">
          <div>
            <h2 className="text-2xl font-semibold text-[#FEFEFF] mb-6">🚀 Prepare for the next Hero selection</h2>
            {selectedAreaId ? (
              <div className="flex flex-col gap-1 mt-2">
                <div className="flex items-center gap-2 text-violet-50">
                  <Clock size={16} />
                  <span className="text-sm">
                    {nominationPeriod === 'monthly' ? 'Monthly' : 'Bi-monthly'} nomination
                  </span>
                </div>
                <div className="flex items-center gap-2 text-violet-50">
                  <Calendar size={16} />
                  <span className="text-sm">
                    From {formatDateToParisEN(nominationCycleDates.start)} to {formatDateToParisEN(nominationCycleDates.end)}
                  </span>
                </div>
                {selectedArea && (
                  <div className="flex items-center gap-2 text-violet-50">
                    <Award size={16} />
                    <span className="text-sm">
                      Skill to reward: {selectedArea.category}
                    </span>
                  </div>
                )}
              </div>
            ) : (
              <div className="mt-4">
                <button
                  onClick={() => setShowModal(true)}
                  disabled={readOnly}
                  className="flex items-center gap-2 px-4 py-2 bg-[#FE348C] text-[#FEFEFF] rounded-lg hover:bg-[#E70076] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <Plus size={20} />
                  Set up next nomination
                </button>
              </div>
            )}
          </div>

          {selectedAreaId && !readOnly && (
            <button
              onClick={() => setShowModal(true)}
              className="p-2 text-violet-50 opacity-0 group-hover:opacity-100 hover:bg-violet-50 hover:text-violet-900 transition-all rounded-lg"
              title="Edit next nomination cycle"
            >
              <Pencil size={20} />
            </button>
          )}
        </div>

        {error && (
          <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            {error}
          </div>
        )}
      </div>

      <NextNominationModal
        isOpen={showModal}
        onClose={() => {
          setShowModal(false);
          setError(null);
        }}
        onSubmit={handleSubmit}
        areas={areas}
        selectedAreaId={selectedAreaId}
        currentStartDate={nextNominationDate}
        nominationPeriod={nominationPeriod}
        error={error}
      />
    </div>
  );
}