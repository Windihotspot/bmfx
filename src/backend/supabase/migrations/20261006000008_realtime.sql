-- =====================================================================
-- 08  Realtime: live prices, balances and notifications
-- (Realtime respects RLS, so users only receive their own rows.)
-- =====================================================================

do $$
declare
  t text;
begin
  foreach t in array array['assets', 'wallets', 'wallet_transactions', 'orders', 'notifications']
  loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then
      null;  -- already published
    end;
  end loop;
end;
$$;
