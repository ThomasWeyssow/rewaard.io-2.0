-- Create table for storing nomination history
CREATE TABLE nomination_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_start_date timestamptz NOT NULL,
  cycle_end_date timestamptz NOT NULL,
  voter_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  nominee_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  selected_areas text[] NOT NULL,
  justification text NOT NULL,
  remarks text,
  nomination_area_id uuid REFERENCES nomination_areas(id),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE nomination_history ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can read nomination history"
  ON nomination_history FOR SELECT
  TO authenticated
  USING (true);

-- Create index for better performance
CREATE INDEX idx_nomination_history_cycle 
ON nomination_history(cycle_start_date, cycle_end_date);

-- Update check_and_update_nomination_cycles function to handle history
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    -- Move current nominations to history before clearing them
    INSERT INTO nomination_history (
      cycle_start_date,
      cycle_end_date,
      voter_id,
      nominee_id,
      selected_areas,
      justification,
      remarks,
      nomination_area_id
    )
    SELECT 
      settings_record.ongoing_nomination_start_date,
      settings_record.ongoing_nomination_end_date,
      voter_id,
      nominee_id,
      selected_areas,
      justification,
      remarks,
      settings_record.ongoing_nomination_area_id
    FROM nominations
    WHERE 
      nomination_cycle_start = settings_record.ongoing_nomination_start_date AND
      nomination_cycle_end = settings_record.ongoing_nomination_end_date;

    -- Delete old nominations
    DELETE FROM nominations
    WHERE 
      nomination_cycle_start = settings_record.ongoing_nomination_start_date AND
      nomination_cycle_end = settings_record.ongoing_nomination_end_date;

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
      -- Set next cycle to start at 23:00:00 UTC the day after ongoing cycle ends
      next_nomination_start_date = date_trunc('day', next_nomination_end_date + interval '1 day') + interval '23 hours',
      next_nomination_area_id = NULL,
      next_nomination_period = NULL,
      next_nomination_end_date = NULL
    WHERE id = settings_record.id;

    RAISE NOTICE 'Nomination cycle updated at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;