-- Optional: refresh prices on a schedule with pg_cron + pg_net.
-- 1) Enable the pg_cron and pg_net extensions (Dashboard -> Database -> Extensions).
-- 2) Store the same secret you set as CRON_SECRET in the Vault:
--      select vault.create_secret('<your-long-random-secret>', 'cron_secret');
-- 3) Replace <project-ref>, then run this file.
-- Mind your price provider's rate limits: every 1-5 minutes is plenty.

select cron.schedule(
  'update-prices',
  '*/2 * * * *',
  $$
  select net.http_post(
    url     := 'https://<project-ref>.supabase.co/functions/v1/update-prices',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')
    ),
    body    := '{}'::jsonb
  );
  $$
);

-- To stop it:  select cron.unschedule('update-prices');
