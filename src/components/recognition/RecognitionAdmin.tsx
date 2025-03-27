import React, { useState, useEffect } from 'react';
import { useRecognitionPrograms } from '../../hooks/useRecognitionPrograms';
import { useProfiles } from '../../hooks/useProfiles';
import { useSettings } from '../../hooks/useSettings';
import { Calendar, Users, Award, Plus, Euro } from 'lucide-react';

export function RecognitionAdmin() {
  const { createProgram, programs, loading, error } = useRecognitionPrograms();
  const { profiles } = useProfiles();
  const [name, setName] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [pointsPerUser, setPointsPerUser] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !startDate || !endDate || !pointsPerUser) return;

    try {
      setSaving(true);
      await createProgram({
        name,
        startDate,
        endDate,
        pointsPerUser: parseInt(pointsPerUser, 10)
      });
      
      // Reset form
      setName('');
      setStartDate('');
      setEndDate('');
      setPointsPerUser('');
    } catch (err) {
      console.error('Error creating program:', err);
    } finally {
      setSaving(false);
    }
  };

  const totalPoints = profiles.length * parseInt(pointsPerUser || '0', 10);
  const totalEuros = totalPoints; // 1 point = 1 euro

  return (
    <div className="max-w-4xl mx-auto px-4">
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">
          Create Recognition Program
        </h2>

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
            <Award size={20} />
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Program Name */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Program Name
              <span className="text-red-500 ml-1">*</span>
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Q1 2025 Recognition Program"
              required
            />
          </div>

          {/* Dates */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Start Date
                <span className="text-red-500 ml-1">*</span>
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Calendar className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  required
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                End Date
                <span className="text-red-500 ml-1">*</span>
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Calendar className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  required
                  min={startDate}
                />
              </div>
            </div>
          </div>

          {/* Points Configuration */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Points per User
              <span className="text-red-500 ml-1">*</span>
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Award className="h-5 w-5 text-gray-400" />
              </div>
              <input
                type="number"
                value={pointsPerUser}
                onChange={(e) => setPointsPerUser(e.target.value)}
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="100"
                min="0"
                required
              />
            </div>
          </div>

          {/* Total Points Summary */}
          <div className="p-4 bg-gray-50 rounded-lg space-y-2">
            <div className="flex items-center gap-2 text-gray-600">
              <Users size={20} />
              <span>{profiles.length} users</span>
              <span>×</span>
              <Award size={20} />
              <span>{pointsPerUser || 0} points each</span>
              <span>=</span>
              <span className="font-bold text-gray-900">{totalPoints} total points</span>
            </div>
            <div className="flex items-center gap-2 text-gray-600">
              <Euro size={20} />
              <span>Budget equivalent:</span>
              <span className="font-bold text-gray-900">{totalEuros} €</span>
              <span className="text-sm text-gray-500">(1 point = 1 €)</span>
            </div>
          </div>

          {/* Submit */}
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={saving || !name || !startDate || !endDate || !pointsPerUser}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-white transition-colors ${
                saving || !name || !startDate || !endDate || !pointsPerUser
                  ? 'bg-indigo-400 cursor-not-allowed'
                  : 'bg-indigo-600 hover:bg-indigo-700'
              }`}
            >
              <Award size={20} />
              {saving ? 'Creating Program...' : 'Create Program'}
            </button>
          </div>
        </form>

        {/* List of Programs */}
        <div className="mt-12 border-t pt-8">
          <h3 className="text-xl font-semibold text-gray-900 mb-6">Recognition Programs</h3>
          <div className="space-y-6">
            {loading ? (
              <div className="text-center py-8 text-gray-600">Loading programs...</div>
            ) : programs.length > 0 ? (
              programs.map(program => {
                const programTotalPoints = profiles.length * program.points_per_user;
                const programTotalEuros = programTotalPoints;
                const isActive = new Date(program.start_date) <= new Date() && new Date(program.end_date) >= new Date();

                return (
                  <div 
                    key={program.id}
                    className={`p-4 rounded-lg border ${
                      isActive ? 'bg-green-50 border-green-200' : 'bg-gray-50 border-gray-200'
                    }`}
                  >
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                      <div>
                        <h4 className="font-semibold text-gray-900">{program.name}</h4>
                        <div className="flex items-center gap-4 mt-2 text-sm text-gray-600">
                          <div className="flex items-center gap-1">
                            <Calendar size={16} />
                            <span>
                              {new Date(program.start_date).toLocaleDateString()} - {new Date(program.end_date).toLocaleDateString()}
                            </span>
                          </div>
                          <div className="flex items-center gap-1">
                            <Award size={16} />
                            <span>{program.points_per_user} points/user</span>
                          </div>
                        </div>
                      </div>
                      <div className="flex flex-col items-end">
                        <div className="flex items-center gap-2 text-gray-900">
                          <span className="font-semibold">{programTotalPoints} total points</span>
                          <span className="text-gray-400">|</span>
                          <span className="font-semibold">{programTotalEuros} €</span>
                        </div>
                        <div className="text-sm text-gray-500">
                          {isActive ? (
                            <span className="text-green-600">Active</span>
                          ) : new Date(program.start_date) > new Date() ? (
                            <span className="text-blue-600">Upcoming</span>
                          ) : (
                            <span className="text-gray-600">Completed</span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })
            ) : (
              <div className="text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
                <Award size={40} className="mx-auto text-gray-400 mb-4" />
                <h3 className="font-medium text-gray-900 mb-1">
                  No recognition programs yet
                </h3>
                <p className="text-sm text-gray-600 mb-4">
                  Create your first recognition program to start rewarding your team
                </p>
                <button
                  onClick={() => document.querySelector('form')?.scrollIntoView({ behavior: 'smooth' })}
                  className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
                >
                  <Plus size={20} />
                  Create Program
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}