/*
  # Insert default badges

  1. Changes
    - Insert the four default badges into the badges table
    - Use the same UUIDs as defined in the frontend data
*/

-- Insérer les badges avec les mêmes UUIDs que dans le frontend
INSERT INTO badges (id, name, icon, description, color)
VALUES
  (
    '1c8f2b6a-7d3e-4981-8f8a-5c0b68f2583b',
    'Respectueux',
    'heart-handshake',
    'Fait preuve d''un grand respect envers ses collègues',
    'emerald'
  ),
  (
    '2d9f3c7b-8e4f-5092-9f9b-6d1c79f3694c',
    'Ponctuel',
    'clock',
    'Toujours à l''heure et respectueux des délais',
    'blue'
  ),
  (
    '3e0f4d8c-9f5f-6103-a90c-7e2d80f4705d',
    'Innovateur',
    'lightbulb',
    'Propose régulièrement des idées innovantes',
    'amber'
  ),
  (
    '4f1e5e9d-0f6a-7114-b81d-8f3e91f5816e',
    'Esprit d''équipe',
    'users',
    'Excellent travail d''équipe et collaboration',
    'purple'
  )
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  icon = EXCLUDED.icon,
  description = EXCLUDED.description,
  color = EXCLUDED.color;