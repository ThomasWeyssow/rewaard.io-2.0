-- Drop tables in correct order due to foreign key constraints
DROP TABLE IF EXISTS client_modules;
DROP TABLE IF EXISTS modules;

-- Log the operation
DO $$
BEGIN
  RAISE NOTICE 'Tables modules and client_modules have been dropped';
END $$;