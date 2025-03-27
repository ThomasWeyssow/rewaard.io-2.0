-- Create table for storing nomination results
CREATE TABLE IF NOT EXISTS nomination_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_start_date timestamptz NOT NULL,
  cycle_end_date timestamptz NOT NULL,
  nominee_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  nomination_count integer NOT NULL DEFAULT 0,
  validation_count integer NOT NULL DEFAULT 0,
  nomination_area_id uuid REFERENCES nomination_areas(id),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE nomination_results ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can read nomination results"
  ON nomination_results FOR SELECT
  TO authenticated
  USING (true);

-- Update the check_and_update_nomination_cycles function
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  top_nominees RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    -- Save top 6 nominees before clearing the cycle
    INSERT INTO nomination_results (
      cycle_start_date,
      cycle_end_date,
      nominee_id,
      nomination_count,
      validation_count,
      nomination_area_id
    )
    SELECT 
      settings_record.ongoing_nomination_start_date,
      settings_record.ongoing_nomination_end_date,
      n.nominee_id,
      COUNT(DISTINCT n.voter_id) as nomination_count,
      COUNT(DISTINCT v.validator_id) as validation_count,
      settings_record.ongoing_nomination_area_id
    FROM nominations n
    LEFT JOIN nomination_validations v ON 
      v.nominee_id = n.nominee_id AND
      v.cycle_start_date = settings_record.ongoing_nomination_start_date AND
      v.cycle_end_date = settings_record.ongoing_nomination_end_date
    WHERE 
      n.nomination_cycle_start = settings_record.ongoing_nomination_start_date AND
      n.nomination_cycle_end = settings_record.ongoing_nomination_end_date
    GROUP BY n.nominee_id
    ORDER BY 
      COUNT(DISTINCT v.validator_id) DESC,
      COUNT(DISTINCT n.voter_id) DESC
    LIMIT 6;

    -- Clear ongoing cycle
    UPDATE settings
    SET
      ongoing_nomination_start_date = NULL,
      ongoing_nomination_end_date = NULL,
      ongoing_nomination_area_id = NULL,
      ongoing_nomination_period = NULL
    WHERE id = settings_record.id;
    
    -- Refresh settings record
    SELECT * INTO settings_record
    FROM settings
    LIMIT 1;
  END IF;

  -- Now check if we need to start a new cycle
  IF settings_record.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     settings_record.ongoing_nomination_start_date IS NULL THEN
    
    -- Move next cycle to ongoing
    UPDATE settings
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      -- Set next cycle to start at midnight the day after ongoing cycle ends
      next_nomination_start_date = date_trunc('day', next_nomination_end_date + interval '1 day')::timestamptz,
      next_nomination_area_id = NULL,
      next_nomination_period = NULL,
      next_nomination_end_date = NULL
    WHERE id = settings_record.id;

    RAISE NOTICE 'Nomination cycle updated at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create index for better performance
CREATE INDEX idx_nomination_results_cycle 
ON nomination_results(cycle_start_date, cycle_end_date);

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings updated:';
  RAISE NOTICE '- Next nomination start: %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination end: %', settings_record.next_nomination_end_date;
  RAISE NOTICE '- Ongoing nomination start: %', settings_record.ongoing_nomination_start_date;
  RAISE NOTICE '- Ongoing nomination end: %', settings_record.ongoing_nomination_end_date;
END $$;