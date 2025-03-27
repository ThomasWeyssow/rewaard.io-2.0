/*
  # Ajout des nouveaux employés et badges

  1. Nouveaux Employés
    - Lucas Moreau (Designer)
    - Emma Laurent (Commercial)
    - Alexandre Petit (Développeur)
    - Julie Roux (Marketing)

  2. Badges
    - Respectueux
    - Ponctuel
    - Innovateur
    - Esprit d'équipe

  3. Attribution des badges aux employés
*/

-- Insertion des badges de base s'ils n'existent pas déjà
DO $$
DECLARE
  badge_respectueux uuid;
  badge_ponctuel uuid;
  badge_innovateur uuid;
  badge_esprit_equipe uuid;
  lucas_id uuid;
  emma_id uuid;
  alexandre_id uuid;
  julie_id uuid;
BEGIN
  -- Création des badges avec des UUID
  INSERT INTO badges (name, icon, description, color)
  VALUES
    ('Respectueux', 'heart-handshake', 'Fait preuve d''un grand respect envers ses collègues', 'emerald')
  RETURNING id INTO badge_respectueux;

  INSERT INTO badges (name, icon, description, color)
  VALUES
    ('Ponctuel', 'clock', 'Toujours à l''heure et respectueux des délais', 'blue')
  RETURNING id INTO badge_ponctuel;

  INSERT INTO badges (name, icon, description, color)
  VALUES
    ('Innovateur', 'lightbulb', 'Propose régulièrement des idées innovantes', 'amber')
  RETURNING id INTO badge_innovateur;

  INSERT INTO badges (name, icon, description, color)
  VALUES
    ('Esprit d''équipe', 'users', 'Excellent travail d''équipe et collaboration', 'purple')
  RETURNING id INTO badge_esprit_equipe;

  -- Lucas Moreau
  INSERT INTO auth.users (id, email, encrypted_password, raw_user_meta_data)
  VALUES (
    gen_random_uuid(),
    'lucas.moreau@company.com',
    crypt('LucasM2024!', gen_salt('bf')),
    jsonb_build_object('name', 'Lucas Moreau', 'department', 'Design')
  )
  RETURNING id INTO lucas_id;

  INSERT INTO profiles (id, email, name, department, points, avatar_url)
  VALUES (
    lucas_id,
    'lucas.moreau@company.com',
    'Lucas Moreau',
    'Design',
    280,
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150'
  );

  -- Emma Laurent
  INSERT INTO auth.users (id, email, encrypted_password, raw_user_meta_data)
  VALUES (
    gen_random_uuid(),
    'emma.laurent@company.com',
    crypt('EmmaL2024!', gen_salt('bf')),
    jsonb_build_object('name', 'Emma Laurent', 'department', 'Commercial')
  )
  RETURNING id INTO emma_id;

  INSERT INTO profiles (id, email, name, department, points, avatar_url)
  VALUES (
    emma_id,
    'emma.laurent@company.com',
    'Emma Laurent',
    'Commercial',
    650,
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150'
  );

  -- Alexandre Petit
  INSERT INTO auth.users (id, email, encrypted_password, raw_user_meta_data)
  VALUES (
    gen_random_uuid(),
    'alexandre.petit@company.com',
    crypt('AlexP2024!', gen_salt('bf')),
    jsonb_build_object('name', 'Alexandre Petit', 'department', 'Développement')
  )
  RETURNING id INTO alexandre_id;

  INSERT INTO profiles (id, email, name, department, points, avatar_url)
  VALUES (
    alexandre_id,
    'alexandre.petit@company.com',
    'Alexandre Petit',
    'Développement',
    480,
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150'
  );

  -- Julie Roux
  INSERT INTO auth.users (id, email, encrypted_password, raw_user_meta_data)
  VALUES (
    gen_random_uuid(),
    'julie.roux@company.com',
    crypt('JulieR2024!', gen_salt('bf')),
    jsonb_build_object('name', 'Julie Roux', 'department', 'Marketing')
  )
  RETURNING id INTO julie_id;

  INSERT INTO profiles (id, email, name, department, points, avatar_url)
  VALUES (
    julie_id,
    'julie.roux@company.com',
    'Julie Roux',
    'Marketing',
    390,
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'
  );

  -- Attribution des badges
  -- Lucas Moreau (Innovateur, Esprit d'équipe)
  INSERT INTO profile_badges (profile_id, badge_id)
  VALUES
    (lucas_id, badge_innovateur),
    (lucas_id, badge_esprit_equipe);

  -- Emma Laurent (Respectueux, Ponctuel, Esprit d'équipe)
  INSERT INTO profile_badges (profile_id, badge_id)
  VALUES
    (emma_id, badge_respectueux),
    (emma_id, badge_ponctuel),
    (emma_id, badge_esprit_equipe);

  -- Alexandre Petit (Ponctuel, Innovateur)
  INSERT INTO profile_badges (profile_id, badge_id)
  VALUES
    (alexandre_id, badge_ponctuel),
    (alexandre_id, badge_innovateur);

  -- Julie Roux (Respectueux, Esprit d'équipe)
  INSERT INTO profile_badges (profile_id, badge_id)
  VALUES
    (julie_id, badge_respectueux),
    (julie_id, badge_esprit_equipe);
END $$;