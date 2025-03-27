-- Ensure module is active for Redspher client
UPDATE client_modules
SET is_active = true
WHERE client_id = (
  SELECT id FROM clients WHERE name = 'Redspher'
)
AND module_id = (
  SELECT id FROM modules WHERE name = 'employee-rewards'
);

-- Insert if not exists
INSERT INTO client_modules (client_id, module_id, is_active)
SELECT 
  c.id,
  m.id,
  true
FROM 
  clients c,
  modules m
WHERE 
  c.name = 'Redspher'
  AND m.name = 'employee-rewards'
  AND NOT EXISTS (
    SELECT 1 
    FROM client_modules cm 
    WHERE cm.client_id = c.id 
    AND cm.module_id = m.id
  );