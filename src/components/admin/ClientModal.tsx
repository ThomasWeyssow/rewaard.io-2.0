import React, { useState, useEffect } from 'react';
import { AlertCircle, Search, Users, UserPlus, X } from 'lucide-react';
import { useProfiles } from '../../hooks/useProfiles';

interface ClientModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (name: string, userIds: string[]) => Promise<void>;
  initialValues?: {
    id: string;
    name: string;
  };
  error?: string | null;
}

export function ClientModal({
  isOpen,
  onClose,
  onSubmit,
  initialValues,
  error
}: ClientModalProps) {
  const { profiles } = useProfiles();
  const [name, setName] = useState(initialValues?.name || '');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUserIds, setSelectedUserIds] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);

  // Réinitialiser les états quand le modal s'ouvre/se ferme ou quand initialValues change
  useEffect(() => {
    if (initialValues) {
      setName(initialValues.name);
      // Récupérer les utilisateurs déjà associés au client
      const clientUsers = profiles.filter(p => p.client_id === initialValues.id);
      setSelectedUserIds(clientUsers.map(u => u.id));
    } else {
      setName('');
      setSelectedUserIds([]);
    }
    setSearchQuery('');
  }, [initialValues, profiles]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    try {
      setSaving(true);
      await onSubmit(name.trim(), selectedUserIds);
    } catch (err) {
      // Error is handled by parent component
    } finally {
      setSaving(false);
    }
  };

  // Obtenir tous les utilisateurs disponibles (non assignés ou appartenant au client en cours)
  const availableUsers = profiles.filter(user => 
    !selectedUserIds.includes(user.id) && // Exclure les utilisateurs déjà sélectionnés
    (!user.client_id || (initialValues && user.client_id === initialValues.id))
  );

  // Filtrer les utilisateurs disponibles en fonction de la recherche
  const filteredUsers = availableUsers.filter(user => 
    user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    user.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
    user.department.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Obtenir les utilisateurs sélectionnés
  const selectedUsers = profiles.filter(user => selectedUserIds.includes(user.id));

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <h3 className="text-lg font-semibold mb-4">
          {initialValues ? 'Modifier le client' : 'Ajouter un client'}
        </h3>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2">
            <AlertCircle size={16} />
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nom du client
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Ex: Redspher"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-4">
              Utilisateurs associés
            </label>

            {/* Liste des utilisateurs sélectionnés */}
            <div className="mb-4">
              <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
                <Users size={16} />
                <span>{selectedUsers.length} utilisateur{selectedUsers.length !== 1 ? 's' : ''} sélectionné{selectedUsers.length !== 1 ? 's' : ''}</span>
              </div>
              <div className="space-y-2">
                {selectedUsers.map(user => (
                  <div
                    key={user.id}
                    className="flex items-center justify-between p-2 bg-indigo-50 rounded-lg"
                  >
                    <div className="flex items-center gap-3">
                      <img
                        src={user.avatar}
                        alt={user.name}
                        className="w-8 h-8 rounded-full object-cover"
                      />
                      <div>
                        <div className="font-medium text-gray-900">{user.name}</div>
                        <div className="text-sm text-gray-600">{user.email}</div>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => setSelectedUserIds(prev => prev.filter(id => id !== user.id))}
                      className="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-white transition-colors"
                      title="Retirer"
                    >
                      <X size={16} />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Recherche d'utilisateurs */}
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-5 w-5 text-gray-400" />
              </div>
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Rechercher un utilisateur..."
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>

            {/* Liste des utilisateurs disponibles */}
            <div className="mt-2 border border-gray-200 rounded-lg divide-y max-h-60 overflow-y-auto">
              {(searchQuery ? filteredUsers : availableUsers).map(user => (
                <button
                  key={user.id}
                  type="button"
                  onClick={() => {
                    setSelectedUserIds(prev => [...prev, user.id]);
                    setSearchQuery('');
                  }}
                  className="w-full flex items-center gap-3 p-2 hover:bg-gray-50 transition-colors text-left"
                >
                  <img
                    src={user.avatar}
                    alt={user.name}
                    className="w-8 h-8 rounded-full object-cover"
                  />
                  <div>
                    <div className="font-medium text-gray-900">{user.name}</div>
                    <div className="text-sm text-gray-600">{user.email}</div>
                  </div>
                  <UserPlus size={16} className="ml-auto text-gray-400" />
                </button>
              ))}
              {searchQuery && filteredUsers.length === 0 && (
                <div className="p-4 text-center text-gray-500">
                  Aucun utilisateur trouvé
                </div>
              )}
              {!searchQuery && availableUsers.length === 0 && (
                <div className="p-4 text-center text-gray-500">
                  Aucun utilisateur disponible
                </div>
              )}
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-4 border-t">
            <button
              type="button"
              onClick={onClose}
              disabled={saving}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={saving || !name.trim()}
              className={`px-4 py-2 text-white rounded-lg transition-colors ${
                saving || !name.trim()
                  ? 'bg-indigo-400 cursor-not-allowed'
                  : 'bg-indigo-600 hover:bg-indigo-700'
              }`}
            >
              {saving ? 'Enregistrement...' : 'Enregistrer'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}