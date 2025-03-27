import React, { useState } from 'react';
import { Employee, Badge } from '../types';
import { Award, Plus, HeartHandshake, Clock, Lightbulb, Users, X, Search, ArrowUpDown } from 'lucide-react';
import { badges } from '../data';
import { useProfiles } from '../hooks/useProfiles';

interface EmployeeListProps {
  employees: Employee[];
  onGivePoints: (employeeId: string) => void;
}

type SortOption = 'name-asc' | 'name-desc' | 'points-asc' | 'points-desc';

export function EmployeeList({ employees, onGivePoints }: EmployeeListProps) {
  const [selectedEmployee, setSelectedEmployee] = useState<string | null>(null);
  const [showBadgeModal, setShowBadgeModal] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [sortOption, setSortOption] = useState<SortOption>('name-asc');
  const { addBadge, removeBadge } = useProfiles();
  
  // État local pour les badges
  const [localBadges, setLocalBadges] = useState<{ [key: string]: Badge[] }>(() => {
    const initialBadges: { [key: string]: Badge[] } = {};
    employees.forEach(emp => {
      initialBadges[emp.id] = emp.badges;
    });
    return initialBadges;
  });

  // État local pour les points
  const [localPoints, setLocalPoints] = useState<{ [key: string]: number }>(() => {
    const initialPoints: { [key: string]: number } = {};
    employees.forEach(emp => {
      initialPoints[emp.id] = emp.points;
    });
    return initialPoints;
  });

  // Initialisation unique des états locaux
  React.useEffect(() => {
    const initialBadges: { [key: string]: Badge[] } = {};
    const initialPoints: { [key: string]: number } = {};
    
    employees.forEach(emp => {
      if (!localBadges[emp.id]) {
        initialBadges[emp.id] = emp.badges;
      }
      if (!localPoints[emp.id]) {
        initialPoints[emp.id] = emp.points;
      }
    });

    if (Object.keys(initialBadges).length > 0) {
      setLocalBadges(prev => ({ ...prev, ...initialBadges }));
    }
    if (Object.keys(initialPoints).length > 0) {
      setLocalPoints(prev => ({ ...prev, ...initialPoints }));
    }
  }, []); // Ne s'exécute qu'une fois à l'initialisation

  const getBadgeColor = (color: string) => {
    const colors: { [key: string]: string } = {
      emerald: 'bg-emerald-100 text-emerald-800',
      blue: 'bg-blue-100 text-blue-800',
      amber: 'bg-amber-100 text-amber-800',
      purple: 'bg-purple-100 text-purple-800'
    };
    return colors[color] || 'bg-gray-100 text-gray-800';
  };

  const getBadgeIcon = (iconName: string) => {
    const icons: { [key: string]: React.ComponentType } = {
      'heart-handshake': HeartHandshake,
      'clock': Clock,
      'lightbulb': Lightbulb,
      'users': Users
    };
    return icons[iconName] || Award;
  };

  const handleGivePoints = async (employeeId: string) => {
    try {
      setError(null);
      const currentPoints = localPoints[employeeId] || 0;
      const newPoints = currentPoints + 100;
      
      // Mise à jour optimiste des points
      setLocalPoints(prev => ({
        ...prev,
        [employeeId]: newPoints
      }));

      await onGivePoints(employeeId);
    } catch (error) {
      // En cas d'erreur, restaurer l'état précédent
      const employee = employees.find(emp => emp.id === employeeId);
      if (employee) {
        setLocalPoints(prev => ({
          ...prev,
          [employeeId]: employee.points
        }));
      }
      console.error('Error giving points:', error);
      setError('Une erreur est survenue lors de l\'attribution des points');
    }
  };

  const handleAddBadge = async (employeeId: string, badge: Badge) => {
    try {
      setError(null);
      
      // Mise à jour optimiste du state local des badges
      setLocalBadges(prev => ({
        ...prev,
        [employeeId]: [...(prev[employeeId] || []), badge]
      }));

      await addBadge(employeeId, badge.id);
      setShowBadgeModal(false);
      setSelectedEmployee(null);
    } catch (err) {
      // En cas d'erreur, restaurer l'état précédent
      setLocalBadges(prev => ({
        ...prev,
        [employeeId]: prev[employeeId].filter(b => b.id !== badge.id)
      }));
      const errorMessage = err instanceof Error ? err.message : 'Une erreur est survenue lors de l\'ajout du badge';
      setError(errorMessage);
    }
  };

  const handleRemoveBadge = async (employeeId: string, badgeId: string) => {
    try {
      setError(null);
      const currentBadges = localBadges[employeeId] || [];
      const badgeToRemove = currentBadges.find(b => b.id === badgeId);
      
      // Mise à jour optimiste du state local des badges
      setLocalBadges(prev => ({
        ...prev,
        [employeeId]: prev[employeeId].filter(b => b.id !== badgeId)
      }));

      await removeBadge(employeeId, badgeId);
    } catch (err) {
      // En cas d'erreur, restaurer l'état précédent
      if (badgeToRemove) {
        setLocalBadges(prev => ({
          ...prev,
          [employeeId]: [...prev[employeeId], badgeToRemove]
        }));
      }
      const errorMessage = err instanceof Error ? err.message : 'Une erreur est survenue lors de la suppression du badge';
      setError(errorMessage);
    }
  };

  // Filtrer et trier les employés
  const filteredAndSortedEmployees = React.useMemo(() => {
    let result = [...employees];

    // Filtrer par recherche
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      result = result.filter(emp => 
        `${emp.first_name} ${emp.last_name}`.toLowerCase().includes(query)
      );
    }

    // Trier selon l'option sélectionnée
    result.sort((a, b) => {
      switch (sortOption) {
        case 'name-asc':
          return `${a.first_name} ${a.last_name}`.localeCompare(`${b.first_name} ${b.last_name}`);
        case 'name-desc':
          return `${b.first_name} ${b.last_name}`.localeCompare(`${a.first_name} ${a.last_name}`);
        case 'points-asc':
          return (localPoints[a.id] || 0) - (localPoints[b.id] || 0);
        case 'points-desc':
          return (localPoints[b.id] || 0) - (localPoints[a.id] || 0);
        default:
          return 0;
      }
    });

    return result;
  }, [employees, searchQuery, sortOption, localPoints]);

  const BadgeModal = () => {
    if (!selectedEmployee) return null;
    const employee = employees.find(emp => emp.id === selectedEmployee);
    if (!employee) return null;

    const employeeBadgeIds = localBadges[employee.id]?.map(b => b.id) || [];
    const availableBadges = badges.filter(
      badge => !employeeBadgeIds.includes(badge.id)
    );

    if (availableBadges.length === 0) {
      return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full">
            <h3 className="text-lg font-semibold mb-4">Ajouter un badge à {employee.first_name} {employee.last_name}</h3>
            <p className="text-gray-600 mb-4">
              Cet employé possède déjà tous les badges disponibles.
            </p>
            <button
              onClick={() => {
                setShowBadgeModal(false);
                setSelectedEmployee(null);
                setError(null);
              }}
              className="w-full px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
            >
              Fermer
            </button>
          </div>
        </div>
      );
    }

    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div className="bg-white rounded-lg p-6 max-w-md w-full">
          <h3 className="text-lg font-semibold mb-4">Ajouter un badge à {employee.first_name} {employee.last_name}</h3>
          
          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
              {error}
            </div>
          )}

          <div className="space-y-3">
            {availableBadges.map(badge => {
              const IconComponent = getBadgeIcon(badge.icon);
              return (
                <button
                  key={badge.id}
                  onClick={() => handleAddBadge(employee.id, badge)}
                  className={`w-full flex items-center gap-3 p-3 rounded-lg ${getBadgeColor(badge.color)} hover:opacity-90 transition-opacity`}
                >
                  <IconComponent size={20} />
                  <div className="text-left">
                    <div className="font-medium">{badge.name}</div>
                    <div className="text-sm opacity-75">{badge.description}</div>
                  </div>
                </button>
              );
            })}
          </div>
          <button
            onClick={() => {
              setShowBadgeModal(false);
              setSelectedEmployee(null);
              setError(null);
            }}
            className="mt-4 w-full px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Fermer
          </button>
        </div>
      </div>
    );
  };

  return (
    <div>
      {/* Barre de filtres */}
      <div className="mb-6 flex flex-col sm:flex-row gap-4">
        <div className="flex-1 relative">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="h-5 w-5 text-gray-400" />
          </div>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Rechercher un employé..."
            className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
        </div>
        <div className="sm:w-64">
          <div className="relative">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <ArrowUpDown className="h-5 w-5 text-gray-400" />
            </div>
            <select
              value={sortOption}
              onChange={(e) => setSortOption(e.target.value as SortOption)}
              className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 appearance-none"
            >
              <option value="name-asc">Nom (A-Z)</option>
              <option value="name-desc">Nom (Z-A)</option>
              <option value="points-asc">Points (croissant)</option>
              <option value="points-desc">Points (décroissant)</option>
            </select>
          </div>
        </div>
      </div>

      {/* Liste des employés */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredAndSortedEmployees.map((employee) => (
          <div key={employee.id} className="bg-white rounded-lg shadow-md p-6">
            <div className="flex items-center gap-4">
              <img
                src={employee.avatar}
                alt={`${employee.first_name} ${employee.last_name}`}
                className="w-16 h-16 rounded-full object-cover"
              />
              <div>
                <h3 className="text-lg font-semibold">{employee.first_name} {employee.last_name}</h3>
                <p className="text-gray-600">{employee.department}</p>
              </div>
            </div>
            
            {/* Badges */}
            <div className="mt-4 flex flex-wrap gap-2">
              {(localBadges[employee.id] || []).map(badge => {
                const IconComponent = getBadgeIcon(badge.icon);
                return (
                  <div
                    key={badge.id}
                    className={`group relative flex items-center gap-1.5 px-2 py-1 rounded-full text-sm ${getBadgeColor(badge.color)}`}
                  >
                    <IconComponent size={16} />
                    {badge.name}
                    <button
                      onClick={() => handleRemoveBadge(employee.id, badge.id)}
                      className="ml-1 opacity-0 group-hover:opacity-100 transition-opacity"
                      title="Supprimer le badge"
                    >
                      <X size={14} className="hover:text-red-600" />
                    </button>
                  </div>
                );
              })}
              <button
                onClick={() => {
                  setSelectedEmployee(employee.id);
                  setShowBadgeModal(true);
                  setError(null);
                }}
                className="flex items-center gap-1.5 px-2 py-1 rounded-full text-sm bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors"
              >
                <Plus size={16} />
                Badge
              </button>
            </div>

            <div className="mt-4">
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Points actuels:</span>
                <span className="font-semibold">{localPoints[employee.id] || 0}</span>
              </div>
            </div>
            <button
              onClick={() => handleGivePoints(employee.id)}
              className="mt-4 w-full flex items-center justify-center gap-2 bg-indigo-600 text-white py-2 px-4 rounded-lg hover:bg-indigo-700 transition-colors"
            >
              <Award size={20} />
              Donner des points
            </button>
          </div>
        ))}
      </div>
      {showBadgeModal && <BadgeModal />}
    </div>
  );
}