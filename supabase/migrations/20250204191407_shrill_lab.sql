-- Synchroniser les cycles de nomination
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Synchroniser le cycle en cours s'il existe
  IF settings_record.ongoing_nomination_start_date IS NOT NULL THEN
    INSERT INTO nomination_cycles (
      start_date,
      end_date,
      period,
      nomination_area_id,
      status
    )
    SELECT
      ongoing_nomination_start_date,
      ongoing_nomination_end_date,
      ongoing_nomination_period,
      ongoing_nomination_area_id,
      'ongoing'
    FROM settings
    WHERE NOT EXISTS (
      SELECT 1 
      FROM nomination_cycles 
      WHERE status = 'ongoing'
    );
  END IF;

  -- Synchroniser le prochain cycle s'il existe
  IF settings_record.next_nomination_start_date IS NOT NULL THEN
    INSERT INTO nomination_cycles (
      start_date,
      end_date,
      period,
      nomination_area_id,
      status
    )
    SELECT
      next_nomination_start_date,
      next_nomination_end_date,
      next_nomination_period,
      next_nomination_area_id,
      'next'
    FROM settings
    WHERE NOT EXISTS (
      SELECT 1 
      FROM nomination_cycles 
      WHERE status = 'next'
    );
  END IF;
END $$;

-- Vérifier l'état des cycles après synchronisation
SELECT 
  'État des cycles après synchronisation:' as section,
  status,
  to_char(start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
  to_char(end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
  period,
  nomination_area_id
FROM nomination_cycles
ORDER BY 
  CASE status
    WHEN 'next' THEN 1
    WHEN 'ongoing' THEN 2
    WHEN 'completed' THEN 3
  END;