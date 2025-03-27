-- Suppression de la colonne title qui n'est plus utilisée
ALTER TABLE nomination_areas
DROP COLUMN title;

-- Ajout d'une contrainte NOT NULL sur areas pour s'assurer qu'il y a toujours au moins une zone
ALTER TABLE nomination_areas
ALTER COLUMN areas SET NOT NULL;