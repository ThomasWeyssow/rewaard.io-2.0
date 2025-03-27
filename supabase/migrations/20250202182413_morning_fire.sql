-- Enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create function to check and update nomination cycles
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if we need to transition to a new cycle
  IF settings_record.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     settings_record.ongoing_nomination_start_date IS NULL THEN
    
    -- Move next cycle to ongoing
    UPDATE settings
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      -- Reset next cycle
      next_nomination_start_date = next_nomination_end_date + interval '1 day',
      next_nomination_end_date = NULL,
      next_nomination_area_id = NULL,
      next_nomination_period = NULL
    WHERE id = settings_record.id;

    RAISE NOTICE 'Nomination cycle updated at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Schedule the cron job to run at 00:01 every day
SELECT cron.schedule(
  'check-nomination-cycles',  -- job name
  '1 0 * * *',              -- cron expression: At 00:01 every day
  'SELECT check_and_update_nomination_cycles()'
);

-- Log that the job has been created
DO $$
BEGIN
  RAISE NOTICE 'Cron job scheduled: check-nomination-cycles will run at 00:01 daily';
END $$;