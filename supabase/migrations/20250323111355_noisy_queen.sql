-- Insert Recognition module if it doesn't exist
INSERT INTO modules (name, description)
SELECT 'Recognition', 'Employee recognition and points system'
WHERE NOT EXISTS (
  SELECT 1 FROM modules WHERE name = 'Recognition'
);

-- First, ensure page settings exist
INSERT INTO page_settings (page_name, is_enabled)
VALUES 
  ('feed', true),
  ('recognize', true),
  ('recognition-admin', true)
ON CONFLICT (page_name) 
DO UPDATE SET is_enabled = true;

-- Get the module ID
WITH recognition_module AS (
  SELECT id FROM modules WHERE name = 'Recognition'
)
-- Then insert module pages
INSERT INTO module_pages (module_id, page_name)
SELECT 
  recognition_module.id,
  page_name
FROM recognition_module
CROSS JOIN (
  VALUES 
    ('feed'),
    ('recognize'),
    ('recognition-admin')
) AS pages(page_name)
WHERE NOT EXISTS (
  SELECT 1 
  FROM module_pages mp 
  WHERE mp.module_id = recognition_module.id 
  AND mp.page_name = pages.page_name
);

-- Log the changes
DO $$
DECLARE
  module_record RECORD;
BEGIN
  SELECT 
    m.name,
    m.description,
    array_agg(mp.page_name) as pages
  INTO module_record
  FROM modules m
  LEFT JOIN module_pages mp ON mp.module_id = m.id
  WHERE m.name = 'Recognition'
  GROUP BY m.id, m.name, m.description;

  RAISE NOTICE 'Recognition module setup:';
  RAISE NOTICE '- Name: %', module_record.name;
  RAISE NOTICE '- Description: %', module_record.description;
  RAISE NOTICE '- Pages: %', module_record.pages;
END $$;