import React, { useState } from 'react';
import { Plus, Pencil, Trash2, AlertCircle, Star, Users, Brain, Target, Lightbulb, HandHeart, Award, Trophy, Medal, Crown } from 'lucide-react';
import type { NominationArea } from '../../hooks/useSettings';
import { NominationModal } from './NominationModal';
import { ConfirmationModal } from '../common/ConfirmationModal';

interface NominationSectionProps {
  areas: NominationArea[];
  onAdd: (category: string, areas: { title: string; description: string }[], icon: string) => Promise<void>;
  onUpdate: (id: string, category: string, areas: { title: string; description: string }[], icon: string) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
}

const ICON_COMPONENTS = {
  Star,
  Users,
  Brain,
  Target,
  Lightbulb,
  HandHeart,
  Award,
  Trophy,
  Medal,
  Crown
};

export function NominationSection({
  areas,
  onAdd,
  onUpdate,
  onDelete
}: NominationSectionProps) {
  const [error, setError] = useState<string | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [editingArea, setEditingArea] = useState<NominationArea | null>(null);
  const [deletingArea, setDeletingArea] = useState<NominationArea | null>(null);
  const [localAreas, setLocalAreas] = useState<NominationArea[]>(areas);

  // Mettre à jour l'état local quand les areas changent
  React.useEffect(() => {
    setLocalAreas(areas);
  }, [areas]);

  const handleSubmit = async (category: string, areas: { title: string; description: string }[], icon: string) => {
    try {
      setError(null);
      if (editingArea) {
        // Mise à jour optimiste pour l'édition
        setLocalAreas(prev => prev.map(area => 
          area.id === editingArea.id 
            ? { ...area, category, areas, icon }
            : area
        ));
        await onUpdate(editingArea.id, category, areas, icon);
      } else {
        await onAdd(category, areas, icon);
      }
      setShowModal(false);
      setEditingArea(null);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An error occurred';
      setError(errorMessage);
      // Restaurer l'état précédent en cas d'erreur
      if (editingArea) {
        setLocalAreas(prev => prev.map(area => 
          area.id === editingArea.id ? editingArea : area
        ));
      }
      throw err;
    }
  };

  const handleDelete = async (id: string) => {
    try {
      setError(null);
      // Mise à jour optimiste pour la suppression
      const areaToDelete = localAreas.find(area => area.id === id);
      setLocalAreas(prev => prev.filter(area => area.id !== id));
      await onDelete(id);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An error occurred';
      setError(errorMessage);
      // Restaurer l'état précédent en cas d'erreur
      if (areaToDelete) {
        setLocalAreas(prev => [...prev, areaToDelete]);
      }
    }
  };

  const getIconComponent = (iconName: string) => {
    return ICON_COMPONENTS[iconName as keyof typeof ICON_COMPONENTS] || Star;
  };

  return (
    <div className="bg-white rounded-2xl shadow-md overflow-hidden p-10">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-gray-900 text-2xl font-bold">🏅 Skills to reward</h2>
          <p className="text-sm text-gray-700 mt-4">
            Define the list of skills to be rewarded in the Hero of the Month program.
          </p>
        </div>

        {/* Only show the button if there are skills */}
        {localAreas.length > 0 && (
        <button
          onClick={() => {
            setEditingArea(null);
            setShowModal(true);
            setError(null);
          }}
          className="flex items-center gap-2 px-4 py-2 bg-[#4F03C1] text-[#FEFEFF] text-semibold rounded-lg hover:bg-[#3B0290] transition-colors"
        >
          <Plus size={24} />
          Add skill
        </button>
      )}
    </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2">
          <AlertCircle size={16} />
          {error}
        </div>
      )}

      <div className="grid gap-4 md:grid-cols-2">
        {localAreas.map((area) => {
          const IconComponent = getIconComponent(area.icon);
          return (
            <div
              key={area.id}
              className="bg-[#FEFEFF] rounded-lg hover:bg-[#DFF2F1] transition-colors group"
            >
              <div className="p-4 bg-[#DFF2F1] rounded-lg flex justify-between items-start">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-[#049687] rounded-lg text-[#FEFEFF]">
                    <IconComponent size={24} />
                  </div>
                  <div>
                    <h3 className="font-bold text-[#02695C]">{area.category}</h3>
                    <p className="text-sm text-[#049687]">
                      {area.areas.length} core {area.areas.length > 1 ? 'competencies' : 'competency'}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    onClick={() => {
                      setEditingArea(area);
                      setShowModal(true);
                      setError(null);
                    }}
                    className="p-2 text-gray-600 hover:text-violet-900 transition-colors rounded-lg hover:bg-white"
                    title="Edit"
                  >
                    <Pencil size={18} />
                  </button>
                  <button
                    onClick={() => setDeletingArea(area)}
                    className="p-2 text-gray-600 hover:text-red-600 transition-colors rounded-lg hover:bg-white"
                    title="Delete"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              </div>

              
              <div className="p-4 space-y-3 mt-4">
                {area.areas.map((subArea, index) => (
                  <div 
                    key={index} 
                    className="pl-4 border-l-2 border-[#B2DFDA] py-2"
                  >
                    <h4 className="font-medium text-sm text-gray-900">{subArea.title}</h4>
                    {subArea.description && (
                      <p className="text-sm text-gray-600 mt-1">{subArea.description}</p>
                    )}
                  </div>
                ))}
              </div>
            </div>
          );
        })}

        {localAreas.length === 0 && (
          <div className="md:col-span-2 text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
            <h3 className="font-medium text-gray-900 mb-1">
              No skills created yet
            </h3>
            <p className="text-sm text-gray-600 mb-4">
              Start by adding a skill to reward
            </p>
            <button
              onClick={() => {
                setEditingArea(null);
                setShowModal(true);
                setError(null);
              }}
              className="inline-flex items-center gap-2 px-4 py-2 bg-[#4F03C1] text-[#FEFEFF] text-semibold rounded-lg hover:bg-[#3B0290] transition-colors"
            >
              <Plus size={20} />
              Add skill
            </button>
          </div>
        )}
      </div>

      <NominationModal
        isOpen={showModal}
        onClose={() => {
          setShowModal(false);
          setEditingArea(null);
          setError(null);
        }}
        onSubmit={handleSubmit}
        initialValues={editingArea || undefined}
        error={error}
      />

      <ConfirmationModal
        isOpen={deletingArea !== null}
        onClose={() => setDeletingArea(null)}
        onConfirm={() => {
          if (deletingArea) {
            handleDelete(deletingArea.id);
          }
          setDeletingArea(null);
        }}
        title="Delete skill"
        message={`Are you sure you want to delete this skill "${deletingArea?.category}"? This action cannot be undone.`}
        confirmLabel="Delete"
        cancelLabel="Cancel"
        type="danger"
      />
    </div>
  );
}