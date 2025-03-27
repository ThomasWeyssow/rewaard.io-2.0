import React, { useState } from 'react';
import { Plus, Pencil, Trash2, AlertCircle, Award, Star, Trophy, Medal, Crown, Gem, Gift, Heart, Rocket, Euro } from 'lucide-react';
import type { Incentive } from '../../hooks/useSettings';
import { IncentiveModal } from './IncentiveModal';
import { ConfirmationModal } from '../common/ConfirmationModal';

interface IncentivesSectionProps {
  incentives: Incentive[];
  onAdd: (title: string, description: string, icon: string) => Promise<void>;
  onUpdate: (id: string, title: string, description: string, icon: string) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
}

const ICON_COMPONENTS = {
  Award,
  Star,
  Trophy,
  Medal,
  Crown,
  Gem,
  Gift,
  Heart,
  Rocket,
  Euro
};

export function IncentivesSection({
  incentives,
  onAdd,
  onUpdate,
  onDelete
}: IncentivesSectionProps) {
  const [showModal, setShowModal] = useState(false);
  const [editingIncentive, setEditingIncentive] = useState<Incentive | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [deletingIncentive, setDeletingIncentive] = useState<Incentive | null>(null);
  const [localIncentives, setLocalIncentives] = useState<Incentive[]>(incentives);

    // Mettre à jour l'état local quand les areas changent
  React.useEffect(() => {
    setLocalIncentives(incentives);
  }, [incentives]);
  
  const handleSubmit = async (title: string, description: string, icon: string) => {
    try {
      setError(null);
      if (editingIncentive) {
        await onUpdate(editingIncentive.id, title, description, icon);
      } else {
        await onAdd(title, description, icon);
      }
      setShowModal(false);
      setEditingIncentive(null);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An error occurred';
      setError(errorMessage);
      throw err;
    }
  };

  const handleDelete = async (id: string) => {
  try {
    setError(null);
    const incentiveToDelete = localIncentives.find(incentive => incentive.id === id);
    
    // Mise à jour optimiste avant l'appel API
    setLocalIncentives(prev => prev.filter(incentive => incentive.id !== id));
    
    await onDelete(id);
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : 'An error occurred';
    setError(errorMessage);

    // Restaurer l'état précédent en cas d'échec
    if (incentiveToDelete) {
      setLocalIncentives(prev => [...prev, incentiveToDelete]);
    }
  }
};

  const getIconComponent = (iconName: string) => {
    return ICON_COMPONENTS[iconName as keyof typeof ICON_COMPONENTS] || Award;
  };

  return (
    <div className="bg-white rounded-2xl shadow-md overflow-hidden">
      <div className="p-10">
        <div className="flex justify-between items-center mb-6">
          <div>
            <h2 className="text-gray-900 text-2xl font-bold">🏆 Hero rewards</h2>
            <p className="text-sm text-gray-700 mt-4">
               Define the rewards that each Hero will receive. Keep your team eager to earn the title!
            </p>
          </div>
        
          {/* Only show the button if there are incentives */}
          {localIncentives.length > 0 && (
            <button
              onClick={() => {
                setEditingIncentive(null);
                setShowModal(true);
                setError(null);
              }}
              className="flex items-center gap-2 px-4 py-2 bg-[#4F03C1] text-[#FEFEFF] text-semibold rounded-lg hover:bg-[#3B0290] transition-colors"
            >
              <Plus size={20} />
              Add reward
            </button>
          )}
        </div>


        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2">
            <AlertCircle size={16} />
            {error}
          </div>
        )}

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {incentives.map((incentive) => {
            const IconComponent = getIconComponent(incentive.icon);
            return (
              <div
                key={incentive.id}
                className="p-4 bg-[#DFF2F1] rounded-lg hover:bg-[#B2DFDA] transition-colors group"
              >
                <div className="flex items-start gap-3">
                  <div className="p-2 bg-[#049687] rounded-lg text-[#FEFEFF]">
                    <IconComponent size={24} />
                  </div>
                  <div className="flex-1">
                    <div className="flex justify-between items-start">
                      <h3 className="font-bold text-[#02695C]">{incentive.title}</h3>
                      <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => {
                            setEditingIncentive(incentive);
                            setShowModal(true);
                            setError(null);
                          }}
                          className="p-1 text-gray-600 hover:text-violet-900 transition-colors rounded hover:bg-white"
                          title="Edit reward"
                        >
                          <Pencil size={16} />
                        </button>
                        <button
                          onClick={() => setDeletingIncentive(incentive)}
                          className="p-1 text-gray-600 hover:text-red-600 transition-colors rounded hover:bg-white"
                          title="Delete reward"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </div>
                    {incentive.description && (
                      <p className="text-sm text-[#049687]">{incentive.description}</p>
                    )}
                  </div>
                </div>
              </div>
            );
          })}

          {incentives.length === 0 && (
            <div className="md:col-span-2 lg:col-span-3 text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
              <Award size={40} className="mx-auto text-gray-600 mb-4" />
              <h3 className="font-medium text-gray-600 mb-1">
                No rewards created yet
              </h3>
              <p className="text-sm text-gray-600 mb-4">
                Start by adding a reward to motivate your employees.
              </p>
              <button
                onClick={() => {
                  setEditingIncentive(null);
                  setShowModal(true);
                  setError(null);
                }}
                className="inline-flex items-center gap-2 px-4 py-2 bg-[#4F03C1] text-[#FEFEFF] text-semibold rounded-lg hover:bg-[#3B0290] transition-colors"
              >
                <Plus size={20} />
                Add reward
              </button>
            </div>
          )}
        </div>
      </div>

      <IncentiveModal
        isOpen={showModal}
        onClose={() => {
          setShowModal(false);
          setEditingIncentive(null);
          setError(null);
        }}
        onSubmit={handleSubmit}
        initialValues={editingIncentive || undefined}
        error={error}
      />

      <ConfirmationModal
        isOpen={deletingIncentive !== null}
        onClose={() => setDeletingIncentive(null)}
        onConfirm={() => {
          if (deletingIncentive) {
            handleDelete(deletingIncentive.id);
          }
          setDeletingIncentive(null);
        }}
        title="Delete reward"
        message={`Are you sure you want to delete this reward "${deletingIncentive?.title}"? This action cannot be undone.`}
        confirmLabel="Delete"
        cancelLabel="Cancel"
        type="danger"
      />

    </div>
  );
}