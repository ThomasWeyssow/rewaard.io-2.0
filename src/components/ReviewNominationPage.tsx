import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { useProfiles } from '../hooks/useProfiles';
import { useSettings } from '../hooks/useSettings';
import { useNominationHistory } from '../hooks/useNominationHistory';
import { Trophy, User, Building, Calendar, Award, Check, Lock, Crown, Info, Clock, AlertCircle } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { usePermissions } from '../hooks/usePermissions';
import { supabase } from '../lib/supabase';

export function ReviewNominationPage() {
  const location = useLocation();
  const { user } = useAuth();
  const { profiles, winners } = useProfiles();
  const { nominations, loading, error, validateNomination, getValidationsCount, hasValidated } = useNominationHistory();
  const { canAccessReviewPage, canValidateNominations, loading: permissionsLoading } = usePermissions();
  const [selectedNomineeId, setSelectedNomineeId] = useState<string | null>(null);
  const [timeLeft, setTimeLeft] = useState<string>('');
  const [isValidationPeriodOver, setIsValidationPeriodOver] = useState(false);
  const [cycleEndDate, setCycleEndDate] = useState<string | null>(null);
  const [validationEndDate, setValidationEndDate] = useState<string | null>(null);
  const [nominationArea, setNominationArea] = useState<any>(null);
  const [cycleWinner, setCycleWinner] = useState<any>(null);

  // Récupérer la date de fin du cycle et la nomination area
  useEffect(() => {
    if (nominations.length > 0) {
      const fetchCycleData = async () => {
        const { data: cycle } = await supabase
          .from('nomination_cycles')
          .select(`
            end_date,
            end_validation_date,
            nomination_areas (
              category,
              areas
            ),
            cycle_winner (
              nominee_id,
              profiles (
                first_name,
                last_name,
                department,
                avatar_url
              )
            )
          `)
          .eq('status', 'completed')
          .order('end_date', { ascending: false })
          .limit(1)
          .single();
        
        if (cycle) {
          setCycleEndDate(cycle.end_date);
          setValidationEndDate(cycle.end_validation_date);
          setNominationArea(cycle.nomination_areas);
          if (cycle.cycle_winner) {
            setCycleWinner(cycle.cycle_winner);
          }
        }
      };
      
      fetchCycleData();
    }
  }, [nominations]);

  // Calculate time left for validation
  useEffect(() => {
    const calculateTimeLeft = () => {
      if (!validationEndDate) return;

      const now = new Date();
      const endDate = new Date(validationEndDate);
      const difference = endDate.getTime() - now.getTime();

      if (difference <= 0) {
        setTimeLeft('Validation phase completed');
        setIsValidationPeriodOver(true);
        return;
      }

      const days = Math.floor(difference / (1000 * 60 * 60 * 24));
      const hours = Math.floor((difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((difference % (1000 * 60)) / 1000);

      setTimeLeft(`${days}d ${hours}h ${minutes}m ${seconds}s`);
      setIsValidationPeriodOver(false);
    };

    const timer = setInterval(calculateTimeLeft, 1000);
    calculateTimeLeft(); // Initial calculation

    return () => clearInterval(timer);
  }, [validationEndDate]);

  // Group nominations by nominee and count them
  const nomineeStats = React.useMemo(() => {
    const stats = new Map();
    nominations.forEach(nomination => {
      if (!stats.has(nomination.nominee_id)) {
        const validationsCount = getValidationsCount(nomination.nominee_id);
        const validatedByCurrentUser = user ? hasValidated(user.id) === nomination.nominee_id : false;
        
        stats.set(nomination.nominee_id, {
          nomineeId: nomination.nominee_id,
          nominations: [],
          nominationCount: 0,
          validationsCount,
          isValidatedByCurrentUser: validatedByCurrentUser
        });
      }
      const nomineeData = stats.get(nomination.nominee_id);
      nomineeData.nominations.push(nomination);
      nomineeData.nominationCount++;
    });
    return Array.from(stats.values());
  }, [nominations, getValidationsCount, hasValidated, user]);

  // Split nominees into top 6 and others, sorted by nomination count only
  const { topNominees, otherNominees } = React.useMemo(() => {
    const sortedNominees = nomineeStats
      .sort((a, b) => {
        // Sort only by nomination count
        return b.nominationCount - a.nominationCount;
      })
      .map(stats => ({
        nominee: profiles.find(p => p.id === stats.nomineeId),
        nominations: stats.nominations,
        voteCount: stats.nominationCount,
        validationsCount: stats.validationsCount,
        isValidatedByCurrentUser: stats.isValidatedByCurrentUser
      }));

    return {
      topNominees: sortedNominees.slice(0, 6),
      otherNominees: sortedNominees.slice(6)
    };
  }, [nomineeStats, profiles]);

  const handleValidateNomination = async (nomineeId: string) => {
    if (!user || isValidationPeriodOver) return;
    
    try {
      await validateNomination(user.id, nomineeId);
    } catch (error) {
      console.error('Error validating nomination:', error);
    }
  };

  // Loading and error states
  if (loading || permissionsLoading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-xl font-semibold text-gray-600">Loading...</div>
      </div>
    );
  }

  if (!canAccessReviewPage) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
        <Lock size={48} className="text-gray-400" />
        <div className="text-xl font-semibold text-gray-600">Access Denied</div>
        <p className="text-gray-500">You don't have permission to view this page.</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
        {error}
      </div>
    );
  }

  // Show message when no completed cycles exist
  if (nominations.length === 0) {
    return (
      <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 text-amber-700">
        No completed nomination cycles yet. Nominations will be available for review once a cycle is completed.
      </div>
    );
  }

  const NomineeCard = ({ nominee, nominations, voteCount, validationsCount, isValidatedByCurrentUser, isTopNominee = false, rank = 0 }) => {
    if (!nominee) return null;

    return (
      <div className={`relative rounded-xl overflow-visible p-6
        bg-gray-100 ${!isValidationPeriodOver && isValidatedByCurrentUser ? 'ring-2 ring-[#4F03C1]' : ''}`}>


        {isValidationPeriodOver && isValidatedByCurrentUser && (
          <div className="absolute info-pill-right pill-green">
            Your finalist
          </div>
        )}
        
        {isTopNominee && rank > 0 && (
          <div className={`absolute -top-2 -left-2 w-8 h-8 rounded-full flex items-center justify-center font-bold
            ${isValidationPeriodOver ? 'bg-gray-600 text-gray-200' : 'bg-[#4F03C1] text-[#FEFEFF]'}`}>
            {rank}
          </div>
        )}

        <div className="flex flex-col items-center">
          <div>
            {/* Nominee avatar */}
            <div className="flex justify-center">
              <img
                src={nominee.avatar}
                alt={`${nominee.first_name} ${nominee.last_name}`}
                className="w-24 h-24 rounded-full object-cover mb-4"
              />
            </div>
            <div>
              {/* Name */}
              <h3 className="heading-3">{nominee.first_name} {nominee.last_name}</h3>
              {/* Department */}
              <div className="flex items-center justify-center gap-2 body-2 mb-6">
                <Building size={16} />
                <p>{nominee.department}</p>
              </div>            
              {/* Pills Section - Displayed side by side */}
              <div className="flex flex-wrap gap-3">
                {/* Vote Count Pill */}
                <div className={`pill-regular ${
                  isValidationPeriodOver
                    ? 'pill-gray'
                    : 'pill-yellow'
                }`}>
                  <User size={16} />
                  <span>{voteCount} vote{voteCount !== 1 ? 's' : ''}</span>
                </div>              
                {/* Validation Count Pill */}
                <div className={`pill-regular ${
                  isValidationPeriodOver
                    ? 'pill-gray'
                    : validationsCount > 0
                      ? 'pill-green'
                      : 'pill-gray'
                }`}>
                  <Check size={16} />
                  <span>{validationsCount} validation{validationsCount !== 1 ? 's' : ''}</span>
                </div>
              </div>
            </div>
           
            {/* Only show validation button for top 6 nominees AND if validation is still open */}
            {isTopNominee && !isValidationPeriodOver && (
              <button
                onClick={() => handleValidateNomination(nominee.id)}
                disabled={!canValidateNominations}
                className={`ml-auto flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${
                  !canValidateNominations
                    ? 'bg-gray-200 text-gray-500 cursor-not-allowed'
                    : isValidatedByCurrentUser
                      ? 'bg-[#7E58C2] hover:bg-[#7E58C2] text-[#FEFEFF]'
                      : 'bg-[#4F03C1] hover:bg-[#3B0290] text-[#FEFEFF]'
                }`}
              >
                {isValidatedByCurrentUser && <Crown size={20} />}
                <span>{isValidatedByCurrentUser ? 'Validated' : 'Confirm as Hero'}</span>
              </button>
            )}
          </div>
        </div>       
        
        {/* Nominations Details */}
        <div className="mt-6">
          <button
            onClick={() => setSelectedNomineeId(
              selectedNomineeId === nominee.id ? null : nominee.id
            )}
            className="w-full px-6 py-3 items-center rounded-lg hover:bg-[#FEFEFF] transition-colors"
          >
            <span className="subtitle-2 mb-0 text-[#4F03C1]">
              {selectedNomineeId === nominee.id ? 'Hide' : 'Show'} nomination details
            </span>
          </button>
          
          {selectedNomineeId === nominee.id && (
            <div className="w-full mt-3 space-y-3">
              {nominations.map((nomination, index) => {
                const voter = profiles.find(p => p.id === nomination.voter_id);
                return (
                  <div
                    key={nomination.id}
                    className="bg-gray-200 rounded-lg p-4"
                  >
                    <div className="flex items-center gap-3 mb-6">
                      <img
                        src={voter?.avatar}
                        alt={`${voter?.first_name} ${voter?.last_name}`}
                        className="w-16 h-16 rounded-full object-cover"
                      />
                      <div>
                        <div className="subtitle-2">{voter?.first_name} {voter?.last_name}</div>
                        <div className="body-2 flex items-center gap-2">
                          <Building size={16} />
                          {voter?.department}
                        </div>
                      </div>
                    </div>
                    <div className="space-y-3">
                      <div>
                        <h4 className="subtitle-2 text-left">
                          Key capabilities
                        </h4>
                        <div className="flex flex-wrap gap-2">
                          {nomination.selected_areas.map((area, i) => (
                            <span
                              key={i}
                              className="px-4 py-2 bg-gray-100 text-gray-600 border-lg body-2"
                            >
                              {area}
                            </span>
                          ))}
                        </div>
                      </div>
                      <div>
                        <h4 className="subtitle-2 text-left">
                          Comment
                        </h4>
                        <p className="px-4 py-2 bg-gray-100 text-gray-600 border-lg body-2 text-left">
                          {nomination.justification}
                        </p>
                      </div>
                      {nomination.remarks && (
                        <div>
                          <h4 className="subtitle-2 text-left">
                            Additional Remarks
                          </h4>
                          <p className="px-4 py-2 bg-gray-100 text-gray-600 border-lg body-2 text-left">
                            {nomination.remarks}
                          </p>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="container-large">
      {/* Header with Timer */}
      <div className="purple-box">                  
        <h2 className="heading-2">
          {isValidationPeriodOver ? "The results are in!" : "Review & Confirm"}
        </h2>
        
        {!isValidationPeriodOver && (
            <div>
              <h3 className="heading-3">
                The nomination phase has ended, and the best contenders have emerged. As part of the Voting Committee, take a moment to review them and confirm the one who truly stood out and for the skill being honored during this cycle.
              </h3> 
              <div className="flex flex-col sm:flex-row gap-3 justify-center items-center">
                {/* Cycle End Date Pill */}
                {cycleEndDate && (
                  <div className="pill-white mb-0">
                    <Calendar size={20} />
                    <span>Cycle Ended:</span>
                    <span className="font-mono">
                      {new Date(cycleEndDate).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                      })}
                    </span>
                  </div>
                )}          
                {/* Nomination Area Pill */}
                <div className="pill-white mb-0">
                  <Award size={20} />
                  <span>{nominationArea?.category}</span>
                </div>
              </div>  
            </div>
          )}
        
        
        {/* Display cycle winner if exists */}
        {cycleWinner && (
          <div className="relative bg-gradient-to-br from-[#3F029A] to-[#AA00FF] rounded-xl flex flex-col items-center p-6 px-6 w-fit mx-auto mt-16">        
            {/* Avatar centré, dépassant en haut */}
            <div className="absolute -top-12 left-1/2 transform -translate-x-1/2">
              <img 
                src={cycleWinner.profiles.avatar_url} 
                alt={`${cycleWinner.profiles.first_name} ${cycleWinner.profiles.last_name}`}
                className="w-32 h-32 rounded-full object-cover"
              />
            </div>
            {/* H3 Centré */}
            <h3 className="heading-3 text-[#FEFEFF] mt-20 mb-8">
                {cycleWinner.profiles.first_name} {cycleWinner.profiles.last_name} has been crowned 🎉
            </h3>         
            {/* Conteneur centré */}
            <div className="flex justify-center">
              {/* Mise en page en 2 colonnes centrées */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 items-center max-w-3xl w-full">  
                {/* Colonne de gauche - Skill */}
                <div className="flex items-center justify-center">
                  <div className="inline-flex items-center pill-regular bg-[#FEFEFF] bg-opacity-10 text-[#FEFEFF] body-2 gap-2 w-full">
                    <Award size={20} />
                    <span>{nominationArea?.category}</span>
                  </div>
                </div>
        
                {/* Colonne de droite - Period */}
                <div className="flex items-center justify-center">
                  {cycleEndDate && (
                    <div className="inline-flex items-center pill-regular bg-[#FEFEFF] bg-opacity-10 text-[#FEFEFF] body-2 gap-2 w-full">
                      <Calendar size={20} />
                      <span>Cycle Ended:</span>
                      <span>
                        {new Date(cycleEndDate).toLocaleDateString('en-US', {
                          month: 'short',
                          day: 'numeric',
                          year: 'numeric',
                        })}
                      </span>
                    </div>
                  )} 

                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Final contenders */}
      {topNominees.length > 0 && (
        <div className="white-box relative">
          
          {/* Validation over pill */}
          {isValidationPeriodOver && (
            <div className="info-pill-right pill-yellow">
              Validation closed
            </div>
          )}
          
          <div>
            <h2 className="heading-2 mt-6">
              {isValidationPeriodOver ? "The final 6 contenders" : "🔥 Your decision matters - Make the final call!"}
            </h2>
            {isValidationPeriodOver && (
            <h3 className="heading-3">
              Give a round of applause for these finalists!
            </h3>
            )}
            
            {/* Time Left Pill - show if validation period ongoing */}
            {!isValidationPeriodOver && (
              <div className="flex justify-center">
                <div className="pill-rounded mb-8 pill-yellow">
                  <Clock size={20} />
                  <span>Time left:</span>
                  <span className="font-mono">{timeLeft}</span>
                </div>   
              </div> 
            )}
            </div>

          
          {/* Nominee Grid */} 
          <div className="grid-3-col">
            {topNominees.map(({ nominee, nominations, voteCount, validationsCount, isValidatedByCurrentUser }, index) => (
              <NomineeCard
                key={nominee?.id}
                nominee={nominee}
                nominations={nominations}
                voteCount={voteCount}
                validationsCount={validationsCount}
                isValidatedByCurrentUser={isValidatedByCurrentUser}
                isTopNominee={true}
                rank={index + 1}
              />
            ))}
          </div>
        </div>
      )}

      {/* Other Nominees */}
      {otherNominees.length > 0 && (
        <div className="space-y-4">
          <h2 className="text-xl font-semibold text-gray-900">Other Nominations</h2>
          <div className="grid gap-6">
            {otherNominees.map(({ nominee, nominations, voteCount, validationsCount, isValidatedByCurrentUser }) => (
              <NomineeCard
                key={nominee?.id}
                nominee={nominee}
                nominations={nominations}
                voteCount={voteCount}
                validationsCount={validationsCount}
                isValidatedByCurrentUser={isValidatedByCurrentUser}
                isTopNominee={false}
              />
            ))}
          </div>
        </div>
      )}

      {topNominees.length === 0 && otherNominees.length === 0 && (
        <div className="text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
          <Trophy size={40} className="mx-auto text-gray-400 mb-4" />
          <h3 className="font-medium text-gray-900 mb-1">
            No nominations yet
          </h3>
          <p className="text-sm text-gray-600">
            Nominations will appear here once team members start voting
          </p>
        </div>
      )}
    </div>
  );
}