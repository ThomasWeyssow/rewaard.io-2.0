import { useAuth } from './useAuth';
import { useProfiles } from './useProfiles';

interface Permissions {
  canAccessUserPage: boolean;
  canViewUserPage: boolean;
  canUpdateUserRoles: boolean;
  canAccessReviewPage: boolean;
  canValidateNominations: boolean;
  canAccessSettingsPage: boolean;
  canModifySettings: boolean;
  loading: boolean;
}

export function usePermissions() {
  const { user } = useAuth();
  const { profiles, loading: profilesLoading } = useProfiles();

  const currentUser = user ? profiles.find(p => p.id === user.id) : null;
  const userRoles = currentUser?.roles.map(r => r.name) || [];

  const permissions: Permissions = {
    // User Management permissions
    canAccessUserPage: userRoles.includes('Admin'),
    canViewUserPage: userRoles.includes('Admin'),
    canUpdateUserRoles: userRoles.includes('Admin'),

    // Review page permissions
    canAccessReviewPage: userRoles.includes('Admin') || userRoles.includes('ExCom'),
    canValidateNominations: userRoles.includes('ExCom'),

    // Settings page permissions
    canAccessSettingsPage: userRoles.includes('Admin'),
    canModifySettings: userRoles.includes('Admin'),

    // Loading state
    loading: profilesLoading
  };

  return permissions;
}