/*
  # Add icon column to incentives table

  1. Changes
    - Add icon column to incentives table with default value 'Award'
*/

-- Add icon column to incentives table
ALTER TABLE incentives 
ADD COLUMN icon text NOT NULL DEFAULT 'Award';