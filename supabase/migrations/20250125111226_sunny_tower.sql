-- Add policy to allow users to delete their own validations
CREATE POLICY "Users can delete their own validations"
  ON nomination_validations FOR DELETE
  TO authenticated
  USING (validator_id = auth.uid());