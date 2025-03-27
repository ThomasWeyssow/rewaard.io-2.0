-- Add new columns
ALTER TABLE profiles
ADD COLUMN first_name text,
ADD COLUMN last_name text;

-- Split existing name into first_name and last_name
UPDATE profiles
SET
  first_name = CASE 
    WHEN position(' ' in name) > 0 
    THEN substring(name from 1 for position(' ' in name) - 1)
    ELSE name
  END,
  last_name = CASE 
    WHEN position(' ' in name) > 0 
    THEN substring(name from position(' ' in name) + 1)
    ELSE ''
  END;

-- Make new columns required
ALTER TABLE profiles
ALTER COLUMN first_name SET NOT NULL,
ALTER COLUMN last_name SET NOT NULL;

-- Drop old name column
ALTER TABLE profiles
DROP COLUMN name;