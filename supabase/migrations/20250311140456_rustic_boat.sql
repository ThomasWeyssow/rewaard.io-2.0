/*
  # Add validation end date to nomination cycles

  1. Changes
    - Add end_validation_date column to nomination_cycles table
    - Column will be used to store the cutoff date for validations (end_date + 20 days)
    - No changes to existing triggers or functions
*/

-- Add end_validation_date column
ALTER TABLE nomination_cycles 
ADD COLUMN IF NOT EXISTS end_validation_date timestamptz;

-- Update existing completed cycles to have an end_validation_date
UPDATE nomination_cycles
SET end_validation_date = end_date + INTERVAL '20 days'
WHERE status = 'completed' AND end_validation_date IS NULL;