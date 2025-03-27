import React, { useState } from 'react';
import { LogOut, LayoutDashboard, AlertCircle, Building, Users, Plus, Pencil, Trash2, UserCircle, Mail, Layers, Settings } from 'lucide-react';
import { usePages } from '../hooks/usePages';
import { useModules } from '../hooks/useModules';
import { useClients } from '../hooks/useClients';
import { useProfiles } from '../hooks/useProfiles';
import { ClientModal } from './admin/ClientModal';
import { ConfirmationModal } from './common/ConfirmationModal';
import { LogoSettings } from './admin/LogoSettings';
import type { Client, Employee } from '../types';
import { supabase } from '../lib/supabase';

interface AdminDashboardProps {
  onLogout: () => void;
}

type ActiveTab = 'clients' | 'users' | 'pages' | 'settings';

export function AdminDashboard({ onLogout }: AdminDashboardProps) {
  const { loading: pagesLoading, error: pagesError, isPageEnabled, togglePage } = usePages();
  const { modules, loading: modulesLoading, error: modulesError, updateModule, movePage } = useModules();
  const { clients: initialClients, loading: clientsLoading, error: clientsError, addClient, updateClient, deleteClient } = useClients();
  const { profiles: initialProfiles, loading: profilesLoading, error: profilesError } = useProfiles();
  const [updating, setUpdating] = useState<string | null>(null);
  const [showClientModal, setShowClientModal] = useState(false);
  const [editingClient, setEditingClient] = useState<{ id: string; name: string } | null>(null);
  const [deletingClient, setDeletingClient] = useState<{ id: string; name: string } | null>(null);
  const [deletingUser, setDeletingUser] = useState<Employee | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<ActiveTab>('pages');
  const [editingModule, setEditingModule] = useState<string | null>(null);
  const [draggedPage, setDraggedPage] = useState<{ name: string; moduleId: string } | null>(null);

  // État local pour les clients et les profils
  const [clients, setClients] = useState<Client[]>(initialClients);
  const [profiles, setProfiles] = useState<Employee[]>(initialProfiles);

  // Mettre à jour l'état local quand les données initiales changent
  React.useEffect(() => {
    setClients(initialClients);
  }, [initialClients]);

  React.useEffect(() => {
    setProfiles(initialProfiles);
  }, [initialProfiles]);

  const handleTogglePage = async (pageName: string, enabled: boolean) => {
    try {
      setUpdating(pageName);
      await togglePage(pageName, enabled);
    } finally {
      setUpdating(null);
    }
  };

  const handleModuleUpdate = async (moduleId: string, name: string, description: string) => {
    try {
      await updateModule(moduleId, name, description);
      setEditingModule(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update module');
    }
  };

  const handleDragStart = (pageName: string, moduleId: string) => {
    setDraggedPage({ name: pageName, moduleId });
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  const handleDrop = async (targetModuleId: string) => {
    if (!draggedPage || draggedPage.moduleId === targetModuleId) return;

    try {
      await movePage(draggedPage.name, draggedPage.moduleId, targetModuleId);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to move page');
    } finally {
      setDraggedPage(null);
    }
  };

  const handleClientSubmit = async (name: string, userIds: string[]) => {
    try {
      setError(null);
      if (editingClient) {
        const updatedClient = { ...editingClient, name };
        setClients(prev => prev.map(c => c.id === editingClient.id ? updatedClient : c));
        
        const oldClientProfiles = profiles.filter(p => p.client_id === editingClient.id);
        const oldUserIds = oldClientProfiles.map(p => p.id);
        
        setProfiles(prev => prev.map(p => {
          if (oldUserIds.includes(p.id) && !userIds.includes(p.id)) {
            return { ...p, client_id: null };
          }
          if (userIds.includes(p.id)) {
            return { ...p, client_id: editingClient.id };
          }
          return p;
        }));

        await updateClient(editingClient.id, name, userIds);
      } else {
        const newClient = await addClient(name, userIds);
        if (newClient) {
          setClients(prev => [...prev, newClient]);
          setProfiles(prev => prev.map(p => 
            userIds.includes(p.id) ? { ...p, client_id: newClient.id } : p
          ));
        }
      }
      setShowClientModal(false);
      setEditingClient(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Une erreur est survenue');
      throw err;
    }
  };

  const handleDeleteClient = async () => {
    if (!deletingClient) return;
    
    try {
      setClients(prev => prev.filter(c => c.id !== deletingClient.id));
      setProfiles(prev => prev.map(p => 
        p.client_id === deletingClient.id ? { ...p, client_id: null } : p
      ));

      await deleteClient(deletingClient.id);
      setDeletingClient(null);
    } catch (err) {
      setClients(initialClients);
      setProfiles(initialProfiles);
      setError(err instanceof Error ? err.message : 'Une erreur est survenue');
    }
  };

  const handleDeleteUser = async () => {
    if (!deletingUser) return;
    
    try {
      // Optimistic update
      setProfiles(prev => prev.filter(p => p.id !== deletingUser.id));

      // Delete from profiles table
      const { error: deleteError } = await supabase
        .from('profiles')
        .delete()
        .eq('id', deletingUser.id);

      if (deleteError) throw deleteError;

      setDeletingUser(null);
    } catch (err) {
      // Revert on error
      setProfiles(initialProfiles);
      setError(err instanceof Error ? err.message : 'Une erreur est survenue');
    }
  };

  if (pagesLoading || clientsLoading || profilesLoading || modulesLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="bg-white shadow">
        <div className="container mx-auto px-4 py-4">
          <div className="flex justify-between items-center">
            <h1 className="text-2xl font-bold">Administration</h1>
            <button
              onClick={onLogout}
              className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
            >
              <LogOut size={20} />
              Déconnexion
            </button>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-8 space-y-8">
        {/* Tabs */}
        <div className="flex gap-4 border-b border-gray-200">
          <button
            onClick={() => setActiveTab('pages')}
            className={`px-4 py-2 font-medium text-sm transition-colors ${
              activeTab === 'pages'
                ? 'text-indigo-600 border-b-2 border-indigo-600'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            Pages
          </button>
          <button
            onClick={() => setActiveTab('clients')}
            className={`px-4 py-2 font-medium text-sm transition-colors ${
              activeTab === 'clients'
                ? 'text-indigo-600 border-b-2 border-indigo-600'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            Clients
          </button>
          <button
            onClick={() => setActiveTab('users')}
            className={`px-4 py-2 font-medium text-sm transition-colors ${
              activeTab === 'users'
                ? 'text-indigo-600 border-b-2 border-indigo-600'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            Users
          </button>
          <button
            onClick={() => setActiveTab('settings')}
            className={`px-4 py-2 font-medium text-sm transition-colors ${
              activeTab === 'settings'
                ? 'text-indigo-600 border-b-2 border-indigo-600'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            Settings
          </button>
        </div>

        {/* Content */}
        {activeTab === 'pages' ? (
          /* Section Pages */
          <div className="bg-white rounded-lg shadow-md p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-xl font-semibold text-gray-900">Pages</h2>
                <p className="text-sm text-gray-600 mt-1">
                  Gérez l'activation des pages de l'application
                </p>
              </div>
            </div>

            {(error || pagesError || modulesError) && (
              <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
                <AlertCircle size={20} />
                {error || pagesError || modulesError}
              </div>
            )}

            <div className="space-y-8">
              {modules.map((module) => (
                <div 
                  key={module.id} 
                  className="space-y-4"
                  onDragOver={handleDragOver}
                  onDrop={() => handleDrop(module.id)}
                >
                  <div className="flex items-center justify-between gap-4">
                    {editingModule === module.id ? (
                      <div className="flex-1 space-y-2">
                        <input
                          type="text"
                          defaultValue={module.name}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') {
                              const input = e.currentTarget;
                              handleModuleUpdate(module.id, input.value, module.description);
                            }
                          }}
                          onBlur={(e) => handleModuleUpdate(module.id, e.target.value, module.description)}
                        />
                        <textarea
                          defaultValue={module.description}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                          onBlur={(e) => handleModuleUpdate(module.id, module.name, e.target.value)}
                        />
                      </div>
                    ) : (
                      <div className="flex items-center gap-2">
                        <Layers size={24} className="text-indigo-600" />
                        <div>
                          <h3 className="text-lg font-semibold text-gray-900">{module.name}</h3>
                          <p className="text-sm text-gray-600">{module.description}</p>
                        </div>
                      </div>
                    )}
                    <button
                      onClick={() => setEditingModule(editingModule === module.id ? null : module.id)}
                      className={`p-2 transition-colors rounded-lg hover:bg-gray-50 ${
                        editingModule === module.id 
                          ? 'text-green-600 hover:text-green-700' 
                          : 'text-gray-400 hover:text-indigo-600'
                      }`}
                      title={editingModule === module.id ? 'Sauvegarder' : 'Modifier'}
                    >
                      <Pencil size={16} />
                    </button>
                  </div>
                  <div className="space-y-4 pl-8">
                    {module.pages.map((pageName) => (
                      <div
                        key={pageName}
                        draggable
                        onDragStart={() => handleDragStart(pageName, module.id)}
                        className="flex items-center justify-between p-4 bg-gray-50 rounded-lg cursor-move hover:bg-gray-100 transition-colors"
                      >
                        <div className="flex items-center gap-3">
                          <Layers size={16} className="text-gray-400" />
                          <h3 className="font-medium text-gray-900">{pageName}</h3>
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => handleTogglePage(pageName, !isPageEnabled(pageName))}
                            disabled={updating === pageName}
                            className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                              isPageEnabled(pageName) ? 'bg-indigo-600' : 'bg-gray-200'
                            }`}
                          >
                            <span
                              className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                                isPageEnabled(pageName) ? 'translate-x-6' : 'translate-x-1'
                              }`}
                            />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ) : activeTab === 'clients' ? (
          /* Section Clients */
          <div className="bg-white rounded-lg shadow-md p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-xl font-semibold text-gray-900">Clients</h2>
                <p className="text-sm text-gray-600 mt-1">
                  Gérez les clients et leurs utilisateurs
                </p>
              </div>
              <button
                onClick={() => {
                  setEditingClient(null);
                  setShowClientModal(true);
                  setError(null);
                }}
                className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
              >
                <Plus size={20} />
                Ajouter un client
              </button>
            </div>

            {(error || clientsError) && (
              <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
                <AlertCircle size={20} />
                {error || clientsError}
              </div>
            )}

            <div className="space-y-4">
              {clients.map((client) => {
                const clientUsers = profiles.filter(p => p.client_id === client.id);
                
                return (
                  <div 
                    key={client.id}
                    className="p-4 bg-gray-50 rounded-lg border border-gray-200 hover:border-indigo-200 transition-colors"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-3">
                        <div className="p-2 bg-indigo-100 rounded-lg text-indigo-600">
                          <Building size={24} />
                        </div>
                        <div>
                          <h3 className="text-lg font-semibold">{client.name}</h3>
                          <div className="flex items-center gap-2 text-gray-600 mt-1">
                            <Users size={16} />
                            <span>{clientUsers.length} utilisateurs</span>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => {
                            setEditingClient(client);
                            setShowClientModal(true);
                            setError(null);
                          }}
                          className="p-2 text-gray-600 hover:text-indigo-600 transition-colors rounded-lg hover:bg-white"
                          title="Modifier"
                        >
                          <Pencil size={16} />
                        </button>
                        <button
                          onClick={() => setDeletingClient(client)}
                          className="p-2 text-gray-600 hover:text-red-600 transition-colors rounded-lg hover:bg-white"
                          title="Supprimer"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </div>

                    {/* Liste des utilisateurs */}
                    <div className="mt-4 pl-4 border-l-2 border-gray-200">
                      <h4 className="text-sm font-medium text-gray-700 mb-2">Utilisateurs</h4>
                      <div className="grid gap-2">
                        {clientUsers.map((user) => (
                          <div key={user.id} className="flex items-center gap-2 text-gray-600">
                            <img
                              src={user.avatar}
                              alt={user.name}
                              className="w-6 h-6 rounded-full object-cover"
                            />
                            <span>{user.name}</span>
                            <span className="text-gray-400">•</span>
                            <span className="text-sm">{user.email}</span>
                          </div>
                        ))}
                        {clientUsers.length === 0 && (
                          <p className="text-sm text-gray-500">
                            Aucun utilisateur associé
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}

              {clients.length === 0 && (
                <div className="text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
                  <Building size={40} className="mx-auto text-gray-400 mb-4" />
                  <h3 className="font-medium text-gray-900 mb-1">
                    Aucun client
                  </h3>
                  <p className="text-sm text-gray-600 mb-4">
                    Commencez par ajouter votre premier client
                  </p>
                  <button
                    onClick={() => {
                      setEditingClient(null);
                      setShowClientModal(true);
                      setError(null);
                    }}
                    className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
                  >
                    <Plus size={20} />
                    Ajouter un client
                  </button>
                </div>
              )}
            </div>
          </div>
        ) : activeTab === 'users' ? (
          /* Section Users */
          <div className="bg-white rounded-lg shadow-md p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-xl font-semibold text-gray-900">Users</h2>
                <p className="text-sm text-gray-600 mt-1">
                  {profiles.length} user{profiles.length !== 1 ? 's' : ''} total
                </p>
              </div>
            </div>

            {(error || profilesError) && (
              <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
                <AlertCircle size={20} />
                {error || profilesError}
              </div>
            )}

            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">User</th>
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Email</th>
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Department</th>
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Client</th>
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {profiles.map((user) => {
                    const userClient = clients.find(c => c.id === user.client_id);
                    
                    return (
                      <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-3">
                            <img
                              src={user.avatar}
                              alt={user.name}
                              className="w-8 h-8 rounded-full object-cover"
                            />
                            <span className="font-medium text-gray-900">{user.name}</span>
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2 text-gray-600">
                            <Mail size={16} />
                            {user.email}
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2 text-gray-600">
                            <UserCircle size={16} />
                            {user.department}
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2 text-gray-600">
                            <Building size={16} />
                            {userClient?.name || 'No client'}
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <button
                            onClick={() => setDeletingUser(user)}
                            className="p-2 text-gray-400 hover:text-red-600 transition-colors rounded-lg hover:bg-gray-100"
                            title="Delete user"
                          >
                            <Trash2 size={16} />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>

              {profiles.length === 0 && (
                <div className="text-center py-12">
                  <Users size={40} className="mx-auto text-gray-400 mb-4" />
                  <h3 className="font-medium text-gray-900 mb-1">
                    No users found
                  </h3>
                  <p className="text-sm text-gray-600">
                    Users will appear here once they are created
                  </p>
                </div>
              )}
            </div>
          </div>
        ) : (
          /* Section Settings */
          <LogoSettings />
        )}
      </div>

      {/* Modals */}
      <ClientModal
        isOpen={showClientModal}
        onClose={() => {
          setShowClientModal(false);
          setEditingClient(null);
          setError(null);
        }}
        onSubmit={handleClientSubmit}
        initialValues={editingClient || undefined}
        error={error}
      />

      <ConfirmationModal
        isOpen={deletingClient !== null}
        onClose={() => setDeletingClient(null)}
        onConfirm={handleDeleteClient}
        title="Supprimer le client"
        message={`Êtes-vous sûr de vouloir supprimer le client "${deletingClient?.name}" ? Cette action est irréversible et supprimera également tous les utilisateurs associés.`}
        confirmLabel="Supprimer"
        cancelLabel="Annuler"
        type="danger"
      />

      <ConfirmationModal
        isOpen={deletingUser !== null}
        onClose={() => setDeletingUser(null)}
        onConfirm={handleDeleteUser}
        title="Delete User"
        message={`Are you sure you want to delete the user "${deletingUser?.name}"? This action cannot be undone.`}
        confirmLabel="Delete"
        cancelLabel="Cancel"
        type="danger"
      />
    </div>
  );
}