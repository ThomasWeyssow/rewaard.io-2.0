-- Drop existing trigger temporarily to avoid validation errors
DROP TRIGGER IF EXISTS set_validation_cycle_id_trigger ON nomination_validations;

-- Insérer un cycle de nomination complété
WITH new_cycle AS (
  INSERT INTO nomination_cycles (
    start_date,
    end_date,
    period,
    status
  )
  VALUES (
    CURRENT_TIMESTAMP - interval '1 month',
    CURRENT_TIMESTAMP - interval '1 day',
    'monthly',
    'completed'
  )
  RETURNING id
),
-- Générer un nouvel UUID pour la nomination
test_nomination AS (
  -- Insérer une nomination de test dans l'historique
  INSERT INTO nomination_history (
    cycle_id,
    voter_id,
    nominee_id,
    selected_areas,
    justification,
    remarks
  )
  SELECT
    new_cycle.id,
    (SELECT id FROM profiles WHERE email = 'nicolas@gmail.com'),
    (SELECT id FROM profiles WHERE email = 'emma.laurent@company.com'),
    ARRAY['Vision stratégique', 'Innovation'],
    'Excellente contribution sur le projet Hero Program',
    'A démontré un leadership exceptionnel'
  FROM new_cycle
  RETURNING nominee_id
),
-- Ajouter quelques validations
validation_data AS (
  INSERT INTO nomination_validations (
    validator_id,
    nominee_id
  )
  SELECT 
    (SELECT id FROM profiles WHERE email = 'nicolas@gmail.com'),
    nominee_id
  FROM test_nomination
)
SELECT 'Données de test insérées avec succès' as result;

-- Recreate the trigger
CREATE TRIGGER set_validation_cycle_id_trigger
  BEFORE INSERT ON nomination_validations
  FOR EACH ROW
  EXECUTE FUNCTION set_validation_cycle_id();