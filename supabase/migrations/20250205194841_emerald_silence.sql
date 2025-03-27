-- Log current state before changes
SELECT 
  'Current state before changes:' as info,
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'nominations'::regclass;

-- Drop all constraints on nominations table
DO $$ 
BEGIN
  -- Drop foreign key constraints
  ALTER TABLE nominations DROP CONSTRAINT IF EXISTS nominations_cycle_id_fkey;
  ALTER TABLE nominations DROP CONSTRAINT IF EXISTS nominations_voter_id_fkey;
  ALTER TABLE nominations DROP CONSTRAINT IF EXISTS nominations_nominee_id_fkey;
  
  -- Drop any unique constraints
  ALTER TABLE nominations DROP CONSTRAINT IF EXISTS nominations_voter_cycle_unique;
  ALTER TABLE nominations DROP CONSTRAINT IF EXISTS nominations_pkey;
END $$;

-- Recreate only necessary constraints
ALTER TABLE nominations
ADD CONSTRAINT nominations_pkey PRIMARY KEY (id),
ADD CONSTRAINT nominations_voter_id_fkey FOREIGN KEY (voter_id) REFERENCES profiles(id),
ADD CONSTRAINT nominations_nominee_id_fkey FOREIGN KEY (nominee_id) REFERENCES profiles(id);

-- Make cycle_id nullable
ALTER TABLE nominations
ALTER COLUMN cycle_id DROP NOT NULL;

-- Drop all existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create super simple policy
CREATE POLICY "allow_all_nominations"
  ON nominations FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Log final state
SELECT 
  'Current state after changes:' as info,
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'nominations'::regclass;

-- Verify current settings state
SELECT 
  'Settings state:' as info,
  ongoing_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end
FROM settings;