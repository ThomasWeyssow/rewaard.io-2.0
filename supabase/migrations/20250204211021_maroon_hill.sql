-- Add back nomination cycle columns to settings
ALTER TABLE settings
ADD COLUMN next_nomination_start_date timestamptz,
ADD COLUMN next_nomination_end_date timestamptz,
ADD COLUMN next_nomination_period text CHECK (next_nomination_period IN ('monthly', 'bi-monthly')),
ADD COLUMN next_nomination_area_id uuid REFERENCES nomination_areas(id),
ADD COLUMN ongoing_nomination_start_date timestamptz,
ADD COLUMN ongoing_nomination_end_date timestamptz,
ADD COLUMN ongoing_nomination_period text CHECK (ongoing_nomination_period IN ('monthly', 'bi-monthly')),
ADD COLUMN ongoing_nomination_area_id uuid REFERENCES nomination_areas(id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_settings_next_nomination_area 
ON settings(next_nomination_area_id);

CREATE INDEX IF NOT EXISTS idx_settings_ongoing_nomination_area 
ON settings(ongoing_nomination_area_id);

CREATE INDEX IF NOT EXISTS idx_settings_next_nomination_dates 
ON settings(next_nomination_start_date, next_nomination_end_date);

CREATE INDEX IF NOT EXISTS idx_settings_ongoing_nomination_dates 
ON settings(ongoing_nomination_start_date, ongoing_nomination_end_date);

-- Update settings with data from nomination_cycles
UPDATE settings s
SET
  next_nomination_start_date = nc_next.start_date,
  next_nomination_end_date = nc_next.end_date,
  next_nomination_period = nc_next.period,
  next_nomination_area_id = nc_next.nomination_area_id,
  ongoing_nomination_start_date = nc_ongoing.start_date,
  ongoing_nomination_end_date = nc_ongoing.end_date,
  ongoing_nomination_period = nc_ongoing.period,
  ongoing_nomination_area_id = nc_ongoing.nomination_area_id
FROM 
  nomination_cycles nc_next,
  nomination_cycles nc_ongoing
WHERE 
  nc_next.id = s.next_cycle_id
  AND nc_ongoing.id = s.ongoing_cycle_id;

-- Create function to handle nomination cycles
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate next_nomination_end_date if start date is set
  IF NEW.next_nomination_start_date IS NOT NULL AND NEW.next_nomination_end_date IS NULL THEN
    -- Set time to midnight (00:00:00) Paris time
    NEW.next_nomination_start_date := date_trunc('day', NEW.next_nomination_start_date)::timestamptz + interval '23 hours';
    
    IF NEW.next_nomination_period = 'monthly' THEN
      -- End date is last day of the month at 23:59:59 Paris time
      NEW.next_nomination_end_date := date_trunc('month', NEW.next_nomination_start_date) + interval '1 month' - interval '1 second';
    ELSE -- 'bi-monthly'
      -- End date is last day of next month at 23:59:59 Paris time
      NEW.next_nomination_end_date := date_trunc('month', NEW.next_nomination_start_date) + interval '2 months' - interval '1 second';
    END IF;
  END IF;

  -- Check if we need to transition to a new cycle
  IF TG_OP = 'UPDATE' AND 
     NEW.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     NEW.ongoing_nomination_start_date IS NULL THEN
    -- Move next cycle to ongoing
    NEW.ongoing_nomination_start_date := NEW.next_nomination_start_date;
    NEW.ongoing_nomination_end_date := NEW.next_nomination_end_date;
    NEW.ongoing_nomination_area_id := NEW.next_nomination_area_id;
    NEW.ongoing_nomination_period := NEW.next_nomination_period;

    -- Set next cycle to start at midnight the day after ongoing cycle ends
    NEW.next_nomination_start_date := date_trunc('day', NEW.ongoing_nomination_end_date + interval '1 day')::timestamptz + interval '23 hours';
    NEW.next_nomination_area_id := NULL;
    NEW.next_nomination_period := NULL;
    NEW.next_nomination_end_date := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER handle_nomination_cycles_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION handle_nomination_cycles();

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings updated with all nomination fields:';
  RAISE NOTICE '- Next nomination start: %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination end: %', settings_record.next_nomination_end_date;
  RAISE NOTICE '- Next nomination period: %', settings_record.next_nomination_period;
  RAISE NOTICE '- Next nomination area ID: %', settings_record.next_nomination_area_id;
  RAISE NOTICE '- Ongoing nomination start: %', settings_record.ongoing_nomination_start_date;
  RAISE NOTICE '- Ongoing nomination end: %', settings_record.ongoing_nomination_end_date;
  RAISE NOTICE '- Ongoing nomination period: %', settings_record.ongoing_nomination_period;
  RAISE NOTICE '- Ongoing nomination area ID: %', settings_record.ongoing_nomination_area_id;
END $$;