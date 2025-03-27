import React, { useState, useEffect } from 'react';
import { AlertCircle } from 'lucide-react';
import type { Client, Module } from '../../types';

interface EditClientModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (name: string, moduleStates: Record<string, boolean>) => Promise<void>;
  client: Client | null;
  modules: Module[];
  initialModuleStates: Record<string, boolean>;
  error?: string | null;
}

export function EditClientModal({
  isOpen,
  onClose,
  onSubmit,
  client,
  modules,
  initialModuleStates,
  error
}: EditClientModalProps) {
  const [name, setName] = useState(client?.name || '');
  const [moduleStates, setModuleStates] = useState<Record<string, boolean>>(initialModuleStates);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (client) {
      setName(client.name);
      setModuleStates(initialModuleStates);
    }
  }, [client, initialModuleStates]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    try {
      setSaving(true);
      await onSubmit(name.trim(), moduleStates);
      onClose();
    } catch (err) {
      // Error is handled by parent component
    } finally {
      setSaving(false);
    }
  };

  const handleCancel = () => {
    setName(client?.name || '');
    setModuleStates(initialModuleStates);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full">
        <h3 className="text-lg font-semibold mb-4">
          Modifier {client?.name}
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
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Modules activés
            </label>
            <div className="space-y-3">
              {modules.map((module) => (
                <label
                  key={module.id}
                  className={`flex items-start gap-3 p-3 rounded-lg border cursor-pointer transition-colors ${
                    moduleStates[module.id]
                      ? 'bg-indigo-50 border-indigo-200'
                      : 'bg-gray-50 border-gray-200 hover:bg-gray-100'
                  }`}
                >
                  <input
                    type="checkbox"
                    className="mt-1"
                    checked={moduleStates[module.id] || false}
                    onChange={(e) => setModuleStates(prev => ({
                      ...prev,
                      [module.id]: e.target.checked
                    }))}
                  />
                  <div>
                    <div className="font-medium text-gray-900">{module.description}</div>
                    <ul className="mt-1 space-y-1">
                      {module.features.map((feature, index) => (
                        <li key={index} className="text-sm text-gray-600">
                          • {feature}
                        </li>
                      ))}
                    </ul>
                  </div>
                </label>
              ))}
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={handleCancel}
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