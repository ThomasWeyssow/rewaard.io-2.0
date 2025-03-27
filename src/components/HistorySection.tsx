import React from 'react';
import { Employee } from '../types';
import { Trophy, Building } from 'lucide-react';
import { useProfiles } from '../hooks/useProfiles';
import { formatDateToParisEN } from '../utils/dateUtils';

interface HistorySectionProps {
  employees: Employee[];
}

export function HistorySection({ employees }: HistorySectionProps) {
  const { winners, loading } = useProfiles();

  const getEmployee = (employeeId: string) => {
    return employees.find(emp => emp.id === employeeId);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-gray-600">Loading Heroes...</div>
      </div>
    );
  }
  
  return (
    <div className="container-large">
      <div className="white-box">
        <div>
          <h2 className="heading-2">
          Welcome to the Wall of Fame
          </h2>
          <h3 className="heading-3">Where the Heroes of the Month shine forever — will your name be next?</h3>
        </div>
          
        {/* Winner card */}
        <div className="grid-3-col">
          {winners.map((winner) => {
            const employee = getEmployee(winner.nominee_id);
            if (!employee) return null;
  
            return (
              <div 
                key={`${winner.cycle_id}`}
                className="flex flex-col items-center text-center bg-[#EDE6F8] rounded-xl p-6"
              >    
                {/* Avatar*/}
                <img
                  src={employee.avatar}
                  alt={employee.name}
                  className="w-32 h-32 rounded-full object-cover mb-4"
                />
                {/* Nom */}
                <h3 className="heading-3">{employee.name}</h3>       
                {/* Department */}
                <div className="flex items-center justify-center gap-2 body-2 mb-6">
                  <Building size={16} />
                  <p>{employee.department}</p>
                </div>
                {/* Hero of ... */}
                <div className="w-full rounded-lg bg-[#DBCEF3] py-2">
                    <p className="body text-[#4F03C1]">
                      🏆 Hero of {formatDateToParisEN(winner.created_at)}
                    </p>
                </div>                 
              </div>
            );
          })}
          {winners.length === 0 && (
            <div className="text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
              <Trophy size={40} className="mx-auto text-gray-400 mb-4" />
              <h3 className="font-medium text-gray-900 mb-1">
                No Heroes crowned yet
              </h3>
              <p className="text-sm text-gray-600">
                Be the first to make history on the Wall of Fame by achieving outstanding performance. Who will rise to the challenge?
              </p>
            </div>
          )}
        </div>
      </div>
     </div> 
  );
}