-- Add missing policies for client_modules
CREATE POLICY "Users can read client modules"
  ON client_modules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update client modules"
  ON client_modules FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  );

-- Add missing indexes
CREATE INDEX IF NOT EXISTS idx_client_modules_active ON client_modules(is_active);
CREATE INDEX IF NOT EXISTS idx_modules_name ON modules(name);

-- Update module descriptions to be more user-friendly
UPDATE modules
SET description = 'Système de récompenses',
    features = ARRAY[
      'Gestion des employés',
      'Attribution de points',
      'Catalogue de récompenses'
    ]
WHERE name = 'employee-rewards';

UPDATE modules
SET description = 'Employé du mois',
    features = ARRAY[
      'Programme Hero',
      'Système de nominations',
      'Validation par ExCom',
      'Wall of Fame',
      'Gestion des utilisateurs',
      'Paramètres avancés'
    ]
WHERE name = 'employee-of-the-month';