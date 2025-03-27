import React from 'react';
import { Calendar } from 'lucide-react';
import type { NominationArea } from '../../types';
import { formatDateToParisEN } from '../../utils/dateUtils';

interface OngoingNominationInfoProps {
  ongoingCycleDates?: {
    start: string;
    end: string;
  } | null;
  ongoingArea?: NominationArea | null;
}

export function OngoingNominationInfo({ 
  ongoingCycleDates,
  ongoingArea
}: OngoingNominationInfoProps) {
  if (!ongoingCycleDates?.start || !ongoingArea) {
    return (
     <div className="container-large">
      <div className="purple-box">
        <h2 className="heading-2">No Hero Quest ... for now!</h2>
        <h3 className="heading-3 mb-0">Hang tight - you'll get your chance to nominate again when the next cycle starts</h3>
      </div>
      </div> 
    );
  }

  return (
  <div className="container-large">
    <div className="purple-box">
        
        <h2 className="heading-2">This cycle, it's all about <span className="text-[#4F03C1]">{ongoingArea.category}</span>
        </h2>

        <div className="inline-flex items-center px-4 py-3 rounded-xl bg-[#FEFEFF] text-[#100127] text-sm font-medium gap-2 mb-8">
          <Calendar size={16} />
          <span>
            From {formatDateToParisEN(ongoingCycleDates.start)} to {formatDateToParisEN(ongoingCycleDates.end)}
          </span>
        </div>   
      
        <div className="flex flex-col items-center"> 
          <div className="flex flex-wrap gap-3 justify-center">
            {ongoingArea.areas.map((area, index) => (
              <div 
                key={index}
                className="p-4 bg-[#DBCEF3] rounded-xl flex flex-col w-[300px]"
              >
                <h4 className="subtitle-2">{area.title}</h4>
                {area.description && (
                  <p className="body-2">{area.description}</p>
                )}
              </div>
            ))}
          </div>
        </div>
    </div>
  </div>
  );
}