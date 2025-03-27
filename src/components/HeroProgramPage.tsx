import React, { useState, useEffect } from 'react';
import { Trophy, Star, Award, Medal, Calendar, Users, UserCheck, Megaphone, Crown, Gem, Gift, Heart, Rocket, Euro, Upload, AlertCircle, Brain, Target } from 'lucide-react';
import { useSettings } from '../hooks/useSettings';
import { useStorage } from '../hooks/useStorage';
import { usePermissions } from '../hooks/usePermissions';

export function HeroProgramPage() {
  const { settings, incentives, nominationAreas, loading, error: settingsError, updateHeroBanner } = useSettings();
  const { uploadHeroBanner, uploading, error: uploadError } = useStorage();
  const { canModifySettings } = usePermissions();
  const [error, setError] = useState<string | null>(null);

  const [openAreaId, setOpenAreaId] = useState<string | null>(null);

  // Mapping des icônes
  const getIconComponent = (iconName: string) => {
    const icons: { [key: string]: React.ComponentType } = {
      'Star': Star,
      'Users': Users,
      'Brain': Brain,
      'Target': Target,
      'Award': Award,
      'Trophy': Trophy,
      'Medal': Medal,
      'Crown': Crown,
      'Gem': Gem,
      'Gift': Gift,
      'Heart': Heart,
      'Rocket': Rocket,
      'Euro': Euro
    };
    return icons[iconName] || Star;
  };

  const handleBannerUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      setError(null);
      const newBannerUrl = await uploadHeroBanner(file);
      await updateHeroBanner(newBannerUrl);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occured');
    }
  };

  const bannerUrl = settings?.hero_banner_url || 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=1920&h=300&fit=crop';

  // Format dates to show only the day
  const formatDate = (dateStr: string) => {
    // Parse the date string and force it to be interpreted in the Europe/Paris timezone
    const date = new Date(dateStr + 'Z'); // Add Z to force UTC interpretation
    
    // Create formatter with explicit timezone
    const formatter = new Intl.DateTimeFormat('fr-FR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      timeZone: 'Europe/Paris'
    });
    
    return formatter.format(date);
  };

  // Loading state
  if (loading) {
    return (
      <div className="min-h-[calc(100vh-3.5rem)] bg-gray-50 flex items-center justify-center">
        <div className="text-gray-600">Loading Hero Program...</div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Hero Banner Section - Full width */}
      <div className="relative -mx-4 -mt-8 w-screen" style={{ marginLeft: 'calc(-50vw + 50%)', marginRight: 'calc(-50vw + 50%)' }}>
        <div className="relative h-[300px] bg-indigo-900">
          <img 
            src={bannerUrl}
            alt="Hero Program Banner"
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-indigo-900/75">
            <div className="h-full flex flex-col items-center justify-center text-center px-4">
              <h1 className="text-4xl lg:text-4xl font-bold text-[#FEFEFF] mt-6">Redspher Hero Program</h1>
              <p className="text-sm lg:text-base text-[#FEFEFF] max-w-3xl mt-6 mb-3">
                This program recognizes outstanding team members who go above and beyond in their contributions. Celebrate excellence and inspire your team — one hero at a time!
              </p>
            </div>
          </div>
          {canModifySettings && (
            <div className="absolute top-4 right-4">
              <label className="cursor-pointer bg-white/10 hover:bg-white/20 backdrop-blur-sm px-4 py-2 rounded-lg flex items-center gap-2 text-white transition-colors">
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleBannerUpload}
                  className="hidden"
                />
                <Upload size={20} />
                <span className="text-sm font-medium">
                  {uploading ? 'Uploading...' : 'Change Banner'}
                </span>
              </label>
            </div>
          )}
        </div>
      </div>

      {error && (
        <div className="max-w-4xl mx-auto px-4">
          <div className="p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
            <AlertCircle size={20} />
            {error}
          </div>
        </div>
      )}

      <div className="container-normal">
        {/* Incentives Section */}
        <div className="white-box">
          <div className="mb-14">
            <h2 className="heading-2">🔥 Be the Hero & Reap the Rewards!
            </h2>
            <h3 className="heading-3">As Redspher Hero, you'll earn well-deserved recognition along with exciting perks</h3>
          </div>
          {loading ? (
            <div className="text-center py-8 text-[#282132]">Loading rewards...</div>
          ) : incentives.length > 0 ? (
            
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {incentives.map((incentive) => {
                const IconComponent = getIconComponent(incentive.icon);

                return (
                  <div
                    key={incentive.id}
                    className="p-2 bg-[#CDEAE7] rounded-xl"
                  >
                    <div className="flex items-center gap-4">
                      <div className="icons-white">
                        <IconComponent size={28} />
                      </div>
                      <div>
                        <p className="subtitle text-left">{incentive.title}</p>
                        {incentive.description && (
                        <p className="body-2">{incentive.description}</p>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
              <Award size={40} className="mx-auto text-gray-400 mb-4" />
              <h3 className="font-medium text-gray-900 mb-1">
                No rewards defined yet
              </h3>
              <p className="text-sm text-gray-600">
                Rewards will be displayed here once they are created by the administrator
              </p>
            </div>
          )}
        </div>
   
        {/* How does it work? - Updated Design */}
        <div className="white-box">
          <div className="text-center mb-20">
            <h2 className="heading-2">How to 
              <span className="bg-[#FFF5E6] ml-2 px-2 rounded">become a Hero</span>
            </h2>
            <h3 className="heading-3">Each cycle, a key skill is chosen and everyone gets to nominate the person who embodies it best. Get recognized, earn epic rewards, and become the next workplace legend!</h3>
          </div>

          <div className="relative">
            {/* Connection line */}
            <div className="absolute top-24 left-0 w-full h-0.5 bg-[#EDE6F8] hidden md:block"></div>

            <div className="grid gap-6 gap-y-12 md:grid-cols-4 relative px-4 sm:px-8 md:px-0">
              
              {/* Step 1 - Nomination */}
              <div className="group relative bg-[#EDE6F8] rounded-xl px-6 sm:px-8 md:px-4 py-5 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1">
                <div className="mt-6 text-center">
                  <div className="absolute -top-6 left-1/2 -translate-x-1/2 p-4 bg-[#9568DA] rounded-full flex items-center justify-center mx-auto mb-3 transition-colors">
                    <Users className="w-7 h-7 text-[#FEFEFF]" />
                  </div>
                  <p className="bg-[#FEFEFF] inline-block px-3 py-2 rounded-lg subtitle-2 mt-6">Game on 🚀</p>
                  <p className="body-2 leading-relaxed mt-2">
                    A new cycle kicks off with a key skill to reward
                  </p>
                </div>
              </div>

              {/* Step 2 - Selection */}
              <div className="group relative bg-[#EDE6F8] rounded-xl px-4 py-5 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1">
                <div className="mt-6 text-center">
                  <div className="absolute -top-6 left-1/2 -translate-x-1/2 p-4 bg-[#9568DA] rounded-full flex items-center justify-center mx-auto mb-3 transition-colors">
                    <UserCheck className="w-7 h-7 text-[#FEFEFF]" />
                  </div>
                  <p className="bg-[#FEFEFF] inline-block px-3 py-2 rounded-lg subtitle-2 mt-6">Cast your vote</p>
                  <p className="body-2 leading-relaxed mt-2">
                    Nominate the teammate who best embodies this skill
                  </p>
                </div>
              </div>

              {/* Step 3 - Results */}
              <div className="group relative bg-[#EDE6F8] rounded-xl px-4 py-5 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1">
                <div className="mt-6 text-center">
                  <div className="absolute -top-6 left-1/2 -translate-x-1/2 p-4 bg-[#9568DA] rounded-full flex items-center justify-center mx-auto mb-3 transition-colors">
                    <Megaphone className="w-7 h-7 text-[#FEFEFF]" />
                  </div>
                  <p className="bg-[#FEFEFF] inline-block px-3 py-2 rounded-lg subtitle-2 mt-6">Final vote</p>
                  <p className="body-2 leading-relaxed mt-2">
                    The Voting Committee selects the winner
                  </p>
                </div>
              </div>

              {/* Step 4 - Awards */}
              <div className="group relative bg-[#EDE6F8] rounded-xl px-4 py-5 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1">
                <div className="mt-6 text-center">
                  <div className="absolute -top-6 left-1/2 -translate-x-1/2 p-4 bg-[#9568DA] rounded-full flex items-center justify-center mx-auto mb-3 transition-colors">
                    <Award className="w-7 h-7 text-[#FEFEFF]" />
                  </div>
                  <p className="bg-[#FEFEFF] inline-block px-3 py-2 rounded-lg subtitle-2 mt-6">Celebrate</p>
                  <p className="body-2 leading-relaxed mt-2">
                    The Hero is honored and walks away with great perks
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Nomination Areas Section */}
        <div className="white-box">
          <div className="text-center mb-14">
            <h2 className="heading-2">Skills that make a Hero</h2>
            <h3 className="heading-3">Here are the key abilities that will be recognized and rewarded. Each month, one skill is selected as the focus — so step up, showcase your strengths, and earn your place among the heroes!</h3>
          </div>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {loading ? (
              <div className="md:col-span-2 text-center py-8 text-gray-600">
                Loading skills...
              </div>
            ) : nominationAreas.length > 0 ? (
              nominationAreas.map((area) => {
                const IconComponent = getIconComponent(area.icon);
      
                return (
                  <div key={area.id} className="transition-all">
                    {/* Header cliquable */}
                    <button
                      onClick={() => setOpenAreaId(openAreaId === area.id ? null : area.id)}
                      className={`w-full text-left p-2 bg-[#CDEAE7] hover:bg-[#9BD5CF] flex items-center gap-4 mb-0 focus:outline-none ${
                        openAreaId === area.id ? 'rounded-t-xl' : 'rounded-xl'
                      }`}
                    >
                      <div className="icons-white">
                        <IconComponent size={28} />
                      </div>
                      <p className="subtitle">{area.category}</p>
                    </button>
                
                    {/* Contenu affiché uniquement si ouvert */}
                    {openAreaId === area.id && (
                      <div className="p-2 space-y-3 bg-[#CDEAE7] rounded-b-xl">
                        {area.areas.map((subArea, idx) => (
                          <div key={idx} className="p-4 bg-[#E6F5F3] rounded-lg py-2">
                            <h4 className="subtitle-2 text-left">{subArea.title}</h4>
                            {subArea.description && (
                              <p className="body-2 text-left">{subArea.description}</p>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })
            ) : (
              <div className="md:col-span-2 text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
                <Award size={40} className="mx-auto text-gray-400 mb-4" />
                <h3 className="font-medium text-gray-900 mb-1">
                  No skills defined yet
                </h3>
                <p className="text-sm text-gray-600">
                  Key skills will be displayed here once they are created by the administrator
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}