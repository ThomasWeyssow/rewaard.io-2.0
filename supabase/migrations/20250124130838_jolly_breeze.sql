-- Clean up existing nominations
DELETE FROM nominations 
WHERE nomination_cycle_start IS NOT NULL 
AND nomination_cycle_end IS NOT NULL;

-- Clean up existing nomination results
DELETE FROM nomination_results;