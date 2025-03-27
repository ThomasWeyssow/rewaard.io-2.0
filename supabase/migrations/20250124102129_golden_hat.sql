-- Remove nomination dates columns
ALTER TABLE settings
DROP COLUMN next_nomination_start_date,
DROP COLUMN next_nomination_end_date,
DROP COLUMN ongoing_nomination_start_date,
DROP COLUMN ongoing_nomination_end_date,
DROP COLUMN ongoing_nomination_area_id;

-- Drop the trigger and function for date calculations
DROP TRIGGER IF EXISTS calculate_nomination_dates_trigger ON settings;
DROP FUNCTION IF EXISTS calculate_nomination_dates();