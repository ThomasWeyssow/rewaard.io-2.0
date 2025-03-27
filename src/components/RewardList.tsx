import React, { useState } from 'react';
import { Reward } from '../types';
import { Gift, Plus, Pencil, Trash2, Euro, AlertCircle } from 'lucide-react';
import { usePermissions } from '../hooks/usePermissions';
import { useStorage } from '../hooks/useStorage';
import { useRewards } from '../hooks/useRewards';
import { useAuth } from '../hooks/useAuth';
import { useProfiles } from '../hooks/useProfiles';

interface RewardModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (name: string, description: string, pointsCost: number, imageUrl: string) => Promise<void>;
  initialValues?: Reward;
  error?: string | null;
}

function RewardModal({ isOpen, onClose, onSubmit, initialValues, error }: RewardModalProps) {
  const [name, setName] = useState(initialValues?.name || '');
  const [description, setDescription] = useState(initialValues?.description || '');
  const [pointsCost, setPointsCost] = useState(initialValues?.pointsCost.toString() || '');
  const [imageUrl, setImageUrl] = useState(initialValues?.image || '');
  const [saving, setSaving] = useState(false);

  // Reset form when initialValues changes
  React.useEffect(() => {
    if (initialValues) {
      setName(initialValues.name);
      setDescription(initialValues.description);
      setPointsCost(initialValues.pointsCost.toString());
      setImageUrl(initialValues.image);
    } else {
      setName('');
      setDescription('');
      setPointsCost('');
      setImageUrl('');
    }
  }, [initialValues]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !pointsCost) return;

    try {
      setSaving(true);
      await onSubmit(
        name.trim(),
        description.trim(),
        parseInt(pointsCost, 10),
        imageUrl
      );
    } catch (err) {
      // Error handled by parent
    } finally {
      setSaving(false);
    }
  };

  if (!isOpen) return null;

  const euroEquivalent = parseInt(pointsCost || '0', 10);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full">
        <h3 className="text-lg font-semibold mb-4">
          {initialValues ? 'Edit Reward' : 'Add New Reward'}
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
              Name
              <span className="text-red-500 ml-1">*</span>
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              rows={3}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Points Cost
              <span className="text-red-500 ml-1">*</span>
            </label>
            <div className="space-y-2">
              <input
                type="number"
                value={pointsCost}
                onChange={(e) => setPointsCost(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                min="0"
                required
              />
              <div className="text-sm text-gray-600 flex items-center gap-1">
                <Euro size={14} />
                <span>Equivalent: {euroEquivalent} €</span>
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Image URL
              <span className="text-red-500 ml-1">*</span>
            </label>
            <input
              type="url"
              value={imageUrl}
              onChange={(e) => setImageUrl(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="https://example.com/image.jpg"
              required
            />
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
              disabled={saving || !name.trim() || !pointsCost || !imageUrl}
              className={`px-4 py-2 text-white rounded-lg transition-colors ${
                saving || !name.trim() || !pointsCost || !imageUrl
                  ? 'bg-indigo-400 cursor-not-allowed'
                  : 'bg-indigo-600 hover:bg-indigo-700'
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

interface ConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
}

function ConfirmationModal({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel'
}: ConfirmationModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full">
        <h3 className="text-lg font-semibold mb-2">{title}</h3>
        <p className="text-gray-600 mb-6">{message}</p>
        <div className="flex justify-end gap-3">
          <button
            onClick={onClose}
            className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            {cancelLabel}
          </button>
          <button
            onClick={() => {
              onConfirm();
              onClose();
            }}
            className="px-4 py-2 text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors"
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

interface UnlockConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  reward: Reward;
}

function UnlockConfirmationModal({
  isOpen,
  onClose,
  onConfirm,
  reward
}: UnlockConfirmationModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full">
        <h3 className="text-lg font-semibold mb-2">Unlock Reward</h3>
        <p className="text-gray-600 mb-4">
          Are you sure you want to unlock "{reward.name}" for {reward.pointsCost} points?
        </p>
        <div className="p-4 bg-gray-50 rounded-lg mb-6">
          <div className="flex items-center gap-2 text-gray-600">
            <Gift size={20} />
            <span>Cost: {reward.pointsCost} points</span>
          </div>
          <div className="flex items-center gap-2 text-gray-600 mt-2">
            <Euro size={20} />
            <span>Value: {reward.pointsCost} €</span>
          </div>
        </div>
        <div className="flex justify-end gap-3">
          <button
            onClick={onClose}
            className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={() => {
              onConfirm();
              onClose();
            }}
            className="px-4 py-2 text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 transition-colors"
          >
            Confirm Unlock
          </button>
        </div>
      </div>
    </div>
  );
}

interface RewardListProps {
  rewards: Reward[];
  userPoints: number;
}

export function RewardList({ rewards, userPoints }: RewardListProps) {
  const { canModifySettings } = usePermissions();
  const { createReward, updateReward, deleteReward, unlockReward } = useRewards();
  const [showModal, setShowModal] = useState(false);
  const [editingReward, setEditingReward] = useState<Reward | null>(null);
  const [deletingReward, setDeletingReward] = useState<Reward | null>(null);
  const [unlockingReward, setUnlockingReward] = useState<Reward | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [localRewards, setLocalRewards] = useState<Reward[]>(rewards);

  // Update local state when props change
  React.useEffect(() => {
    setLocalRewards(rewards);
  }, [rewards]);

  const handleSubmit = async (name: string, description: string, pointsCost: number, imageUrl: string) => {
    try {
      setError(null);
      if (editingReward) {
        // Update existing reward
        const updatedReward = await updateReward(editingReward.id, name, description, pointsCost, imageUrl);
        setLocalRewards(prev => prev.map(r => r.id === editingReward.id ? {
          id: updatedReward.id,
          name: updatedReward.name,
          description: updatedReward.description,
          pointsCost: updatedReward.points_cost,
          image: updatedReward.image_url
        } : r));
      } else {
        // Create new reward
        const newReward = await createReward(name, description, pointsCost, imageUrl);
        setLocalRewards(prev => [...prev, {
          id: newReward.id,
          name: newReward.name,
          description: newReward.description,
          pointsCost: newReward.points_cost,
          image: newReward.image_url
        }]);
      }
      setShowModal(false);
      setEditingReward(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    }
  };

  const handleDelete = async (reward: Reward) => {
    try {
      setError(null);
      await deleteReward(reward.id);
      setLocalRewards(prev => prev.filter(r => r.id !== reward.id));
      setDeletingReward(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    }
  };

  const handleUnlock = async (reward: Reward) => {
    try {
      setError(null);
      await unlockReward(reward.id);
      setUnlockingReward(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    }
  };

  return (
    <div>
      {/* Header with Add Button */}
      {canModifySettings && (
        <div className="mb-6 flex justify-between items-center">
          <h2 className="text-2xl font-bold text-gray-900">Rewards</h2>
          <button
            onClick={() => {
              setEditingReward(null);
              setShowModal(true);
              setError(null);
            }}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
          >
            <Plus size={20} />
            Add Reward
          </button>
        </div>
      )}

      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
          <AlertCircle size={20} />
          {error}
        </div>
      )}

      {/* Rewards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {localRewards.map((reward) => (
          <div key={reward.id} className="bg-white rounded-lg shadow-md overflow-hidden">
            <img
              src={reward.image}
              alt={reward.name}
              className="w-full h-48 object-cover"
            />
            <div className="p-6">
              <div className="flex justify-between items-start mb-4">
                <h3 className="text-lg font-semibold">{reward.name}</h3>
                {canModifySettings && (
                  <div className="flex gap-2">
                    <button
                      onClick={() => {
                        setEditingReward(reward);
                        setShowModal(true);
                        setError(null);
                      }}
                      className="p-2 text-gray-600 hover:text-indigo-600 transition-colors rounded-lg hover:bg-gray-100"
                      title="Edit"
                    >
                      <Pencil size={16} />
                    </button>
                    <button
                      onClick={() => setDeletingReward(reward)}
                      className="p-2 text-gray-600 hover:text-red-600 transition-colors rounded-lg hover:bg-gray-100"
                      title="Delete"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                )}
              </div>
              <p className="text-gray-600 mb-4">{reward.description}</p>
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-2 text-gray-600">
                  <Gift size={20} />
                  <span className="font-semibold">{reward.pointsCost} points</span>
                </div>
                <button
                  onClick={() => setUnlockingReward(reward)}
                  disabled={userPoints < reward.pointsCost}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg ${
                    userPoints >= reward.pointsCost
                      ? 'bg-indigo-600 text-white hover:bg-indigo-700'
                      : 'bg-gray-200 text-gray-500 cursor-not-allowed'
                  }`}
                >
                  <Gift size={20} />
                  Unlock
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Modals */}
      <RewardModal
        isOpen={showModal}
        onClose={() => {
          setShowModal(false);
          setEditingReward(null);
          setError(null);
        }}
        onSubmit={handleSubmit}
        initialValues={editingReward || undefined}
        error={error}
      />

      <ConfirmationModal
        isOpen={deletingReward !== null}
        onClose={() => setDeletingReward(null)}
        onConfirm={() => deletingReward && handleDelete(deletingReward)}
        title="Delete Reward"
        message={`Are you sure you want to delete "${deletingReward?.name}"? This action cannot be undone.`}
        confirmLabel="Delete"
        cancelLabel="Cancel"
      />

      <UnlockConfirmationModal
        isOpen={unlockingReward !== null}
        onClose={() => setUnlockingReward(null)}
        onConfirm={() => unlockingReward && handleUnlock(unlockingReward)}
        reward={unlockingReward!}
      />
    </div>
  );
}