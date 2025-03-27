/*
  # Update icon column in incentives table

  1. Changes
    - Ensure icon column exists with correct properties
    - Set default value and NOT NULL constraint if needed
*/

DO $$ 
BEGIN
  -- Check if icon column exists and update its properties if needed
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'incentives' 
    AND column_name = 'icon'
  ) THEN
    -- Update existing column properties
    ALTER TABLE incentives 
    ALTER COLUMN icon SET NOT NULL,
    ALTER COLUMN icon SET DEFAULT 'Award';
  ELSE
    -- Add the column if it doesn't exist
    ALTER TABLE incentives 
    ADD COLUMN icon text NOT NULL DEFAULT 'Award';
  END IF;
END $$;