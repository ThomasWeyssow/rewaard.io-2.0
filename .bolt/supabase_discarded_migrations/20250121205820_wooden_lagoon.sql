-- Ajouter Nicolas Devaux
WITH nicolas AS (
  INSERT INTO auth.users (
    email,
    encrypted_password,
    raw_user_meta_data
  ) VALUES (
    'nicolas.devaux@company.com',
    crypt('NicolasD2024!', gen_salt('bf')),
    jsonb_build_object(
      'name', 'Nicolas Devaux',
      'department', 'Développement'
    )
  ) RETURNING id
)
INSERT INTO profiles (
  id,
  email,
  name,
  department,
  points,
  avatar_url
) 
SELECT 
  id,
  'nicolas.devaux@company.com',
  'Nicolas Devaux',
  'Développement',
  300,
  'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150'
FROM nicolas;

-- Ajouter quelques badges à Nicolas
WITH nicolas_profile AS (
  SELECT id FROM profiles WHERE email = 'nicolas.devaux@company.com'
)
INSERT INTO profile_badges (profile_id, badge_id)
SELECT 
  (SELECT id FROM nicolas_profile),
  id
FROM badges 
WHERE name IN ('Innovateur', 'Esprit d''équipe')
AND EXISTS (SELECT 1 FROM nicolas_profile);