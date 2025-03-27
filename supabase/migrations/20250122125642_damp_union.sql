-- Mise à jour de la table nomination_areas
ALTER TABLE nomination_areas
DROP COLUMN area_title,
DROP COLUMN area_description;

ALTER TABLE nomination_areas
ADD COLUMN category text NOT NULL,
ADD COLUMN areas jsonb DEFAULT '[]'::jsonb;