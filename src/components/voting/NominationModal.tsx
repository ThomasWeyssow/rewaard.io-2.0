import React, { useState } from 'react';
import { AlertCircle, HelpCircle } from 'lucide-react';
import type { NominationArea } from '../../hooks/useSettings';

interface NominationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (selectedAreas: string[], justification: string, remarks?: string) => Promise<void>;
  nomineeInfo: {
    name: string;
    department: string;
  };
  ongoingArea: NominationArea;
}

export function NominationModal({
  isOpen,
  onClose,
  onSubmit,
  nomineeInfo,
  ongoingArea
}: NominationModalProps) {
  const [selectedAreas, setSelectedAreas] = useState<string[]>([]);
  const [justification, setJustification] = useState('');
  const [remarks, setRemarks] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedAreas.length === 0) {
      setError('Please select at least one area of outstanding performance');
      return;
    }

    if (!justification.trim()) {
      setError('Please provide a comment');
      return;
    }

    try {
      setSaving(true);
      setError(null);
      await onSubmit(selectedAreas, justification, remarks.trim() || undefined);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setSaving(false);
    }
  };

  const toggleArea = (areaTitle: string) => {
    setSelectedAreas(prev => 
      prev.includes(areaTitle)
        ? prev.filter(title => title !== areaTitle)
        : [...prev, areaTitle]
    );
    setError(null);
  };

  return (
    <div className="modal-opacity">
      <div className="modal-style">
        <h2 className="heading-2 text-center">
          Nominate {nomineeInfo.name}
        </h2>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2">
            <AlertCircle size={16} />
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-8">
          <div>
            <p className="subtitle-2">
              What are your nominee's strengths?
              <span className="text-lg text-red-500 ml-1">*</span>
            </p>
            <div className="space-y-3">
              {ongoingArea.areas.map((area) => (
                <label
                  key={area.title}
                  className={`flex items-start gap-3 p-4 rounded-xl cursor-pointer transition-colors ${
                    selectedAreas.includes(area.title)
                      ? 'bg-[#EDE6F8] border-2 border-[#4F03C1] hover:bg-[#DBCEF3]'
                      : 'bg-gray-50 border-gray-200 hover:bg-gray-100'
                  }`}
                >
                  <input
                    type="checkbox"
                    className="mt-1"
                    checked={selectedAreas.includes(area.title)}
                    onChange={() => toggleArea(area.title)}
                  />
                  <div>
                    <div className="subtitle-2">{area.title}</div>
                    {area.description && (
                      <div className="body-2">{area.description}</div>
                    )}
                  </div>
                </label>
              ))}
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="subtitle-2">
                Tell us why you're nominating this colleague
                <span className="text-lg text-red-500 ml-1">*</span>
              </label>
            </div>
            <textarea
              value={justification}
              onChange={(e) => {
                const value = e.target.value;
                if (value.length <= 512) {
                  setJustification(value);
                  setError(null);
                }
              }}
              className="w-full px-3 py-2 body-2 border border-gray-300 rounded-xl focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1] min-h-[120px]"
              placeholder="Give specific examples, behaviors, etc."
              required
              maxLength={512}
            />
          </div>

          <div>
            <label className="subtitle-2">
              Any additional thoughts?
            </label>
            <textarea
              value={remarks}
              onChange={(e) => {
                const value = e.target.value;
                if (value.length <= 512) {
                  setRemarks(value);
                }
              }}
              className="mt-2 w-full px-3 py-2 body-2 border border-gray-300 rounded-xl focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1] min-h-[120px]"
              placeholder="Optional additional comment..."
              maxLength={512}
            />
          </div>

          <div className="flex justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              disabled={saving}
              className="button-cancel"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || selectedAreas.length === 0 || !justification.trim()}
              className={` ${
                saving || selectedAreas.length === 0 || !justification.trim()
                  ? 'button-primary-disabled'
                  : 'button-primary'
              }`}
            >
              {saving ? 'Nominating...' : 'Submit nomination'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}