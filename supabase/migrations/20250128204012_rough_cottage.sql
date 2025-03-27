-- Supprimer les contraintes et index existants
ALTER TABLE page_settings
DROP CONSTRAINT IF EXISTS page_settings_client_page_unique;

DROP INDEX IF EXISTS idx_page_settings_client_id;
DROP INDEX IF EXISTS page_settings_page_name_idx;

-- Supprimer la colonne client_id
ALTER TABLE page_settings
DROP COLUMN IF EXISTS client_id;

-- Ajouter une contrainte unique sur page_name
ALTER TABLE page_settings
ADD CONSTRAINT page_settings_page_name_unique UNIQUE (page_name);

-- Supprimer les doublons potentiels
WITH ranked_settings AS (
  SELECT 
    id,
    page_name,
    is_enabled,
    ROW_NUMBER() OVER (PARTITION BY page_name ORDER BY created_at DESC) as rn
  FROM page_settings
)
DELETE FROM page_settings
WHERE id IN (
  SELECT id 
  FROM ranked_settings 
  WHERE rn > 1
);

-- S'assurer que toutes les pages sont présentes avec leur état par défaut
INSERT INTO page_settings (page_name, is_enabled)
VALUES 
  ('hero-program', true),
  ('employees', true),
  ('rewards', true),
  ('voting', true),
  ('review', true),
  ('history', true),
  ('users', true),
  ('settings', true)
ON CONFLICT (page_name) DO NOTHING;