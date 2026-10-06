-- =====================================================================
-- 06  Row Level Security + grants
--
-- Rule of thumb:
--   * users can READ their own rows
--   * admins can READ everything
--   * money tables are never writable from the browser: writes happen
--     through edge functions using the service role (which bypasses RLS)
-- =====================================================================

alter table public.profiles            enable row level security;
alter table public.user_roles          enable row level security;
alter table public.platform_settings   enable row level security;
alter table public.audit_logs          enable row level security;
alter table public.notifications       enable row level security;
alter table public.kyc_submissions     enable row level security;
alter table public.payment_methods     enable row level security;
alter table public.wallets             enable row level security;
alter table public.assets              enable row level security;
alter table public.price_history       enable row level security;
alter table public.watchlist           enable row level security;
alter table public.holdings            enable row level security;
alter table public.orders              enable row level security;
alter table public.wallet_transactions enable row level security;

-- ---------- table privileges ---------------------------------------------
revoke all on all tables in schema public from anon;
grant select on public.assets, public.price_history to anon;

revoke insert, update, delete on
  public.profiles, public.user_roles, public.audit_logs, public.kyc_submissions,
  public.wallets, public.holdings, public.orders, public.wallet_transactions,
  public.price_history, public.assets, public.notifications
from authenticated;

-- profile fields a user may edit themselves (everything else is service-role only)
grant update (first_name, last_name, phone, country, avatar_url) on public.profiles to authenticated;
-- notifications: users may mark read / delete their own
grant update (read_at) on public.notifications to authenticated;
grant delete on public.notifications to authenticated;
-- admin-managed config tables (guarded by the admin policies below)
grant insert, update, delete on public.payment_methods, public.platform_settings to authenticated;
grant insert, update, delete on public.assets to authenticated;

-- ---------- profiles -----------------------------------------------------
create policy "profiles: read own or admin" on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());

create policy "profiles: update own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- ---------- user_roles ---------------------------------------------------
create policy "user_roles: read own or admin" on public.user_roles
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

-- ---------- platform_settings -------------------------------------------
create policy "settings: read" on public.platform_settings
  for select to authenticated using (true);
create policy "settings: admin write" on public.platform_settings
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------- audit_logs ----------------------------------------------------
create policy "audit: admin read" on public.audit_logs
  for select to authenticated using (public.is_admin());

-- ---------- notifications ------------------------------------------------
create policy "notifications: read own" on public.notifications
  for select to authenticated using (user_id = auth.uid());
create policy "notifications: update own" on public.notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "notifications: delete own" on public.notifications
  for delete to authenticated using (user_id = auth.uid());

-- ---------- kyc_submissions ----------------------------------------------
create policy "kyc: read own or admin" on public.kyc_submissions
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

-- ---------- payment_methods ----------------------------------------------
create policy "payment methods: read active" on public.payment_methods
  for select to authenticated using (is_active or public.is_admin());
create policy "payment methods: admin write" on public.payment_methods
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------- wallets / holdings / orders / ledger ------------------------
create policy "wallets: read own or admin" on public.wallets
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "holdings: read own or admin" on public.holdings
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "orders: read own or admin" on public.orders
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "wallet_transactions: read own or admin" on public.wallet_transactions
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

-- ---------- assets & prices ----------------------------------------------
create policy "assets: public read active" on public.assets
  for select to anon, authenticated using (is_active or public.is_admin());
create policy "assets: admin write" on public.assets
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "price_history: public read" on public.price_history
  for select to anon, authenticated using (true);

-- ---------- watchlist ----------------------------------------------------
grant select, insert, delete on public.watchlist to authenticated;
create policy "watchlist: manage own" on public.watchlist
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
