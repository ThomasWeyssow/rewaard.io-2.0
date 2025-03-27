-- Drop existing cron job
SELECT cron.unschedule('check-nomination-cycles');

-- Schedule the cron job to run at 23:01 UTC every day
SELECT cron.schedule(
  'check-nomination-cycles',  -- job name
  '1 23 * * *',             -- cron expression: At 23:01 UTC every day
  'SELECT check_and_update_nomination_cycles()'
);

-- Log that the job has been updated
DO $$
BEGIN
  RAISE NOTICE 'Cron job updated: check-nomination-cycles will now run at 23:01 UTC daily';
END $$;