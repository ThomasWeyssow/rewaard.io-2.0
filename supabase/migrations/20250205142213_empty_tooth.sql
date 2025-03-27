-- Update the specific nomination to match the ongoing cycle
UPDATE nominations n
SET 
  nomination_cycle_start = s.ongoing_nomination_start_date,
  nomination_cycle_end = s.ongoing_nomination_end_date
FROM settings s
WHERE n.id = 'e049c5f8-891c-4308-9690-cc532e0632a3'
  AND s.ongoing_nomination_start_date IS NOT NULL
  AND s.ongoing_nomination_end_date IS NOT NULL;

-- Verify the specific nomination
SELECT 
  'Nomination state:' as info,
  n.*,
  s.ongoing_nomination_start_date,
  s.ongoing_nomination_end_date,
  n.nomination_cycle_start = s.ongoing_nomination_start_date as dates_match
FROM nominations n
CROSS JOIN settings s
WHERE n.id = 'e049c5f8-891c-4308-9690-cc532e0632a3';