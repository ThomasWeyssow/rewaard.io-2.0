import React, { useState, useEffect } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useRecognitions } from '../../hooks/useRecognitions';
import { useProfiles } from '../../hooks/useProfiles';
import { Search, Image, Tag, Lock, Globe, Award } from 'lucide-react';
import { Link } from 'react-router-dom';
import { getFullName } from '../../types';

export function RecognitionFeed() {
  const { user } = useAuth();
  const { recognitions, loading: recognitionsLoading } = useRecognitions();
  const { profiles, loading: profilesLoading } = useProfiles();
  const [searchQuery, setSearchQuery] = useState('');

  const filteredRecognitions = recognitions.filter(recognition => {
    const sender = profiles.find(p => p.id === recognition.sender_id);
    const receiver = profiles.find(p => p.id === recognition.receiver_id);
    
    if (!sender || !receiver) return false;

    const searchString = `${getFullName(sender)} ${getFullName(receiver)} ${recognition.message} ${recognition.tags.join(' ')}`.toLowerCase();
    return searchString.includes(searchQuery.toLowerCase());
  });

  if (recognitionsLoading || profilesLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-gray-600">Loading recognitions...</div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto px-4">
      {/* Search and Create */}
      <div className="flex flex-col sm:flex-row gap-4 mb-8">
        <div className="flex-1 relative">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="h-5 w-5 text-gray-400" />
          </div>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search recognitions..."
            className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
        </div>
        <Link
          to="/recognize"
          className="flex items-center justify-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
        >
          <Award size={20} />
          Recognize Someone
        </Link>
      </div>

      {/* Recognition Feed */}
      <div className="space-y-6">
        {filteredRecognitions.map(recognition => {
          const sender = profiles.find(p => p.id === recognition.sender_id);
          const receiver = profiles.find(p => p.id === recognition.receiver_id);
          
          if (!sender || !receiver) return null;

          return (
            <div 
              key={recognition.id} 
              className={`bg-white rounded-lg shadow-md overflow-hidden ${
                recognition.is_private ? 'border-2 border-amber-200' : ''
              }`}
            >
              {/* Header */}
              <div className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-4">
                    <img
                      src={sender.avatar}
                      alt={getFullName(sender)}
                      className="w-12 h-12 rounded-full object-cover"
                    />
                    <div>
                      <div className="font-medium">{getFullName(sender)}</div>
                      <div className="text-sm text-gray-500">{sender.department}</div>
                    </div>
                    <div className="text-gray-400 mx-2">→</div>
                    <div className="flex items-center gap-4">
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
                  </div>
                  {recognition.points > 0 && (
                    <div className="flex items-center gap-1 px-3 py-1 bg-green-100 text-green-800 rounded-full">
                      <Award size={16} />
                      <span>{recognition.points} points</span>
                    </div>
                  )}
                </div>

                {/* Message */}
                <p className="text-gray-700 whitespace-pre-wrap">{recognition.message}</p>

                {/* Image */}
                {recognition.image_url && (
                  <div className="mt-4">
                    <img
                      src={recognition.image_url}
                      alt="Recognition"
                      className="rounded-lg max-h-96 w-full object-cover"
                    />
                  </div>
                )}

                {/* Tags and Visibility */}
                <div className="mt-4 flex flex-wrap items-center gap-2">
                  {recognition.tags.map((tag, index) => (
                    <span
                      key={index}
                      className="inline-flex items-center gap-1 px-2 py-1 bg-indigo-100 text-indigo-800 text-sm rounded-full"
                    >
                      <Tag size={14} />
                      {tag}
                    </span>
                  ))}
                  <span className="inline-flex items-center gap-1 px-2 py-1 bg-gray-100 text-gray-600 text-sm rounded-full ml-auto">
                    {recognition.is_private ? (
                      <>
                        <Lock size={14} />
                        Private
                      </>
                    ) : (
                      <>
                        <Globe size={14} />
                        Public
                      </>
                    )}
                  </span>
                </div>
              </div>
            </div>
          );
        })}

        {filteredRecognitions.length === 0 && (
          <div className="text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
            <Award size={40} className="mx-auto text-gray-400 mb-4" />
            <h3 className="font-medium text-gray-900 mb-1">
              No recognitions found
            </h3>
            <p className="text-sm text-gray-600 mb-4">
              {searchQuery
                ? "No recognitions match your search"
                : "Be the first to recognize someone's great work!"}
            </p>
            {!searchQuery && (
              <Link
                to="/recognize"
                className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
              >
                <Award size={20} />
                Recognize Someone
              </Link>
            )}
          </div>
        )}
      </div>
    </div>
  );
}