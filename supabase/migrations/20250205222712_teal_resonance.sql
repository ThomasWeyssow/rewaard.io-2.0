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
-- Ajouter une validation seulement si elle n'existe pas déjà
validation_data AS (
  INSERT INTO nomination_validations (
    validator_id,
    nominee_id
  )
  SELECT 
    (SELECT id FROM profiles WHERE email = 'nicolas@gmail.com'),
    nominee_id
  FROM test_nomination
  WHERE NOT EXISTS (
    SELECT 1 
    FROM nomination_validations 
    WHERE validator_id = (SELECT id FROM profiles WHERE email = 'nicolas@gmail.com')
    AND nominee_id = (SELECT nominee_id FROM test_nomination)
  )
)
SELECT 'Données de test insérées avec succès' as result;