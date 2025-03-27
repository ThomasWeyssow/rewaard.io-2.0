import React from 'react';
import { useSettings } from '../hooks/useSettings';
import { useProfiles } from '../hooks/useProfiles';
import { usePermissions } from '../hooks/usePermissions';
import { NextNominationArea } from './settings/NextNominationArea';
import { OngoingNominationArea } from './settings/OngoingNominationArea';
import { IncentivesSection } from './settings/IncentivesSection';
import { NominationSection } from './settings/NominationSection';
import { EmployeeManagementSection } from './settings/EmployeeManagementSection';
import { GeneralSettings } from './settings/GeneralSettings';
import { Lock } from 'lucide-react';

export function SettingsPage() {
  const {
    settings,
    incentives,
    nominationAreas,
    loading,
    error: settingsError,
    selectNextNominationArea,
    deleteOngoingNominationCycle,
    getNextNominationDate,
    getNominationCycleDates,
    getOngoingCycleDates,
    getOngoingArea,
    addIncentive,
    updateIncentive,
    deleteIncentive,
    addNominationArea,
    updateNominationArea,
    deleteNominationArea
  } = useSettings();

  const { profiles, loading: profilesLoading } = useProfiles();
  const { canAccessSettingsPage, canModifySettings, loading: permissionsLoading } = usePermissions();

  if (loading || profilesLoading || permissionsLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  if (!canAccessSettingsPage) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
        <Lock size={48} className="text-gray-400" />
        <div className="text-xl font-semibold text-gray-600">Access Denied</div>
        <p className="text-gray-500">You don't have permission to view this page.</p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* General Settings */}
      <GeneralSettings 
        settings={settings}
        onUpdateSettings={(period, startDate) => {
          // Implement settings update logic
          console.log('Update settings:', { period, startDate });
        }}
      />

      {/* Next Nomination Area en sticky */}
      <div className="sticky top-0 z-10 bg-gray-100 pt-6 pb-4 -mx-4 px-4 -mt-6">
        <NextNominationArea
          areas={nominationAreas}
          selectedAreaId={settings?.next_nomination_area_id || null}
          onSelect={canModifySettings ? selectNextNominationArea : undefined}
          nextNominationDate={getNextNominationDate()}
          nominationCycleDates={getNominationCycleDates()}
          nominationPeriod={settings?.next_nomination_period || 'monthly'}
          readOnly={!canModifySettings}
        />
      </div>

      {/* Autres sections */}
      <div className="pt-4 space-y-6">
        <OngoingNominationArea
          ongoingCycleDates={getOngoingCycleDates()}
          ongoingArea={getOngoingArea()}
          onDelete={canModifySettings ? deleteOngoingNominationCycle : undefined}
          readOnly={!canModifySettings}
        />

        <IncentivesSection
          incentives={incentives}
          onAdd={canModifySettings ? addIncentive : undefined}
          onUpdate={canModifySettings ? updateIncentive : undefined}
          onDelete={canModifySettings ? deleteIncentive : undefined}
          readOnly={!canModifySettings}
        />

        <NominationSection
          areas={nominationAreas}
          onAdd={canModifySettings ? addNominationArea : undefined}
          onUpdate={canModifySettings ? updateNominationArea : undefined}
          onDelete={canModifySettings ? deleteNominationArea : undefined}
          readOnly={!canModifySettings}
        />

        <EmployeeManagementSection
          currentEmployees={profiles}
          onUpdateEmployees={canModifySettings ? () => {} : undefined}
          readOnly={!canModifySettings}
        />
      </div>
    </div>
  );
}