-- Add pages array to modules table
ALTER TABLE modules
ADD COLUMN pages text[] NOT NULL DEFAULT '{}';

-- Update existing modules with their pages
UPDATE modules
SET pages = ARRAY['employees', 'rewards']
WHERE name = 'employee-rewards';

UPDATE modules
SET pages = ARRAY['hero-program', 'voting', 'review', 'history', 'users', 'settings']
WHERE name = 'employee-of-the-month';