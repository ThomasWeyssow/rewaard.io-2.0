-- Add new columns with default values
ALTER TABLE votes
ADD COLUMN nomination_cycle_start date,
ADD COLUMN nomination_cycle_end date;

-- Update existing votes with calculated dates
DO $$
DECLARE
  cycle_start date;
  cycle_end date;
BEGIN
  -- For each month/year combination, calculate start and end dates
  FOR cycle_start IN
    SELECT DISTINCT date_trunc('month', make_date(year, month, 1))::date
    FROM votes
  LOOP
    cycle_end := (cycle_start + interval '1 month' - interval '1 day')::date;
    
    -- Update votes for this cycle
    UPDATE votes
    SET 
      nomination_cycle_start = cycle_start,
      nomination_cycle_end = cycle_end
    WHERE 
      date_part('month', cycle_start) = month
      AND date_part('year', cycle_start) = year;
  END LOOP;
END $$;

-- Make the new columns NOT NULL after data migration
ALTER TABLE votes
ALTER COLUMN nomination_cycle_start SET NOT NULL,
ALTER COLUMN nomination_cycle_end SET NOT NULL;

-- Drop old columns
ALTER TABLE votes
DROP COLUMN month,
DROP COLUMN year;

-- Update unique constraint
ALTER TABLE votes
DROP CONSTRAINT IF EXISTS votes_voter_id_month_year_key,
ADD CONSTRAINT votes_voter_id_cycle_key UNIQUE (voter_id, nomination_cycle_start, nomination_cycle_end);