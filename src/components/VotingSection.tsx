import React, { useState } from 'react';
import { Employee } from '../types';
import { Check, Search, AlertCircle, Building } from 'lucide-react';
import { NominateHeroIcon } from './icons/NominateHeroIcon';
import { OngoingNominationInfo } from './voting/OngoingNominationInfo';
import { NominationModal } from './voting/NominationModal';
import { useSettings } from '../hooks/useSettings';
import { useAuth } from '../hooks/useAuth';
import { useNominations } from '../hooks/useNominations';

interface VotingSectionProps {
  employees: Employee[];
}

export function VotingSection({ employees }: VotingSectionProps) {
  const { user } = useAuth();
  const { getOngoingArea, getOngoingCycleDates } = useSettings();
  const { nominations, createNomination, deleteNomination, loading, error } = useNominations();
  const ongoingCycleDates = getOngoingCycleDates();
  const ongoingArea = getOngoingArea();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);
  const [showNominationModal, setShowNominationModal] = useState(false);
  const [nominationError, setNominationError] = useState<string | null>(null);

  // Get the client_id of the logged-in user
  const currentUserProfile = employees.find(emp => emp.id === user?.id);
  const userClientId = currentUserProfile?.client_id;

  // Filter employees by client_id
  const clientEmployees = userClientId 
    ? employees.filter(emp => emp.client_id === userClientId)
    : [];

  const isVotingEnabled = ongoingCycleDates?.start && ongoingArea && user;

  // Find the current user's nomination for the ongoing cycle
  const currentNomination = React.useMemo(() => {
    if (!user || !ongoingCycleDates) return null;
    
    return nominations.find(
      nomination => nomination.voter_id === user.id
    );
  }, [nominations, user, ongoingCycleDates]);

  const hasVoted = Boolean(currentNomination);
  const currentNomineeId = currentNomination?.nominee_id;

  const filteredEmployees = React.useMemo(() => {
    if (!searchQuery.trim()) return clientEmployees;

    const query = searchQuery.toLowerCase();
    return clientEmployees.filter(employee => 
      `${employee.first_name} ${employee.last_name}`.toLowerCase().includes(query) ||
      employee.department.toLowerCase().includes(query)
    );
  }, [clientEmployees, searchQuery]);

  const handleNominationSubmit = async (selectedAreas: string[], justification: string, remarks?: string) => {
    if (!user || !ongoingCycleDates || !selectedEmployee) return;

    try {
      setNominationError(null);
      await createNomination(
        user.id,
        selectedEmployee.id,
        selectedAreas,
        justification,
        remarks
      );
      setSelectedEmployee(null);
      setShowNominationModal(false);
    } catch (err) {
      setNominationError(err instanceof Error ? err.message : 'An error occurred while submitting nomination');
    }
  };

  const handleNominationClick = async (employee: Employee) => {
    if (!isVotingEnabled || !user) return;

    if (currentNomineeId === employee.id) {
      try {
        await deleteNomination(user.id);
      } catch (err) {
        console.error('Error deleting nomination:', err);
      }
    } else if (!hasVoted) {
      setSelectedEmployee(employee);
      setShowNominationModal(true);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-gray-600">Loading nominations...</div>
      </div>
    );
  }

  return (
    <div className="container-large">
      <OngoingNominationInfo
        ongoingCycleDates={ongoingCycleDates}
        ongoingArea={ongoingArea}
      />

      <div className="white-box relative">
        <div>
          {isVotingEnabled && (
            <h2 className="heading-2">
              {hasVoted ? "Vote locked in — you're awesome! 🙌" : "🔥 Honor a teammate - Vote Now!"}
            </h2>
          )}
          {error && (
            <div className="mt-4 flex items-center justify-center gap-2 text-red-600 bg-red-50 p-3 rounded-lg">
              <AlertCircle size={20} />
              <p>{error}</p>
            </div>
          )}
          {!isVotingEnabled ? (
            <div className="info-pill-right pill-yellow">
              <p>Nomination closed</p>
            </div>
      
          ) : (
            <h3 className="heading-3">
              {hasVoted 
                ? `You have nominated ${employees.find(emp => emp.id === currentNomineeId)?.first_name} ${employees.find(emp => emp.id === currentNomineeId)?.last_name}. Changed your mind? Just click again to update your vote.`
                : `Show some love to the colleague who masters this cycle's skill by nominating them for Redspher Hero`
              }
            </h3>
          )}
        </div>

        {/* Search Bar */}
        <div className="m-6">
          <div className="relative max-w-md mx-auto">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-5 w-5 text-gray-400" />
            </div>
            <input
              type="search"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search colleague"
              className="block w-full pl-10 px-3 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#4F03C1] focus:border-[#4F03C1] font-inter text-sm"
            />
          </div>
        </div>

        {/* Employee Grid */}
        <div className="grid-3-col">
          {filteredEmployees.map((employee) => {
            const isNominated = currentNomineeId === employee.id;
            const cardClasses = `${isNominated ? 'bg-[#EDE6F8]' : 'bg-gray-100'} rounded-xl p-6 ${
              isNominated ? 'ring-2 ring-[#4F03C1]' : ''
            }`;
            return (
              <div key={employee.id} className={cardClasses}>
                <div className="flex flex-col items-center">
                  <img
                    src={employee.avatar}
                    alt={`${employee.first_name} ${employee.last_name}`}
                    className="w-24 h-24 rounded-full object-cover mb-6"
                  />              
                  <h3 className="heading-3">{employee.first_name} {employee.last_name}</h3>
                   <div className="flex items-center justify-center gap-2 body-2 mb-6">
                      <Building size={16} />
                      <p>{employee.department}
                      </p>
                    </div> 
                  <button
                    onClick={() => handleNominationClick(employee)}
                    className={`button-style w-full ${
                      !isVotingEnabled
                        ? 'button-disabled'
                        : isNominated
                        ? 'button-primary'
                        : hasVoted
                        ? 'button-disabled'
                        : 'button-primary'
                    }`}
                    disabled={!isVotingEnabled || (hasVoted && !isNominated)}
                  >
                    {isNominated ? (
                      <>
                        <Check size={20} />
                        Nominated
                      </>
                    ) : (
                      <>
                        <NominateHeroIcon size={20} />
                        Nominate
                      </>
                    )}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {showNominationModal && selectedEmployee && ongoingArea && (
        <NominationModal
          isOpen={showNominationModal}
          onClose={() => {
            setShowNominationModal(false);
            setSelectedEmployee(null);
            setNominationError(null);
          }}
          onSubmit={handleNominationSubmit}
          nomineeInfo={{
            name: `${selectedEmployee.first_name} ${selectedEmployee.last_name}`,
            department: selectedEmployee.department
          }}
          ongoingArea={ongoingArea}
          error={nominationError}
        />
      )}
    </div>
  );
}