-- Drop existing trigger and function
DROP TRIGGER IF EXISTS set_nomination_cycle_id_trigger ON nominations;
DROP FUNCTION IF EXISTS set_nomination_cycle_id;

-- Drop all constraints on nominations table
DO $$ 
BEGIN
  -- Drop foreign key constraints
  ALTER TABLE nominations DROP CONSTRAINT IF EXISTS nominations_cycle_id_fkey;
  ALTER TABLE nominations DROP CONSTRAINT IF EXISTS nominations_voter_id_fkey;
  ALTER TABLE nominations DROP CONSTRAINT IF EXISTS nominations_nominee_id_fkey;
  
  -- Drop any unique constraints
  ALTER TABLE nominations DROP CONSTRAINT IF EXISTS nominations_voter_cycle_unique;
END $$;

-- Drop all columns related to cycles
ALTER TABLE nominations 
DROP COLUMN IF EXISTS cycle_id,
DROP COLUMN IF EXISTS nomination_cycle_start,
DROP COLUMN IF EXISTS nomination_cycle_end;

-- Add back only necessary constraints
ALTER TABLE nominations
ADD CONSTRAINT nominations_voter_id_fkey FOREIGN KEY (voter_id) REFERENCES profiles(id),
ADD CONSTRAINT nominations_nominee_id_fkey FOREIGN KEY (nominee_id) REFERENCES profiles(id);

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