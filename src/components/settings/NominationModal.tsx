import React, { useState, useEffect } from 'react';
import {Trash2, Plus, AlertCircle, Star, Users, Brain, Target, Lightbulb, HandHeart, Award, Trophy, Medal, Crown } from 'lucide-react';
import type { NominationArea } from '../../hooks/useSettings';

interface NominationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (category: string, areas: { title: string; description: string }[], icon: string) => Promise<void>;
  initialValues?: NominationArea;
  error?: string | null;
}

const AVAILABLE_ICONS = [
  { name: 'Star', icon: Star },
  { name: 'Users', icon: Users },
  { name: 'Brain', icon: Brain },
  { name: 'Target', icon: Target },
  { name: 'Lightbulb', icon: Lightbulb },
  { name: 'HandHeart', icon: HandHeart },
  { name: 'Award', icon: Award },
  { name: 'Trophy', icon: Trophy },
  { name: 'Medal', icon: Medal },
  { name: 'Crown', icon: Crown }
];

export function NominationModal({
  isOpen,
  onClose,
  onSubmit,
  initialValues,
  error
}: NominationModalProps) {
  const [category, setCategory] = useState(initialValues?.category || '');
  const [areas, setAreas] = useState<{ title: string; description: string }[]>(
    initialValues?.areas || [{ title: '', description: '' }]
  );
  const [icon, setIcon] = useState(initialValues?.icon || 'Star');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (initialValues) {
      setCategory(initialValues.category);
      setAreas(initialValues.areas);
      setIcon(initialValues.icon || 'Star');
    } else {
      setCategory('');
      setAreas([{ title: '', description: '' }]);
      setIcon('Star');
    }
  }, [initialValues]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!category.trim()) {
      return;
    }
    
    // Filter out empty areas
    const validAreas = areas.filter(area => area.title.trim());
    if (validAreas.length === 0) {
      return;
    }

    try {
      setSaving(true);
      await onSubmit(category.trim(), validAreas, icon);
    } catch (err) {
      // Error is handled by parent component
    } finally {
      setSaving(false);
    }
  };

  const addArea = () => {
    setAreas([...areas, { title: '', description: '' }]);
  };

  const removeArea = (index: number) => {
    if (areas.length > 1) {
      setAreas(areas.filter((_, i) => i !== index));
    }
  };

  const updateArea = (index: number, field: 'title' | 'description', value: string) => {
    const newAreas = [...areas];
    newAreas[index] = { ...newAreas[index], [field]: value };
    setAreas(newAreas);
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-2xl p-10 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <h3 className="text-2xl text-center font-semibold mb-6">
          {initialValues ? 'Edit skill' : 'Add skill'}
        </h3>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2">
            <AlertCircle size={16} />
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-900 mt-6 mb-1">
              Category
              <span className="text-red-500 ml-1">*</span>
            </label>
            <input
              type="text"
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1]" 
              placeholder="Eg. Leadership"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-900 mb-1">
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

          <div>
            <div className="flex justify-between items-center mb-4">
              <label className="block text-sm font-medium text-gray-900 mb-1">
                Core competencies
                <span className="text-red-500 ml-1">*</span>
              </label>
              <button
                type="button"
                onClick={addArea}
                className="flex items-center gap-1 text-sm bg-[#4F03C1] rounded-lg px-3 py-2 text-[#FEFEFF] hover:bg-[#3B0290] mb-1"
              >
                <Plus size={16} />
                Add new
              </button>
            </div>

            <div className="space-y-4">
              {areas.map((area, index) => (
                <div
                  key={index}
                  className="flex gap-4 items-start p-4 bg-gray-50 rounded-lg relative group"
                >
                  <div className="flex-1 space-y-3">
                    <input
                      type="text"
                      value={area.title}
                      onChange={(e) => updateArea(index, 'title', e.target.value)}
                      className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1]"
                      placeholder="Title"
                      required
                    />
                    <textarea
                      value={area.description}
                      onChange={(e) => updateArea(index, 'description', e.target.value)}
                      className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1]"
                      placeholder="Description"
                      rows={2}
                    />
                  </div>
                  {areas.length > 1 && (
                    <button
                      type="button"
                      onClick={() => removeArea(index)}
                      className="p-2 text-gray-400 hover:text-red-600 transition-colors"
                      title="Delete"
                    >
                      <Trash2 size={18} />
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-4">
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
              disabled={
                saving ||
                !category.trim() ||  // Category must not be empty
                !icon ||             // Icon must be selected
                areas.length === 0 || // At least one core competency
                areas.some(area => !area.title.trim()) // Ensure each core competency has a title
              }
              className={`px-4 py-2 text-white rounded-lg transition-colors ${
                saving ||
                !category.trim() ||
                !icon ||
                areas.length === 0 ||
                areas.some(area => !area.title.trim())
                  ? 'bg-[#7E58C2] cursor-not-allowed' // Disabled style
                  : 'bg-[#4F03C1] hover:bg-[#3B0290] text-[#FEFEFF]' // Enabled style
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