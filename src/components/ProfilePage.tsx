import React, { useState, useRef } from 'react';
import { Employee, Reward } from '../types';
import { Trophy, Gift, Camera, AlertCircle, Mail } from 'lucide-react';
import { useProfiles } from '../hooks/useProfiles';
import { useStorage } from '../hooks/useStorage';
import { formatDateToParisEN } from '../utils/dateUtils';
import { useRecognitions } from '../hooks/useRecognitions';

interface ProfilePageProps {
  employee: Employee;
  rewards: Reward[];
  onClose: () => void;
}

export function ProfilePage({ employee, rewards, onClose }: ProfilePageProps) {
  const { winners, loading, updateAvatar } = useProfiles();
  const { uploadProfilePhoto, uploading } = useStorage();
  const employeeWins = winners.filter(win => win.nominee_id === employee.id);
  const unlockedRewards = rewards.filter(reward => reward.pointsCost <= employee.points);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [error, setError] = useState<string>('');
  const [isEditingEmail, setIsEditingEmail] = useState(false);
  const [newEmail, setNewEmail] = useState(employee.email);
  const [emailError, setEmailError] = useState('');
  const [localAvatar, setLocalAvatar] = useState<string>(employee.avatar);

  const handlePhotoChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      setError('');

      // Create temporary URL for preview
      const tempUrl = URL.createObjectURL(file);
      setLocalAvatar(tempUrl);

      // Upload the new photo
      const newAvatarUrl = await uploadProfilePhoto(file, employee.id);
      
      // Update profile with new URL
      await updateAvatar(employee.id, newAvatarUrl);
      
      // Update local avatar with final URL
      setLocalAvatar(newAvatarUrl);
      
      // Clean up temporary URL
      URL.revokeObjectURL(tempUrl);
    } catch (err) {
      // Revert to original avatar on error
      setLocalAvatar(employee.avatar);
      setError(err instanceof Error ? err.message : 'An error occurred while updating the photo');
    }
  };

  const handleEmailUpdate = async () => {
    try {
      // Email update logic to be implemented
      setIsEditingEmail(false);
      setEmailError('');
    } catch (error) {
      setEmailError("An error occurred while updating the email");
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col">
      <div className="bg-indigo-600 px-4 py-4">
        <div className="container mx-auto">
          <button
            onClick={onClose}
            className="text-white hover:text-gray-200 transition-colors"
          >
            ← Back
          </button>
        </div>
      </div>

      <div className="flex-1 container mx-auto px-4 py-6">
        {/* Profile Header */}
        <div className="bg-white rounded-lg shadow-md overflow-hidden mb-6">
          <div className="p-6">
            <div className="flex flex-col sm:flex-row items-center gap-6">
              <div className="relative">
                <img
                  src={localAvatar}
                  alt={employee.name}
                  className="w-24 h-24 rounded-full object-cover"
                />
                <button
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploading}
                  className={`absolute bottom-0 right-0 p-2 rounded-full transition-colors ${
                    uploading
                      ? 'bg-indigo-400 cursor-wait'
                      : 'bg-indigo-600 hover:bg-indigo-700'
                  } text-white`}
                  title="Change profile photo"
                >
                  <Camera size={16} />
                </button>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/jpeg,image/png,image/gif,image/webp"
                  onChange={handlePhotoChange}
                  className="hidden"
                  disabled={uploading}
                />
              </div>
              <div>
                <h1 className="text-2xl font-bold">{employee.first_name} {employee.last_name}</h1>
                <p className="text-gray-600">{employee.department}</p>

                {/* Email field */}
                <div className="mt-4">
                  {isEditingEmail ? (
                    <div className="space-y-2 max-w-md mx-auto sm:mx-0">
                      <div className="flex items-center bg-white rounded-lg border">
                        <Mail className="text-gray-400 ml-3" size={20} />
                        <input
                          type="email"
                          value={newEmail}
                          onChange={(e) => setNewEmail(e.target.value)}
                          className="flex-1 px-3 py-2 focus:outline-none"
                          placeholder="Your email"
                        />
                      </div>
                      <div className="flex flex-col sm:flex-row gap-2">
                        <button
                          onClick={handleEmailUpdate}
                          className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
                        >
                          Save
                        </button>
                        <button
                          onClick={() => {
                            setIsEditingEmail(false);
                            setNewEmail(employee.email);
                            setEmailError('');
                          }}
                          className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                        >
                          Cancel
                        </button>
                      </div>
                      {emailError && (
                        <p className="text-sm text-red-600">{emailError}</p>
                      )}
                    </div>
                  ) : (
                    <div className="flex items-center justify-center sm:justify-start gap-2">
                      <Mail className="text-gray-400" size={20} />
                      <span className="text-gray-700 break-all">{employee.email}</span>
                      <button
                        onClick={() => setIsEditingEmail(true)}
                        className="text-sm text-indigo-600 hover:text-indigo-700"
                      >
                        Edit
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
            {error && (
              <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
                <AlertCircle size={20} />
                {error}
              </div>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Recognition Points */}
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Recognition Points</h2>
            <div className="space-y-4">
              {/* Points to Distribute */}
              {employee.recognition_points?.distributable_points > 0 && (
                <div className="flex items-center gap-4 p-4 bg-indigo-50 rounded-lg">
                  <div className="p-2 rounded-full bg-indigo-100 text-indigo-600">
                    <Gift size={24} />
                  </div>
                  <div>
                    <h3 className="font-semibold text-indigo-900">Points to Distribute</h3>
                    <p className="text-indigo-700">{employee.recognition_points.distributable_points} points available</p>
                  </div>
                </div>
              )}

              {/* Points Earned */}
              {employee.recognition_points?.earned_points > 0 && (
                <div className="flex items-center gap-4 p-4 bg-emerald-50 rounded-lg">
                  <div className="p-2 rounded-full bg-emerald-100 text-emerald-600">
                    <Trophy size={24} />
                  </div>
                  <div>
                    <h3 className="font-semibold text-emerald-900">Points Earned</h3>
                    <p className="text-emerald-700">{employee.recognition_points.earned_points} points received</p>
                  </div>
                </div>
              )}

              {(!employee.recognition_points?.distributable_points && !employee.recognition_points?.earned_points) && (
                <p className="text-gray-500 text-center py-4">
                  No recognition points yet
                </p>
              )}
            </div>
          </div>

          {/* Unlocked Rewards */}
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Unlocked Rewards</h2>
            <div className="space-y-4">
              {unlockedRewards.map(reward => (
                <div
                  key={reward.id}
                  className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg"
                >
                  <div className="flex-shrink-0">
                    <Gift className="text-green-600" size={24} />
                  </div>
                  <div>
                    <h3 className="font-semibold">{reward.name}</h3>
                    <p className="text-sm text-gray-600">{reward.description}</p>
                    <p className="text-sm text-green-600 mt-1">
                      {reward.pointsCost} points
                    </p>
                  </div>
                </div>
              ))}
              {unlockedRewards.length === 0 && (
                <p className="text-gray-500 text-center py-4">
                  No rewards unlocked yet
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Employee of the Month History */}
        <div className="mt-6 bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4">Employee of the Month History</h2>
          <div className="space-y-4">
            {employeeWins.map(win => (
              <div
                key={win.cycle_id}
                className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg"
              >
                <div className="p-2 rounded-full bg-yellow-100">
                  <Trophy className="text-yellow-600" size={24} />
                </div>
                <div>
                  <h3 className="font-semibold">
                    Hero of {formatDateToParisEN(win.created_at)}
                  </h3>
                </div>
              </div>
            ))}
            {employeeWins.length === 0 && (
              <p className="text-gray-500 text-center py-4">
                Not yet elected as employee of the month
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}