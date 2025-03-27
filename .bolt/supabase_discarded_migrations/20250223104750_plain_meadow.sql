-- Drop existing trigger and function
DROP TRIGGER IF EXISTS set_validation_cycle_id_trigger ON nomination_validations;
DROP FUNCTION IF EXISTS set_validation_cycle_id();

-- Create updated function to set cycle_id on new validations
CREATE OR REPLACE FUNCTION set_validation_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  last_completed_cycle_id uuid;
BEGIN
  -- Get the last completed cycle ID
  SELECT id INTO last_completed_cycle_id
  FROM nomination_cycles
  WHERE status = 'completed'
  ORDER BY end_date DESC
  LIMIT 1;
  
  IF last_completed_cycle_id IS NULL THEN
    RAISE EXCEPTION 'No completed nomination cycle found';
  END IF;
  
  -- Set cycle_id from the last completed cycle
  NEW.cycle_id := last_completed_cycle_id;
  
  -- Log for debugging
  RAISE NOTICE 'Setting validation cycle_id to %', last_completed_cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new validations
CREATE TRIGGER set_validation_cycle_id_trigger
  BEFORE INSERT ON nomination_validations
  FOR EACH ROW
  EXECUTE FUNCTION set_validation_cycle_id();

-- Create function to get review data
CREATE OR REPLACE FUNCTION get_review_data()
RETURNS TABLE (
  cycle_id uuid,
  start_date timestamptz,
  end_date timestamptz,
  area_category text,
  area_details jsonb,
  nominees json
) AS $$
BEGIN
  RETURN QUERY
  WITH last_completed_cycle AS (
    SELECT 
      nc.id as cycle_id,
      nc.start_date,
      nc.end_date,
      nc.period,
      nc.nomination_area_id,
      na.category as area_category,
      na.areas as area_details
    FROM nomination_cycles nc
    LEFT JOIN nomination_areas na ON na.id = nc.nomination_area_id
    WHERE nc.status = 'completed'
    ORDER BY nc.end_date DESC
    LIMIT 1
  ),
  nominee_stats AS (
    SELECT 
      nh.nominee_id,
      p.first_name,
      p.last_name,
      p.department,
      p.avatar_url,
      COUNT(DISTINCT nh.id) as nomination_count,
      COUNT(DISTINCT nv.validator_id) as validation_count,
      ARRAY_AGG(DISTINCT nv.validator_id) as validator_ids,
      ARRAY_AGG(DISTINCT nh.id) as nomination_ids,
      lcc.cycle_id,
      lcc.start_date,
      lcc.end_date,
      lcc.area_category,
      lcc.area_details
    FROM last_completed_cycle lcc
    JOIN nomination_history nh ON nh.cycle_id = lcc.cycle_id
    JOIN profiles p ON p.id = nh.nominee_id
    LEFT JOIN nomination_validations nv ON 
      nv.nominee_id = nh.nominee_id 
      AND nv.cycle_id = lcc.cycle_id
    GROUP BY 
      nh.nominee_id,
      p.first_name,
      p.last_name,
      p.department,
      p.avatar_url,
      lcc.cycle_id,
      lcc.start_date,
      lcc.end_date,
      lcc.area_category,
      lcc.area_details
    ORDER BY 
      COUNT(DISTINCT nv.validator_id) DESC,
      COUNT(DISTINCT nh.id) DESC
  ),
  nomination_details AS (
    SELECT 
      nh.id as nomination_id,
      nh.nominee_id,
      nh.voter_id,
      p.first_name as voter_first_name,
      p.last_name as voter_last_name,
      p.department as voter_department,
      p.avatar_url as voter_avatar,
      nh.selected_areas,
      nh.justification,
      nh.remarks,
      to_char(nh.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as created_at
    FROM nomination_history nh
    JOIN profiles p ON p.id = nh.voter_id
    WHERE nh.nominee_id IN (SELECT nominee_id FROM nominee_stats)
  )
  SELECT 
    ns.cycle_id,
    ns.start_date,
    ns.end_date,
    ns.area_category,
    ns.area_details,
    json_agg(
      json_build_object(
        'nominee_id', ns.nominee_id,
        'first_name', ns.first_name,
        'last_name', ns.last_name,
        'department', ns.department,
        'avatar_url', ns.avatar_url,
        'nomination_count', ns.nomination_count,
        'validation_count', ns.validation_count,
        'validator_ids', ns.validator_ids,
        'nominations', (
          SELECT json_agg(row_to_json(nd))
          FROM nomination_details nd
          WHERE nd.nominee_id = ns.nominee_id
        )
      )
    ) as nominees
  FROM nominee_stats ns
  GROUP BY 
    ns.cycle_id,
    ns.start_date,
    ns.end_date,
    ns.area_category,
    ns.area_details;
END;
$$ LANGUAGE plpgsql;

-- Verify the current state
SELECT * FROM get_review_data();