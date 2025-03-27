export interface Employee {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  points: number;
  department: string;
  avatar: string;
  badges: Badge[];
  roles: Role[];
  client_id: string;
  name?: string; // Pour la compatibilité
  recognition_points?: {
    distributable_points: number;
    earned_points: number;
  };
}

// Ajouter une fonction utilitaire pour le nom complet
export const getFullName = (employee: Employee): string => {
  if (employee.name) return employee.name;
  return `${employee.first_name} ${employee.last_name}`.trim();
};

export interface Badge {
  id: string;
  name: string;
  icon: string;
  description: string;
  color: string;
}

export interface Role {
  id: string;
  name: 'User' | 'ExCom' | 'Admin';
  created_at?: string;
}

export interface Reward {
  id: string;
  name: string;
  description: string;
  pointsCost: number;
  image: string;
}

export interface Vote {
  id: string;
  voterId: string;
  votedForId: string;
  month: string;
  year: number;
}

export interface EmployeeOfTheMonth {
  employeeId: string;
  month: string;
  year: number;
  voteCount: number;
}

export interface Client {
  id: string;
  name: string;
  created_at: string;
  updated_at: string;
  employeeCount?: number;
}

export interface RecognitionProgram {
  id: string;
  name: string;
  start_date: string;
  end_date: string;
  points_per_user: number;
  created_at: string;
  updated_at: string;
}

export interface Recognition {
  id: string;
  program_id: string;
  sender_id: string;
  receiver_id: string;
  points: number;
  message: string;
  image_url?: string;
  tags: string[];
  is_private: boolean;
  created_at: string;
}

export interface RecognitionPoints {
  id: string;
  profile_id: string;
  program_id: string;
  distributable_points: number;
  earned_points: number;
  created_at: string;
  updated_at: string;
}