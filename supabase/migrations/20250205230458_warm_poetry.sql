-- Mettre à jour la fonction handle_nomination_cycles
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate next_nomination_end_date if it's not provided
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
    -- Generate new cycle_id for ongoing cycle
    NEW.ongoing_cycle_id := gen_random_uuid();
    
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

-- Vérifier l'état actuel
SELECT 
  'État actuel:' as section,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  ongoing_nomination_period,
  ongoing_nomination_area_id,
  ongoing_cycle_id
FROM settings;

-- Générer un cycle_id s'il n'existe pas pour le cycle en cours
UPDATE settings
SET ongoing_cycle_id = gen_random_uuid()
WHERE ongoing_nomination_start_date IS NOT NULL 
  AND ongoing_nomination_end_date IS NOT NULL 
  AND ongoing_cycle_id IS NULL;