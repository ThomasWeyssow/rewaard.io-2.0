/*
  # Add hero banner storage
  
  1. Changes
    - Add hero_banner_url column to settings table
    - Set default banner URL
    - Add update policy for hero banner
*/

-- Add hero_banner_url column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'settings' 
    AND column_name = 'hero_banner_url'
  ) THEN
    ALTER TABLE settings
    ADD COLUMN hero_banner_url text DEFAULT 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=1200&h=400&fit=crop';
  END IF;
END $$;