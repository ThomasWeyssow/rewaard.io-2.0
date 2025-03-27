import React, { useState, useEffect } from 'react';
import { Routes, Route, useLocation, Navigate } from 'react-router-dom';
import { Header } from './components/Header';
import { EmployeeList } from './components/EmployeeList';
import { RewardList } from './components/RewardList';
import { VotingSection } from './components/VotingSection';
import { HistorySection } from './components/HistorySection';
import { ProfilePage } from './components/ProfilePage';
import { AdminLogin } from './components/AdminLogin';
import { AdminDashboard } from './components/AdminDashboard';
import { AuthForm } from './components/AuthForm';
import { SettingsPage } from './components/SettingsPage';
import { ReviewNominationPage } from './components/ReviewNominationPage';
import { HeroProgramPage } from './components/HeroProgramPage';
import { UserManagementPage } from './components/UserManagementPage';
import { RecognitionFeed } from './components/recognition/RecognitionFeed';
import { RecognitionForm } from './components/recognition/RecognitionForm';
import { RecognitionAdmin } from './components/recognition/RecognitionAdmin';
import { useAuth } from './hooks/useAuth';
import { useProfiles } from './hooks/useProfiles';
import { usePermissions } from './hooks/usePermissions';
import { useRewards } from './hooks/useRewards';

function App() {
  const { user, loading: authLoading } = useAuth();
  const { profiles, loading: profilesLoading } = useProfiles();
  const { canAccessUserPage, canAccessReviewPage, canAccessSettingsPage } = usePermissions();
  const { rewards, loading: rewardsLoading } = useRewards();
  const location = useLocation();
  
  const [activeTab, setActiveTab] = useState('hero-program');
  const [showProfile, setShowProfile] = useState(false);
  const [isAdminLoggedIn, setIsAdminLoggedIn] = useState(false);
  
  const currentUser = user ? profiles.find(emp => emp.id === user.id) : undefined;

  // Log user and client info
  console.log('Current user:', { 
    userId: user?.id,
    userEmail: user?.email,
    currentUser,
    clientId: currentUser?.client_id
  });

  // Display a loader while data is loading
  if (authLoading || profilesLoading || rewardsLoading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-xl font-semibold text-gray-600">Loading...</div>
      </div>
    );
  }

  if (location.pathname === '/admin') {
    if (!isAdminLoggedIn) {
      return <AdminLogin onLogin={setIsAdminLoggedIn} />;
    }
    return <AdminDashboard 
      onLogout={() => setIsAdminLoggedIn(false)} 
      onUpdateEmployees={() => {}}
      currentEmployees={profiles}
    />;
  }

  if (!user) {
    return <AuthForm onSuccess={() => {}} />;
  }

  if (showProfile && currentUser) {
    return (
      <ProfilePage
        employee={currentUser}
        rewards={rewards}
        onClose={() => setShowProfile(false)}
      />
    );
  }

  return (
    <div className="min-h-screen bg-[#FAF7FF]">
      <Header 
        activeTab={activeTab} 
        setActiveTab={setActiveTab}
        onProfileClick={() => setShowProfile(true)}
        currentUser={currentUser}
      />
      <main className="container mx-auto px-4 py-8">
        <Routes>
          <Route path="/" element={
            activeTab === 'hero-program' ? (
              <HeroProgramPage />
            ) : activeTab === 'employees' ? (
              <EmployeeList 
                employees={profiles}
                onGivePoints={() => {}}
              />
            ) : activeTab === 'rewards' ? (
              <RewardList
                rewards={rewards}
                userPoints={currentUser?.recognition_points?.earned_points || 0}
                onRedeemReward={() => {}}
              />
            ) : activeTab === 'voting' ? (
              <VotingSection
                employees={profiles}
              />
            ) : activeTab === 'review' && canAccessReviewPage ? (
              <ReviewNominationPage />
            ) : activeTab === 'history' ? (
              <HistorySection
                employees={profiles}
              />
            ) : activeTab === 'feed' ? (
              <RecognitionFeed />
            ) : activeTab === 'recognize' ? (
              <RecognitionForm />
            ) : activeTab === 'recognition-admin' && canAccessSettingsPage ? (
              <RecognitionAdmin />
            ) : activeTab === 'settings' ? (
              <SettingsPage />
            ) : activeTab === 'users' && canAccessUserPage ? (
              <UserManagementPage />
            ) : null
          } />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;