import React, { useRef, useState } from 'react';
import { Download, Upload, AlertCircle, UserPlus } from 'lucide-react';
import { Employee } from '../../types';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';

interface EmployeeManagementSectionProps {
  currentEmployees: Employee[];
  onUpdateEmployees: (employees: Employee[]) => void;
}

export function EmployeeManagementSection({ currentEmployees, onUpdateEmployees }: EmployeeManagementSectionProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const csvInputRef = useRef<HTMLInputElement>(null);
  const [error, setError] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const { user } = useAuth();

  // Récupérer le client_id de l'utilisateur connecté
  const userClientId = currentEmployees.find(emp => emp.id === user?.id)?.client_id;

  // Filtrer les employés par client_id
  const clientEmployees = userClientId 
    ? currentEmployees.filter(emp => emp.client_id === userClientId)
    : [];

  const handleAddEmployee = async (email: string, firstName: string, lastName: string, department: string) => {
    try {
      setError('');
      setLoading(true);

      // 1. Créer l'utilisateur avec signUp
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email,
        password: 'ChangeMe123!', // Mot de passe temporaire
        options: {
          data: {
            first_name: firstName,
            last_name: lastName,
            department
          }
        }
      });

      if (authError) throw authError;
      if (!authData.user) throw new Error('No user data returned');

      // 2. Créer le profil
      const { error: profileError } = await supabase
        .from('profiles')
        .insert([{
          id: authData.user.id,
          email,
          first_name: firstName,
          last_name: lastName,
          department,
          client_id: userClientId,
          points: 0,
          avatar_url: `https://api.dicebear.com/7.x/avatars/svg?seed=${authData.user.id}`
        }]);

      if (profileError) {
        // Si la création du profil échoue, supprimer l'utilisateur
        await supabase.auth.admin.deleteUser(authData.user.id);
        throw profileError;
      }

      // 3. Ajouter le rôle "User"
      const { data: roleData } = await supabase
        .from('roles')
        .select('id')
        .eq('name', 'User')
        .single();

      if (roleData) {
        const { error: roleAssignError } = await supabase
          .from('profile_roles')
          .insert([{
            profile_id: authData.user.id,
            role_id: roleData.id
          }]);

        if (roleAssignError) throw roleAssignError;
      }

      // 4. Rafraîchir la liste des employés
      await onUpdateEmployees(currentEmployees);
      setShowAddModal(false);

    } catch (err) {
      setError(err instanceof Error ? err.message : "Error adding employee");
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadEmployees = () => {
    const headers = ['first_name', 'last_name', 'email', 'points', 'department'];
    
    const employeesData = currentEmployees.map(emp => [
      emp.first_name,
      emp.last_name,
      emp.email,
      emp.points,
      emp.department
    ]);

    const csvContent = [
      headers.join(','),
      ...employeesData.map(row => row.join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'employees.csv';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const handlePhotoUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        setError("Image size must not exceed 5MB");
        return;
      }
      
      const reader = new FileReader();
      reader.onloadend = () => {
        console.log('Photo uploaded:', file.name);
        setError('');
      };
      reader.readAsDataURL(file);
    }
  };

  const handleCsvImport = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = async (e) => {
        try {
          setLoading(true);
          const text = e.target?.result as string;
          const lines = text.split('\n').filter(line => line.trim() !== '');
          const headers = lines[0].toLowerCase().split(',').map(h => h.trim());
          
          // Vérifier les colonnes requises
          const requiredHeaders = ['first_name', 'last_name', 'email', 'department'];
          const missingHeaders = requiredHeaders.filter(h => !headers.includes(h));
          
          if (missingHeaders.length > 0) {
            setError(`Missing columns: ${missingHeaders.join(', ')}`);
            return;
          }

          if (!userClientId) {
            setError("Impossible d'importer des utilisateurs : client non trouvé");
            return;
          }

          // Trouver l'index de chaque colonne
          const firstNameIndex = headers.indexOf('first_name');
          const lastNameIndex = headers.indexOf('last_name');
          const emailIndex = headers.indexOf('email');
          const departmentIndex = headers.indexOf('department');
          const pointsIndex = headers.indexOf('points');

          // Récupérer le rôle "User"
          const { data: roleData, error: roleError } = await supabase
            .from('roles')
            .select('id')
            .eq('name', 'User')
            .single();

          if (roleError) throw roleError;

          // Traiter chaque ligne
          for (const line of lines.slice(1)) {
            const values = line.split(',').map(v => v.trim());
            const email = values[emailIndex];
            const firstName = values[firstNameIndex];
            const lastName = values[lastNameIndex];
            const department = values[departmentIndex];
            const points = pointsIndex >= 0 ? parseInt(values[pointsIndex]) || 0 : 0;

            // Vérifier si l'email existe déjà
            const { data: existingUser } = await supabase
              .from('profiles')
              .select('id')
              .eq('email', email)
              .single();

            if (existingUser) {
              console.log(`Skipping existing user: ${email}`);
              continue;
            }

            // 1. Créer l'utilisateur avec signUp
            const { data: authData, error: authError } = await supabase.auth.signUp({
              email,
              password: 'ChangeMe123!', // Mot de passe temporaire
              options: {
                data: {
                  first_name: firstName,
                  last_name: lastName,
                  department
                }
              }
            });

            if (authError) {
              console.error(`Error creating user ${email}:`, authError);
              continue;
            }

            if (!authData.user) {
              console.error(`No user data returned for ${email}`);
              continue;
            }

            // 2. Créer le profil
            const { error: profileError } = await supabase
              .from('profiles')
              .insert([{
                id: authData.user.id,
                email,
                first_name: firstName,
                last_name: lastName,
                department,
                client_id: userClientId,
                points,
                avatar_url: `https://api.dicebear.com/7.x/avatars/svg?seed=${authData.user.id}`
              }]);

            if (profileError) {
              console.error(`Error creating profile for ${email}:`, profileError);
              // Supprimer l'utilisateur en cas d'erreur
              await supabase.auth.admin.deleteUser(authData.user.id);
              continue;
            }

            // 3. Ajouter le rôle "User"
            const { error: roleAssignError } = await supabase
              .from('profile_roles')
              .insert([{
                profile_id: authData.user.id,
                role_id: roleData.id
              }]);

            if (roleAssignError) {
              console.error(`Error assigning role for ${email}:`, roleAssignError);
              continue;
            }
          }

          // Rafraîchir la liste des profils
          await onUpdateEmployees(currentEmployees);
          setError('');
          alert('Import completed successfully. Check the console for any skipped users.');

        } catch (err) {
          setError(err instanceof Error ? err.message : "Error importing CSV file");
        } finally {
          setLoading(false);
          // Reset the file input
          if (csvInputRef.current) {
            csvInputRef.current.value = '';
          }
        }
      };
      reader.readAsText(file);
    }
  };

  return (
    <div className="bg-white rounded-2xl shadow-md overflow-hidden p-10">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-3xl font-bold text-gray-900">👥 User Management</h2>
          <p className="text-sm text-gray-700 mt-4">Add a single user, upload users in bulk and export your user list.</p>
        </div>
      </div>

      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
          <AlertCircle size={20} />
          {error}
        </div>
      )}

      {/* Modal d'ajout d'employé */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full">
            <h3 className="text-lg font-semibold mb-4">Add single user</h3>
            <form onSubmit={(e) => {
              e.preventDefault();
              const formData = new FormData(e.currentTarget);
              handleAddEmployee(
                formData.get('email') as string,
                formData.get('first_name') as string,
                formData.get('last_name') as string,
                formData.get('department') as string
              );
            }}>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    First name
                  </label>
                  <input
                    type="text"
                    name="first_name"
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Last name
                  </label>
                  <input
                    type="text"
                    name="last_name"
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Work email
                  </label>
                  <input
                    type="email"
                    name="email"
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Department
                  </label>
                  <select
                    name="department"
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="">Select department</option>
                    <option value="Marketing">Marketing</option>
                    <option value="Development">Development</option>
                    <option value="Design">Design</option>
                    <option value="HR">Human Resources</option>
                    <option value="Sales">Sales</option>
                    <option value="Admin">Administration</option>
                  </select>
                </div>
              </div>

              <div className="flex justify-end gap-3 mt-6">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className={`px-4 py-2 text-white rounded-lg transition-colors ${
                    loading ? 'bg-violet-400 cursor-not-allowed' : 'bg-violet-600 hover:bg-violet-700'
                  }`}
                >
                  {loading ? 'Adding...' : 'Add user'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      
      <div className="space-y-6">
        <div>
          <p className="text-gray-600 mb-4">
            Export users
            <br />
            <span className="text-sm text-gray-500">
              Download a CSV file with all users
            </span>
          </p>
          <button
            onClick={handleDownloadEmployees}
            className="flex items-center gap-2 px-4 py-2 bg-[#4F03C1] text-[#FEFEFF] text-semibold rounded-lg hover:bg-[#3B0290] transition-colors"
          >
            <Download size={20} />
            Export users
          </button>
        </div>

        <div className="border-t pt-6">
        <p className="text-gray-600 mb-4">
          Add single user
          <br />
          <span className="text-sm text-gray-500">
          Manually add a new user by entering their details. Perfect for adding individual team members quickly and easily
          </span>
        </p>
        <button
          onClick={() => {
            setShowAddModal(true);
            setError(null);
          }}
          className="flex items-center gap-2 px-4 py-2 bg-[#4F03C1] text-[#FEFEFF] text-semibold rounded-lg hover:bg-[#3B0290] transition-colors"
        >
          <UserPlus size={20} />
          Add single user
        </button>
        </div>

        <div className="border-t pt-6">
          <p className="text-gray-600 mb-4">
            Bulk user import
            <br />
            <span className="text-sm text-gray-500">
              Easily add multiple users at once by uploading a CSV file. Required file format: first_name, last_name, email, department, points (optional)
            </span>
          </p>
          <input
            type="file"
            ref={csvInputRef}
            onChange={handleCsvImport}
            accept=".csv"
            className="hidden"
          />
          <button
            onClick={() => csvInputRef.current?.click()}
            disabled={loading}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${
              loading
                ? 'bg-[#4F03C1] cursor-not-allowed'
                : 'bg-[#4F03C1] hover:bg-[#3B0290] text-[#FEFEFF]'
            }`}
          >
            <Upload size={20} />
            {loading ? 'Importing...' : 'Import users'}
          </button>
        </div>
      </div>
    </div>
  );
}