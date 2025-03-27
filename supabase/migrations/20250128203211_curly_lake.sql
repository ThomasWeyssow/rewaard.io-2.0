-- Add client_id column to page_settings
ALTER TABLE page_settings
ADD COLUMN client_id uuid REFERENCES clients(id) ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX idx_page_settings_client_id ON page_settings(client_id);

-- Add unique constraint to prevent duplicate settings for same page and client
ALTER TABLE page_settings
ADD CONSTRAINT page_settings_client_page_unique UNIQUE (client_id, page_name);

-- Drop old unique index on page_name if it exists
DROP INDEX IF EXISTS page_settings_page_name_idx;

-- Update existing records to link with Redspher client
UPDATE page_settings
SET client_id = (
  SELECT id 
  FROM clients 
  WHERE name = 'Redspher'
)
WHERE client_id IS NULL;