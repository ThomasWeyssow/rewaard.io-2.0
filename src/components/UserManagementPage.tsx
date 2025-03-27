import React, { useState } from 'react';
import { useProfiles } from '../hooks/useProfiles';
import { usePermissions } from '../hooks/usePermissions';
import { Mail, Building, Shield, Plus, X, AlertCircle, Lock } from 'lucide-react';
import type { Role } from '../types';
import { useAuth } from '../hooks/useAuth';

export function UserManagementPage() {
  const { user } = useAuth();
  const { profiles, loading: profilesLoading, error: profileError, addRole, removeRole } = useProfiles();
  const { canViewUserPage, canUpdateUserRoles, loading: permissionsLoading } = usePermissions();
  const [error, setError] = useState<string | null>(null);
  const [processing, setProcessing] = useState<string | null>(null);

  // Récupérer le client_id de l'utilisateur connecté
  const currentUserProfile = profiles.find(p => p.id === user?.id);
  const userClientId = currentUserProfile?.client_id;

  // Filtrer les utilisateurs qui ont le même client_id
  const filteredProfiles = userClientId 
    ? profiles.filter(profile => profile.client_id === userClientId)
    : [];

  // Wait for permissions to load before checking access
  if (permissionsLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  if (!canViewUserPage) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
        <Lock size={48} className="text-gray-400" />
        <div className="text-xl font-semibold text-gray-600">Access Denied</div>
        <p className="text-gray-500">You don't have permission to view this page.</p>
      </div>
    );
  }

  const getRoleColor = (role: Role) => {
    switch (role.name) {
      case 'Admin':
        return 'bg-amber-100 text-amber-700';
      case 'ExCom':
        return 'bg-purple-100 text-purple-700';
      case 'User':
        return 'bg-blue-100 text-blue-700';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  const handleAddRole = async (userId: string, roleName: 'ExCom' | 'Admin') => {
    if (!canUpdateUserRoles) return;
    try {
      setError(null);
      setProcessing(`add-${userId}-${roleName}`);
      await addRole(userId, roleName);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setProcessing(null);
    }
  };

  const handleRemoveRole = async (userId: string, roleName: 'ExCom' | 'Admin') => {
    if (!canUpdateUserRoles) return;
    try {
      setError(null);
      setProcessing(`remove-${userId}-${roleName}`);
      await removeRole(userId, roleName);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setProcessing(null);
    }
  };

  if (profilesLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-gray-600">Loading users...</div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto">
      <div className="bg-white rounded-2xl shadow-md overflow-hidden">
        <div className="p-10">
          <div className="flex justify-between items-center mb-10">
            <div>
              <h2 className="text-3xl font-semibold text-gray-900 mb-3">User list</h2>
              <p className="text-sm text-gray-600 mt-1">
                Your organization has {filteredProfiles.length} active user{filteredProfiles.length !== 1 ? 's' : ''}
              </p>
            </div>
          </div>
          
          {(error || profileError) && (
            <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
              <AlertCircle size={20} />
              {error || (profileError instanceof Error ? profileError.message : 'An error occurred')}
            </div>
          )}
          
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-900">User</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-900">Email</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-900">Department</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-900">Roles</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredProfiles.map((user) => {
                  const hasAdminRole = user.roles.some(role => role.name === 'Admin');
                  const hasExComRole = user.roles.some(role => role.name === 'ExCom');

                  return (
                    <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <img
                            src={user.avatar}
                            alt={user.name}
                            className="w-10 h-10 rounded-full object-cover"
                          />
                          <span className="font-medium text-sm text-gray-900">{user.name}</span>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-2 text-gray-600 text-sm">
                          <Mail size={16} />
                          {user.email}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-2 text-gray-600 text-sm">
                          <Building size={16} />
                          {user.department}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex flex-wrap items-center gap-2">
                          {/* Always show User role */}
                          <span
                            className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700"
                          >
                            <Shield size={12} />
                            User
                          </span>

                          {/* ExCom Role */}
                          {hasExComRole ? (
                            <button
                              onClick={() => handleRemoveRole(user.id, 'ExCom')}
                              disabled={!canUpdateUserRoles || !!processing}
                              className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700 ${
                                canUpdateUserRoles ? 'hover:bg-purple-200' : 'opacity-60 cursor-not-allowed'
                              } transition-colors`}
                            >
                              <Shield size={12} />
                              Approver
                              {canUpdateUserRoles && <X size={12} className="ml-1" />}
                            </button>
                          ) : (
                            canUpdateUserRoles && (
                              <button
                                onClick={() => handleAddRole(user.id, 'ExCom')}
                                disabled={!!processing}
                                className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600 hover:bg-gray-200 transition-colors"
                              >
                                <Plus size={12} />
                                Approver
                              </button>
                            )
                          )}

                          {/* Admin Role */}
                          {hasAdminRole ? (
                            <button
                              onClick={() => handleRemoveRole(user.id, 'Admin')}
                              disabled={!canUpdateUserRoles || !!processing}
                              className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700 ${
                                canUpdateUserRoles ? 'hover:bg-amber-200' : 'opacity-60 cursor-not-allowed'
                              } transition-colors`}
                            >
                              <Shield size={12} />
                              Admin
                              {canUpdateUserRoles && <X size={12} className="ml-1" />}
                            </button>
                          ) : (
                            canUpdateUserRoles && (
                              <button
                                onClick={() => handleAddRole(user.id, 'Admin')}
                                disabled={!!processing}
                                className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600 hover:bg-gray-200 transition-colors"
                              >
                                <Plus size={12} />
                                Admin
                              </button>
                            )
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}