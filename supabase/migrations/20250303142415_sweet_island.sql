-- Add icon column to nomination_areas if it doesn't exist
ALTER TABLE nomination_areas
ADD COLUMN IF NOT EXISTS icon text DEFAULT 'Star';

-- Update existing rows to have a default icon if needed
UPDATE nomination_areas
SET icon = 'Star'
WHERE icon IS NULL;

-- Make icon column NOT NULL
ALTER TABLE nomination_areas
ALTER COLUMN icon SET NOT NULL;

-- Verify the changes
SELECT 
  'Current state:' as info,
  COUNT(*) as total_areas,
  COUNT(*) FILTER (WHERE icon IS NOT NULL) as areas_with_icon
FROM nomination_areas;