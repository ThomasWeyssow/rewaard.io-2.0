/*
  # Add next_nomination_area_id to settings table

  1. Changes
    - Add next_nomination_area_id column to settings table with foreign key reference to nomination_areas
    - Make the column nullable since it's optional
    - Add index for better query performance
*/

-- Add the column
ALTER TABLE settings
ADD COLUMN next_nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL;

-- Add an index for better performance
CREATE INDEX idx_settings_next_nomination_area ON settings(next_nomination_area_id);