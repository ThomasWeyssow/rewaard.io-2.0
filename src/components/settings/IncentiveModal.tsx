import React, { useState, useEffect } from 'react';
import { AlertCircle, Award, Star, Trophy, Medal, Crown, Gem, Gift, Heart, Rocket, Euro } from 'lucide-react';

interface IncentiveModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (title: string, description: string, icon: string) => Promise<void>;
  initialValues?: {
    title: string;
    description: string;
    icon: string;
  };
  error?: string | null;
}

const AVAILABLE_ICONS = [
  { name: 'Award', icon: Award },
  { name: 'Star', icon: Star },
  { name: 'Trophy', icon: Trophy },
  { name: 'Medal', icon: Medal },
  { name: 'Crown', icon: Crown },
  { name: 'Gem', icon: Gem },
  { name: 'Gift', icon: Gift },
  { name: 'Heart', icon: Heart },
  { name: 'Rocket', icon: Rocket },
  { name: 'Euro', icon: Euro }
];

export function IncentiveModal({
  isOpen,
  onClose,
  onSubmit,
  initialValues,
  error
}: IncentiveModalProps) {
  const [title, setTitle] = useState(initialValues?.title || '');
  const [description, setDescription] = useState(initialValues?.description || '');
  const [icon, setIcon] = useState(initialValues?.icon || 'Award');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (initialValues) {
      setTitle(initialValues.title);
      setDescription(initialValues.description);
      setIcon(initialValues.icon);
    } else {
      setTitle('');
      setDescription('');
      setIcon('Award');
    }
  }, [initialValues]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      return;
    }

    try {
      setSaving(true);
      await onSubmit(title.trim(), description.trim(), icon);
    } catch (err) {
      // L'erreur est gérée par le composant parent
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-2xl p-10 max-w-2xl w-full max-h-[90vh] overflow-y-auto ">
        <h3 className="text-2xl text-center font-semibold mb-6">
          {initialValues ? 'Modify reward' : 'Add reward'}
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
              Title
              <span className="text-red-500 ml-1">*</span>
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1]"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
              <span className="text-red-500 ml-1">*</span>
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1]"
              rows={3}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Icon
              <span className="text-red-500 ml-1">*</span>
            </label>
            <div className="grid grid-cols-5 gap-2">
              {AVAILABLE_ICONS.map(({ name, icon: IconComponent }) => (
                <button
                  key={name}
                  type="button"
                  onClick={() => setIcon(name)}
                  className={`flex items-center justify-center p-3 rounded-lg transition-all ${
                    icon === name
                      ? 'bg-[#EEE7F7] text-[#4F03C1] ring-2 ring-[#4F03C1]'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  <IconComponent size={24} />
                </button>
              ))}
            </div>
          </div>

          <div className="flex justify-end gap-2 mt-6">
            <button
              type="button"
              onClick={onClose}
              disabled={saving}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50 mt-6"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || !title.trim() || !description.trim()}
              className={`px-4 py-2 text-white rounded-lg transition-colors mt-6 ${
                saving || !title.trim() || !description.trim()
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