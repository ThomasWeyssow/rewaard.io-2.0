import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { useProfiles } from '../../hooks/useProfiles';
import { useRecognitions } from '../../hooks/useRecognitions';
import { Search, Image, Tag, Lock, Globe, Award, ArrowLeft, X } from 'lucide-react';
import TextareaAutosize from 'react-textarea-autosize';
import { getFullName } from '../../types';

const AVAILABLE_POINTS = [0, 1, 2, 3, 5];
const DEFAULT_TAGS = ['Leadership', 'Innovation', 'Teamwork', 'Excellence', 'Initiative'];

interface Step1Props {
  selectedUserId: string | null;
  onSelectUser: (userId: string) => void;
  onBack: () => void;
}

function Step1({ selectedUserId, onSelectUser, onBack }: Step1Props) {
  const { profiles } = useProfiles();
  const [searchQuery, setSearchQuery] = useState('');

  const filteredProfiles = profiles.filter(profile => {
    const searchString = `${getFullName(profile)} ${profile.department}`.toLowerCase();
    return searchString.includes(searchQuery.toLowerCase());
  });

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <button
          onClick={onBack}
          className="flex items-center gap-2 text-gray-600 hover:text-gray-900"
        >
          <ArrowLeft size={20} />
          Back to Feed
        </button>
      </div>

      <h2 className="text-2xl font-bold text-gray-900 mb-6">
        Who do you want to recognize?
      </h2>

      <div className="relative mb-6">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <Search className="h-5 w-5 text-gray-400" />
        </div>
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search by name or department..."
          className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
        />
      </div>

      <div className="grid gap-4">
        {filteredProfiles.map(profile => (
          <button
            key={profile.id}
            onClick={() => onSelectUser(profile.id)}
            className={`flex items-center gap-4 p-4 rounded-lg transition-colors ${
              selectedUserId === profile.id
                ? 'bg-indigo-50 border-2 border-indigo-500'
                : 'bg-white border border-gray-200 hover:border-indigo-200'
            }`}
          >
            <img
              src={profile.avatar}
              alt={getFullName(profile)}
              className="w-12 h-12 rounded-full object-cover"
            />
            <div className="text-left">
              <div className="font-medium">{getFullName(profile)}</div>
              <div className="text-sm text-gray-500">{profile.department}</div>
            </div>
          </button>
        ))}

        {filteredProfiles.length === 0 && (
          <div className="text-center py-8 bg-gray-50 rounded-lg">
            <p className="text-gray-600">No users found matching your search</p>
          </div>
        )}
      </div>
    </div>
  );
}

interface Step2Props {
  receiverId: string;
  onBack: () => void;
  onSubmit: (data: {
    message: string;
    points: number;
    tags: string[];
    isPrivate: boolean;
    imageUrl?: string;
  }) => void;
  availablePoints: number;
  programEndDate: string;
}

function Step2({ receiverId, onBack, onSubmit, availablePoints, programEndDate }: Step2Props) {
  const { profiles } = useProfiles();
  const receiver = profiles.find(p => p.id === receiverId);
  
  const [message, setMessage] = useState('');
  const [points, setPoints] = useState(0);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [isPrivate, setIsPrivate] = useState(false);
  const [imageUrl, setImageUrl] = useState('');
  const [customPoints, setCustomPoints] = useState('');

  if (!receiver) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      message,
      points: customPoints ? parseInt(customPoints, 10) : points,
      tags: selectedTags,
      isPrivate,
      imageUrl: imageUrl || undefined
    });
  };

  const toggleTag = (tag: string) => {
    setSelectedTags(prev =>
      prev.includes(tag)
        ? prev.filter(t => t !== tag)
        : [...prev, tag]
    );
  };

  const handleCustomPoints = (value: string) => {
    const numValue = parseInt(value, 10);
    if (value === '' || (numValue >= 0 && numValue <= availablePoints)) {
      setCustomPoints(value);
      setPoints(0);
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <button
          onClick={onBack}
          className="flex items-center gap-2 text-gray-600 hover:text-gray-900"
        >
          <ArrowLeft size={20} />
          Back
        </button>
      </div>

      <div className="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 className="text-2xl font-bold text-gray-900 mb-4">
          Recognize {getFullName(receiver)}
        </h2>

        <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg mb-6">
          <img
            src={receiver.avatar}
            alt={getFullName(receiver)}
            className="w-12 h-12 rounded-full object-cover"
          />
          <div>
            <div className="font-medium">{getFullName(receiver)}</div>
            <div className="text-sm text-gray-500">{receiver.department}</div>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Points Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Points to Give ({availablePoints} available)
              <span className="text-sm text-gray-500 ml-2">
                Program ends on {new Date(programEndDate).toLocaleDateString()}
              </span>
            </label>
            <div className="grid grid-cols-6 gap-2 mb-2">
              {AVAILABLE_POINTS.map(value => (
                <button
                  key={value}
                  type="button"
                  onClick={() => {
                    setPoints(value);
                    setCustomPoints('');
                  }}
                  className={`py-2 px-4 rounded-lg text-sm font-medium transition-colors ${
                    points === value && customPoints === ''
                      ? 'bg-indigo-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  } ${value > availablePoints ? 'opacity-50 cursor-not-allowed' : ''}`}
                  disabled={value > availablePoints}
                >
                  {value} pts
                </button>
              ))}
              <div className="relative">
                <input
                  type="number"
                  value={customPoints}
                  onChange={(e) => handleCustomPoints(e.target.value)}
                  placeholder="Custom"
                  min="0"
                  max={availablePoints}
                  className="block w-full py-2 px-4 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
                />
              </div>
            </div>
          </div>

          {/* Message */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Message
              <span className="text-red-500 ml-1">*</span>
            </label>
            <TextareaAutosize
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              minRows={3}
              className="block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Why do you want to recognize this person?"
              required
            />
          </div>

          {/* Image URL */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Image URL (optional)
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Image className="h-5 w-5 text-gray-400" />
              </div>
              <input
                type="url"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://..."
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
          </div>

          {/* Tags */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Tags
            </label>
            <div className="flex flex-wrap gap-2">
              {DEFAULT_TAGS.map(tag => (
                <button
                  key={tag}
                  type="button"
                  onClick={() => toggleTag(tag)}
                  className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-sm font-medium transition-colors ${
                    selectedTags.includes(tag)
                      ? 'bg-indigo-100 text-indigo-800'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  <Tag size={14} />
                  {tag}
                  {selectedTags.includes(tag) && (
                    <X size={14} className="ml-1" />
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Visibility */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Visibility
            </label>
            <div className="flex gap-4">
              <button
                type="button"
                onClick={() => setIsPrivate(false)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  !isPrivate
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                <Globe size={16} />
                Public
              </button>
              <button
                type="button"
                onClick={() => setIsPrivate(true)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  isPrivate
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                <Lock size={16} />
                Private
              </button>
            </div>
          </div>

          {/* Submit */}
          <div className="flex justify-end gap-4 pt-4 border-t">
            <button
              type="button"
              onClick={onBack}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
            >
              Back
            </button>
            <button
              type="submit"
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={!message.trim()}
            >
              <Award size={20} />
              Recognize
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export function RecognitionForm() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { profiles } = useProfiles();
  const { createRecognition } = useRecognitions();
  const [step, setStep] = useState(1);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const currentUser = user ? profiles.find(p => p.id === user.id) : undefined;
  const availablePoints = currentUser?.recognition_points?.distributable_points || 0;

  const handleBack = () => {
    if (step === 1) {
      navigate('/feed');
    } else {
      setStep(1);
    }
  };

  const handleSelectUser = (userId: string) => {
    setSelectedUserId(userId);
    setStep(2);
  };

  const handleSubmit = async (data: {
    message: string;
    points: number;
    tags: string[];
    isPrivate: boolean;
    imageUrl?: string;
  }) => {
    if (!user || !selectedUserId) return;

    try {
      setError(null);
      await createRecognition({
        receiverId: selectedUserId,
        ...data
      });
      navigate('/feed');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    }
  };

  // TODO: Get these values from the active program
  const programEndDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

  return (
    <div className="py-8">
      {error && (
        <div className="max-w-2xl mx-auto mb-6">
          <div className="p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            {error}
          </div>
        </div>
      )}

      {step === 1 ? (
        <Step1
          selectedUserId={selectedUserId}
          onSelectUser={handleSelectUser}
          onBack={handleBack}
        />
      ) : (
        selectedUserId && (
          <Step2
            receiverId={selectedUserId}
            onBack={handleBack}
            onSubmit={handleSubmit}
            availablePoints={availablePoints}
            programEndDate={programEndDate}
          />
        )
      )}
    </div>
  );
}