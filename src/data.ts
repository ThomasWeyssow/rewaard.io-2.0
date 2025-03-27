import { Badge, Reward } from './types';

export const badges: Badge[] = [
  {
    id: '1c8f2b6a-7d3e-4981-8f8a-5c0b68f2583b',
    name: 'Respectueux',
    icon: 'heart-handshake',
    description: 'Fait preuve d\'un grand respect envers ses collègues',
    color: 'emerald'
  },
  {
    id: '2d9f3c7b-8e4f-5092-9f9b-6d1c79f3694c',
    name: 'Ponctuel',
    icon: 'clock',
    description: 'Toujours à l\'heure et respectueux des délais',
    color: 'blue'
  },
  {
    id: '3e0f4d8c-9f5f-6103-a90c-7e2d80f4705d',
    name: 'Innovateur',
    icon: 'lightbulb',
    description: 'Propose régulièrement des idées innovantes',
    color: 'amber'
  },
  {
    id: '4f1e5e9d-0f6a-7114-b81d-8f3e91f5816e',
    name: 'Esprit d\'équipe',
    icon: 'users',
    description: 'Excellent travail d\'équipe et collaboration',
    color: 'purple'
  }
];

export const mockRewards: Reward[] = [
  {
    id: '1',
    name: 'Jour de congé supplémentaire',
    description: 'Profitez d\'une journée de repos bien méritée',
    pointsCost: 1000,
    image: 'https://images.unsplash.com/photo-1602192509154-0b900ee1f851?w=400',
  },
  {
    id: '2',
    name: 'Bon d\'achat 50€',
    description: 'Utilisable dans plusieurs enseignes partenaires',
    pointsCost: 500,
    image: 'https://images.unsplash.com/photo-1559589689-577aabd1db4f?w=400',
  },
  {
    id: '3',
    name: 'Formation au choix',
    description: 'Accédez à une formation professionnelle de votre choix',
    pointsCost: 2000,
    image: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400',
  },
];