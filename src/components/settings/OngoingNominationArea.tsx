import React, { useState } from 'react';
import { Calendar, Trash2 } from 'lucide-react';
import type { NominationArea } from '../../types';
import { ConfirmationModal } from '../common/ConfirmationModal';
import { formatDateToParisEN } from '../../utils/dateUtils';

interface OngoingNominationAreaProps {
  ongoingCycleDates?: {
    start: string;
    end: string;
  } | null;
  ongoingArea?: NominationArea | null;
  onDelete: () => Promise<void>;
}

export function OngoingNominationArea({ 
  ongoingCycleDates,
  ongoingArea,
  onDelete
}: OngoingNominationAreaProps) {
  const [showDeleteModal, setShowDeleteModal] = useState(false);

  if (!ongoingCycleDates?.start) {
    return (
      <div className="bg-gradient-to-br from-violet-50 to-white rounded-2xl shadow-md overflow-hidden">
        <div className="p-10">
          <div className="flex items-start justify-between">
            <div>
              <h2 className="text-2xl font-semibold text-gray-900 mb-3">There's no ongoing Hero selection</h2>
              <p className="text-gray-700 mt-2 text-sm">If you haven't set up the next nomination cycle yet, do it now. Otherwise, sit tight and wait for the next cycle to begin!</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-[#FEFEFF] rounded-2xl shadow-md overflow-hidden">
      <div className="p-10">
        <div className="flex items-start justify-between">
          <div>
            <h2 className="text-gray-900 text-2xl font-bold">⏳ Ongoing Hero selection</h2>
            <div className="flex flex-col gap-1 mt-2">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-amber-50 text-amber-700 font-medium mt-3">
                <Calendar size={16} />
                <span className="text-sm">
                  From {formatDateToParisEN(ongoingCycleDates.start)} to {formatDateToParisEN(ongoingCycleDates.end)}
                </span>
              </div>
            </div>
          </div>
          <button
            onClick={() => setShowDeleteModal(true)}
            className="p-2 text-gray-400 hover:text-red-600 transition-colors rounded-lg hover:bg-gray-50"
            title="Delete ongoing nomination cycle"
          >
            <Trash2 size={20} />
          </button>
        </div>

        {ongoingArea && (
          <div className="mt-6">
              <h3 className="font-medium text-gray-700">Skill of the month: {ongoingArea.category}
              </h3>
            <div className="p-4 space-y-3">
              {ongoingArea.areas.map((area, index) => (
                <div 
                  key={index}
                  className="pl-4 border-l-2 border-[#EEE7F7] py-2"
                >
                  <h4 className="text-sm font-medium text-gray-800">{area.title}</h4>
                  {area.description && (
                    <p className="text-sm text-gray-600 mt-1">{area.description}</p>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <ConfirmationModal
        isOpen={showDeleteModal}
        onClose={() => setShowDeleteModal(false)}
        onConfirm={onDelete}
        title="Delete Ongoing Nomination Cycle"
        message="Are you sure you want to delete the ongoing nomination cycle? This action cannot be undone."
        confirmLabel="Delete"
        cancelLabel="Cancel"
        type="danger"
      />
    </div>
  );
}