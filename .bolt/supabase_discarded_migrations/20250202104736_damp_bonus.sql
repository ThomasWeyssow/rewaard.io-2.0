-- Create function to format date nicely
CREATE OR REPLACE FUNCTION format_date(d date)
RETURNS text AS $$
BEGIN
  RETURN to_char(d, 'YYYY-MM-DD');
END;
$$ LANGUAGE plpgsql;

-- Check current settings state
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT 
    next_nomination_start_date,
    next_nomination_end_date,
    ongoing_nomination_start_date,
    ongoing_nomination_end_date,
    nomination_period
  INTO settings_record
  FROM settings
  LIMIT 1;

  -- Log the values
  RAISE NOTICE 'Current nomination cycle settings:';
  RAISE NOTICE 'Next cycle:';
  RAISE NOTICE '- Start: %', format_date(settings_record.next_nomination_start_date);
  RAISE NOTICE '- End: %', format_date(settings_record.next_nomination_end_date);
  RAISE NOTICE 'Ongoing cycle:';
  RAISE NOTICE '- Start: %', format_date(settings_record.ongoing_nomination_start_date);
  RAISE NOTICE '- End: %', format_date(settings_record.ongoing_nomination_end_date);
  RAISE NOTICE 'Period: %', settings_record.nomination_period;
END $$;

-- Drop the temporary function
DROP FUNCTION IF EXISTS format_date(date);