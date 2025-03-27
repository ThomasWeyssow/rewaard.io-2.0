import React, { useState, useMemo } from 'react';
import { Gift, User, History, UserCircle, Menu, X, Settings, ClipboardCheck, Award, Users, LogOut, MessageSquare, Send } from 'lucide-react';
import { NominateHeroIcon } from './icons/NominateHeroIcon';
import { RewaardLogo } from './icons/RewaardLogo';
import { Employee } from '../types';
import { usePermissions } from '../hooks/usePermissions';
import { useAuth } from '../hooks/useAuth';
import { usePages } from '../hooks/usePages';
import { useSettings } from '../hooks/useSettings';

interface HeaderProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  onProfileClick: () => void;
  currentUser: Employee | undefined;
}

export function Header({ activeTab, setActiveTab, onProfileClick, currentUser }: HeaderProps) {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const { canAccessReviewPage, canAccessUserPage, canAccessSettingsPage } = usePermissions();
  const { user, signOut } = useAuth();
  const { isPageEnabled } = usePages();
  const { settings } = useSettings();

  // Mémoriser les props du logo
  const logoProps = useMemo(() => ({
    className: "h-8 w-auto text-gray-900"
  }), []);

  const handleTabClick = (tab: string) => {
    if (isPageEnabled(tab)) {
      setActiveTab(tab);
      setIsMenuOpen(false);
    }
  };

  // Determine if we should show user controls
  const showUserControls = Boolean(user);

  return (
    <header className="bg-[#FEFEFF] text-gray-900 shadow sticky top-0 z-50">
      <div className="container mx-auto px-4">
        <div className="flex justify-between items-center h-14">
          <div className="flex-shrink-0">
            {settings?.logo_url ? (
              <img 
                src={settings.logo_url} 
                alt="Logo" 
                className="h-8 w-auto"
              />
            ) : (
              <RewaardLogo {...logoProps} />
            )}
          </div>
          
          {/* Mobile menu button */}
          <button
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className="md:hidden p-2 hover:bg-gray-100 rounded-lg transition-colors"
            aria-label={isMenuOpen ? "Close menu" : "Open menu"}
          >
            {isMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>

          {/* Desktop menu */}
          <div className="hidden md:flex items-center gap-2">
            <nav className="flex gap-2">
              {isPageEnabled('hero-program') && (
                <button
                  onClick={() => handleTabClick('hero-program')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'hero-program' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  Hero Program
                </button>
              )}
              {isPageEnabled('employees') && (
                <button
                  onClick={() => handleTabClick('employees')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'employees' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  Employees
                </button>
              )}
              {isPageEnabled('rewards') && (
                <button
                  onClick={() => handleTabClick('rewards')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'rewards' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  Rewards
                </button>
              )}
              {isPageEnabled('voting') && (
                <button
                  onClick={() => handleTabClick('voting')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'voting' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  Vote Now
                </button>
              )}
              {canAccessReviewPage && isPageEnabled('review') && (
                <button
                  onClick={() => handleTabClick('review')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'review' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  Validate Hero
                </button>
              )}
              {isPageEnabled('history') && (
                <button
                  onClick={() => handleTabClick('history')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'history' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  Wall of Fame
                </button>
              )}
              {/* Recognition Module Pages */}
              {isPageEnabled('feed') && (
                <button
                  onClick={() => handleTabClick('feed')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'feed' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    Feed
                  </div>
                </button>
              )}
              {isPageEnabled('recognize') && (
                <button
                  onClick={() => handleTabClick('recognize')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'recognize' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    Recognize
                  </div>
                </button>
              )}
              {canAccessUserPage && isPageEnabled('users') && (
                <button
                  onClick={() => handleTabClick('users')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'users' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  Users
                </button>
              )}
              {canAccessSettingsPage && isPageEnabled('settings') && (
                <button
                  onClick={() => handleTabClick('settings')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'settings' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  Settings
                </button>
              )}
              {canAccessSettingsPage && isPageEnabled('recognition-admin') && (
                <button
                  onClick={() => handleTabClick('recognition-admin')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    activeTab === 'recognition-admin' 
                      ? 'menu-active' 
                      : 'menu-inactive'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    Recognition Admin
                  </div>
                </button>
              )}
            </nav>
            {showUserControls && (
              <div className="flex items-center gap-2 ml-2">
                <button
                  onClick={onProfileClick}
                  className="p-2 rounded-lg text-gray-700 hover:text-gray-700 hover:bg-gray-50 transition-colors"
                  title="Profile"
                >
                  <UserCircle size={24} />
                </button>
                <button
                  onClick={signOut}
                  className="p-2 rounded-lg text-gray-700 hover:text-gray-700 hover:bg-gray-50 transition-colors"
                  title="Sign out"
                >
                  <LogOut size={24} />
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Mobile menu */}
        <div
          className={`md:hidden ${
            isMenuOpen
              ? 'max-h-screen opacity-100 visible'
              : 'max-h-0 opacity-0 invisible'
          } transition-all duration-300 ease-in-out overflow-hidden`}
        >
          <nav className="py-4 space-y-1">
            {isPageEnabled('hero-program') && (
              <button
                onClick={() => handleTabClick('hero-program')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'hero-program' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Hero Program
              </button>
            )}
            {isPageEnabled('employees') && (
              <button
                onClick={() => handleTabClick('employees')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'employees' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Employees
              </button>
            )}
            {isPageEnabled('rewards') && (
              <button
                onClick={() => handleTabClick('rewards')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'rewards' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Rewards
              </button>
            )}
            {isPageEnabled('voting') && (
              <button
                onClick={() => handleTabClick('voting')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'voting' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Vote now
              </button>
            )}
            {canAccessReviewPage && isPageEnabled('review') && (
              <button
                onClick={() => handleTabClick('review')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'review' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Validate Hero
              </button>
            )}
            {isPageEnabled('history') && (
              <button
                onClick={() => handleTabClick('history')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'history' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Wall of Fame
              </button>
            )}
            {/* Recognition Module Pages - Mobile */}
            {isPageEnabled('feed') && (
              <button
                onClick={() => handleTabClick('feed')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'feed' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Feed
              </button>
            )}
            {isPageEnabled('recognize') && (
              <button
                onClick={() => handleTabClick('recognize')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'recognize' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Recognize
              </button>
            )}
            {canAccessUserPage && isPageEnabled('users') && (
              <button
                onClick={() => handleTabClick('users')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'users' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Users
              </button>
            )}
            {canAccessSettingsPage && isPageEnabled('settings') && (
              <button
                onClick={() => handleTabClick('settings')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'settings' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Settings
              </button>
            )}
            {canAccessSettingsPage && isPageEnabled('recognition-admin') && (
              <button
                onClick={() => handleTabClick('recognition-admin')}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                  activeTab === 'recognition-admin' 
                    ? 'menu-active' 
                    : 'menu-inactive'
                }`}
              >
                Recognition Admin
              </button>
            )}
            {showUserControls && (
              <>
                <button
                  onClick={() => {
                    onProfileClick();
                    setIsMenuOpen(false);
                  }}
                  className="w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  <UserCircle size={24} />
                  Profile
                </button>
                <button
                  onClick={signOut}
                  className="w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  <LogOut size={24} />
                  Sign Out
                </button>
              </>
            )}
          </nav>
        </div>
      </div>
    </header>
  );
}