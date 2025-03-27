-- Drop old unique index on page_name if it exists
DROP INDEX IF EXISTS page_settings_page_name_idx;

-- Add unique constraint to prevent duplicate settings for same page and client
ALTER TABLE page_settings
DROP CONSTRAINT IF EXISTS page_settings_client_page_unique;

ALTER TABLE page_settings
ADD CONSTRAINT page_settings_client_page_unique UNIQUE (client_id, page_name);

-- Create index for better performance if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_page_settings_client_id ON page_settings(client_id);

-- Update existing records to link with Redspher client
UPDATE page_settings
SET client_id = (
  SELECT id 
  FROM clients 
  WHERE name = 'Redspher'
)
WHERE client_id IS NULL;