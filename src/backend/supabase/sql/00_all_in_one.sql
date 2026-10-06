-- ===== 20261006000001_enums_and_helpers.sql =====
-- =====================================================================
-- 01  Enums and shared helpers
-- =====================================================================

create type public.app_role           as enum ('user', 'admin', 'super_admin');
create type public.asset_class        as enum ('stock', 'forex', 'crypto', 'commodity', 'index', 'etf');
create type public.order_side         as enum ('buy', 'sell');
create type public.order_status       as enum ('filled', 'rejected', 'cancelled');
create type public.transaction_type   as enum ('deposit', 'withdrawal', 'trade_buy', 'trade_sell', 'fee', 'bonus', 'adjustment');
create type public.transaction_status as enum ('pending', 'completed', 'rejected', 'cancelled', 'failed');
create type public.kyc_status         as enum ('not_submitted', 'pending', 'approved', 'rejected');

-- Keeps updated_at current on any table that has the column.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ===== 20261006000002_core_tables.sql =====
-- =====================================================================
-- 02  Core tables: profiles, roles, settings, audit, notifications, KYC
-- =====================================================================

-- ---------- profiles ----------------------------------------------------
create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  first_name    text not null default '',
  last_name     text not null default '',
  email         text not null,
  phone         text,
  country       text,
  avatar_url    text,
  kyc_status    public.kyc_status not null default 'not_submitted',
  is_active     boolean not null default true,
  referral_code text not null unique default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
  referred_by   uuid references public.profiles (id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index profiles_email_idx on public.profiles (lower(email));
create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------- user_roles (kept separate from profiles on purpose) ---------
create table public.user_roles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  role       public.app_role not null,
  created_at timestamptz not null default now(),
  unique (user_id, role)
);
create index user_roles_user_idx on public.user_roles (user_id);

create or replace function public.has_role(_user_id uuid, _role public.app_role)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (select 1 from public.user_roles where user_id = _user_id and role = _role);
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role in ('admin', 'super_admin')
  );
$$;

-- ---------- platform_settings -------------------------------------------
create table public.platform_settings (
  key         text primary key,
  value       jsonb not null,
  description text,
  updated_by  uuid references auth.users (id) on delete set null,
  updated_at  timestamptz not null default now()
);
create trigger platform_settings_set_updated_at before update on public.platform_settings
  for each row execute function public.set_updated_at();

insert into public.platform_settings (key, value, description) values
  ('trading_enabled',               'true'::jsonb, 'Master switch for placing orders'),
  ('maintenance_mode',              'false'::jsonb, 'Show maintenance banner in the app'),
  ('trading_fee_pct',               '0.5'::jsonb,  'Fee charged on each buy/sell, percent of order value'),
  ('withdrawal_fee_pct',            '0'::jsonb,    'Fee charged on withdrawals, percent of amount'),
  ('min_deposit',                   '10'::jsonb,   'Minimum deposit amount'),
  ('min_withdrawal',                '20'::jsonb,   'Minimum withdrawal amount'),
  ('kyc_required_for_withdrawal',   'true'::jsonb, 'Require approved KYC before withdrawing'),
  ('kyc_required_for_trading',      'false'::jsonb,'Require approved KYC before trading')
on conflict (key) do nothing;

create or replace function public.get_setting_numeric(_key text, _default numeric)
returns numeric
language sql stable security definer
set search_path = ''
as $$
  select coalesce((select (value #>> '{}')::numeric from public.platform_settings where key = _key), _default);
$$;

create or replace function public.get_setting_bool(_key text, _default boolean)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce((select (value #>> '{}')::boolean from public.platform_settings where key = _key), _default);
$$;

-- ---------- audit_logs --------------------------------------------------
create table public.audit_logs (
  id          bigint generated always as identity primary key,
  actor_id    uuid references auth.users (id) on delete set null,
  action      text not null,
  entity_type text,
  entity_id   text,
  metadata    jsonb not null default '{}'::jsonb,
  ip_address  text,
  created_at  timestamptz not null default now()
);
create index audit_logs_actor_idx   on public.audit_logs (actor_id, created_at desc);
create index audit_logs_entity_idx  on public.audit_logs (entity_type, entity_id);
create index audit_logs_created_idx on public.audit_logs (created_at desc);

-- ---------- notifications -----------------------------------------------
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  type       text not null default 'info',
  title      text not null,
  body       text,
  data       jsonb not null default '{}'::jsonb,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_unread_idx on public.notifications (user_id) where read_at is null;

-- ---------- kyc_submissions ---------------------------------------------
create table public.kyc_submissions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  document_type   text not null check (document_type in ('national_id', 'passport', 'drivers_license', 'voters_card')),
  document_number text not null,
  front_path      text not null,   -- storage path in the kyc-documents bucket
  back_path       text,
  selfie_path     text not null,
  status          public.kyc_status not null default 'pending',
  review_notes    text,
  reviewed_by     uuid references auth.users (id) on delete set null,
  reviewed_at     timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index kyc_user_idx on public.kyc_submissions (user_id, created_at desc);
create unique index kyc_one_pending_per_user on public.kyc_submissions (user_id) where status = 'pending';
create trigger kyc_set_updated_at before update on public.kyc_submissions
  for each row execute function public.set_updated_at();

-- ---------- payment_methods (managed by admins) --------------------------
create table public.payment_methods (
  id                    uuid primary key default gen_random_uuid(),
  name                  text not null,
  type                  text not null check (type in ('bank_transfer', 'crypto', 'card', 'other')),
  currency              text not null default 'USD',
  details               jsonb not null default '{}'::jsonb,  -- bank account / wallet address shown to depositors
  instructions          text,
  min_amount            numeric(20, 2) not null default 0,
  max_amount            numeric(20, 2),
  is_deposit_enabled    boolean not null default true,
  is_withdrawal_enabled boolean not null default true,
  is_active             boolean not null default true,
  sort_order            int not null default 0,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
create trigger payment_methods_set_updated_at before update on public.payment_methods
  for each row execute function public.set_updated_at();

-- ===== 20261006000003_wallet_and_trading_tables.sql =====
-- =====================================================================
-- 03  Wallets, assets, holdings, orders, ledger
-- =====================================================================

-- ---------- wallets (one USD wallet per user) ---------------------------
create table public.wallets (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null unique references auth.users (id) on delete cascade,
  currency        text not null default 'USD',
  balance         numeric(20, 2) not null default 0 check (balance >= 0),
  locked_balance  numeric(20, 2) not null default 0 check (locked_balance >= 0), -- funds held for pending withdrawals
  total_deposited numeric(20, 2) not null default 0,
  total_withdrawn numeric(20, 2) not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create trigger wallets_set_updated_at before update on public.wallets
  for each row execute function public.set_updated_at();

-- ---------- assets (tradable instruments) --------------------------------
create table public.assets (
  id                uuid primary key default gen_random_uuid(),
  symbol            text not null unique,
  name              text not null,
  asset_class       public.asset_class not null,
  quote_currency    text not null default 'USD',
  price             numeric(24, 8) not null default 0 check (price >= 0),
  previous_close    numeric(24, 8),
  day_high          numeric(24, 8),
  day_low           numeric(24, 8),
  change_percent    numeric(10, 4) not null default 0,
  logo_url          text,
  price_provider    text not null default 'manual' check (price_provider in ('manual', 'coingecko', 'twelvedata')),
  provider_symbol   text,           -- e.g. 'bitcoin' (coingecko), 'AAPL' or 'EUR/USD' (twelvedata)
  quantity_decimals smallint not null default 8 check (quantity_decimals between 0 and 8),
  min_order_amount  numeric(20, 2) not null default 1,
  is_active         boolean not null default true,   -- visible in the app
  is_tradable       boolean not null default true,   -- can be bought/sold
  price_updated_at  timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index assets_class_idx on public.assets (asset_class) where is_active;
create trigger assets_set_updated_at before update on public.assets
  for each row execute function public.set_updated_at();

create table public.price_history (
  id          bigint generated always as identity primary key,
  asset_id    uuid not null references public.assets (id) on delete cascade,
  price       numeric(24, 8) not null,
  recorded_at timestamptz not null default now()
);
create index price_history_asset_time_idx on public.price_history (asset_id, recorded_at desc);

create table public.watchlist (
  user_id    uuid not null references auth.users (id) on delete cascade,
  asset_id   uuid not null references public.assets (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, asset_id)
);

-- ---------- holdings (current position per user per asset) ---------------
create table public.holdings (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  asset_id        uuid not null references public.assets (id) on delete restrict,
  quantity        numeric(28, 8) not null default 0 check (quantity >= 0),
  avg_entry_price numeric(24, 8) not null default 0 check (avg_entry_price >= 0),
  realized_pnl    numeric(20, 2) not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (user_id, asset_id)
);
create index holdings_user_idx on public.holdings (user_id);
create trigger holdings_set_updated_at before update on public.holdings
  for each row execute function public.set_updated_at();

-- ---------- orders (every executed trade) ---------------------------------
create table public.orders (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  asset_id        uuid not null references public.assets (id) on delete restrict,
  client_order_id text,                                  -- idempotency key from the client
  side            public.order_side not null,
  quantity        numeric(28, 8) not null check (quantity > 0),
  price           numeric(24, 8) not null check (price > 0),   -- execution price
  gross_amount    numeric(20, 2) not null,               -- quantity * price
  fee             numeric(20, 2) not null default 0,
  net_amount      numeric(20, 2) not null,               -- buy: gross + fee debited, sell: gross - fee credited
  realized_pnl    numeric(20, 2),                        -- sells only
  status          public.order_status not null default 'filled',
  created_at      timestamptz not null default now(),
  unique (user_id, client_order_id)
);
create index orders_user_idx  on public.orders (user_id, created_at desc);
create index orders_asset_idx on public.orders (asset_id);

-- ---------- wallet_transactions (append-only money ledger) ----------------
create table public.wallet_transactions (
  id               uuid primary key default gen_random_uuid(),
  reference        text not null unique default 'TX-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12)),
  user_id          uuid not null references auth.users (id) on delete cascade,
  wallet_id        uuid not null references public.wallets (id) on delete cascade,
  type             public.transaction_type not null,
  status           public.transaction_status not null default 'pending',
  direction        text not null check (direction in ('credit', 'debit')),
  amount           numeric(20, 2) not null check (amount > 0),
  fee              numeric(20, 2) not null default 0,
  balance_after    numeric(20, 2),
  currency         text not null default 'USD',
  method           text,
  description      text,
  details          jsonb not null default '{}'::jsonb,   -- destination account / wallet address / notes
  proof_path       text,                                 -- storage path of deposit proof
  order_id         uuid references public.orders (id) on delete set null,
  rejection_reason text,
  processed_by     uuid references auth.users (id) on delete set null,
  processed_at     timestamptz,
  created_at       timestamptz not null default now()
);
create index wallet_tx_user_idx   on public.wallet_transactions (user_id, created_at desc);
create index wallet_tx_status_idx on public.wallet_transactions (status, type) where status = 'pending';

-- ===== 20261006000004_auth_triggers.sql =====
-- =====================================================================
-- 04  Auth triggers: new user -> profile + wallet + default role
-- =====================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ref text := upper(nullif(new.raw_user_meta_data ->> 'referral_code', ''));
begin
  insert into public.profiles (id, email, first_name, last_name, phone, country, referred_by)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(trim(new.raw_user_meta_data ->> 'first_name'), ''),
    coalesce(trim(new.raw_user_meta_data ->> 'last_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'country'), ''),
    case when v_ref is null then null
         else (select p.id from public.profiles p where p.referral_code = v_ref) end
  )
  on conflict (id) do nothing;

  insert into public.wallets (user_id) values (new.id) on conflict (user_id) do nothing;
  insert into public.user_roles (user_id, role) values (new.id, 'user') on conflict do nothing;

  insert into public.notifications (user_id, type, title, body)
  values (new.id, 'welcome', 'Welcome to BMFX', 'Your account is ready. Complete identity verification to unlock withdrawals.');

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep profiles.email in sync when a user changes their email.
create or replace function public.handle_user_email_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles set email = coalesce(new.email, '') where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_changed on auth.users;
create trigger on_auth_user_email_changed
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function public.handle_user_email_change();

-- ===== 20261006000005_money_and_trading_functions.sql =====
-- =====================================================================
-- 05  Money & trading functions
--
-- Every function below moves money or changes prices. They are
-- SECURITY DEFINER and executable ONLY by service_role, so the only way
-- to reach them is through the edge functions (which authenticate the
-- caller first). Row locks (FOR UPDATE) make each operation atomic and
-- safe against double-spends and race conditions.
-- Business-rule violations raise the default SQLSTATE P0001 so the edge
-- functions can safely return the message to the user.
-- =====================================================================

create or replace function public._assert_admin(p_user_id uuid)
returns void
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.user_roles
    where user_id = p_user_id and role in ('admin', 'super_admin')
  ) then
    raise exception 'Not authorized';
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- execute_trade: market order filled instantly at the current asset price
-- ---------------------------------------------------------------------
create or replace function public.execute_trade(
  p_user_id         uuid,
  p_asset_id        uuid,
  p_side            public.order_side,
  p_quantity        numeric default null,
  p_amount          numeric default null,
  p_client_order_id text    default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_existing public.orders;
  v_profile  public.profiles;
  v_asset    public.assets;
  v_wallet   public.wallets;
  v_holding  public.holdings;
  v_order    public.orders;
  v_fee_pct  numeric;
  v_price    numeric;
  v_qty      numeric;
  v_gross    numeric;
  v_fee      numeric;
  v_net      numeric;
  v_pnl      numeric := null;
begin
  if (p_quantity is null) = (p_amount is null) then
    raise exception 'Provide either a quantity or an amount';
  end if;
  if coalesce(p_quantity, p_amount) <= 0 then
    raise exception 'Order size must be greater than zero';
  end if;

  -- Idempotency: a retried request returns the original order.
  if p_client_order_id is not null then
    select * into v_existing from public.orders
    where user_id = p_user_id and client_order_id = p_client_order_id;
    if found then return v_existing; end if;
  end if;

  if not public.get_setting_bool('trading_enabled', true) then
    raise exception 'Trading is temporarily disabled';
  end if;

  select * into v_profile from public.profiles where id = p_user_id;
  if not found or not v_profile.is_active then
    raise exception 'Your account is not active';
  end if;
  if public.get_setting_bool('kyc_required_for_trading', false) and v_profile.kyc_status <> 'approved' then
    raise exception 'Identity verification (KYC) is required before trading';
  end if;

  select * into v_asset from public.assets where id = p_asset_id;
  if not found or not v_asset.is_active or not v_asset.is_tradable then
    raise exception 'This asset is not available for trading';
  end if;
  if v_asset.price <= 0 then
    raise exception 'This asset has no valid price right now';
  end if;
  v_price := v_asset.price;

  -- Lock order: wallet first, then holding (always the same order).
  select * into v_wallet from public.wallets where user_id = p_user_id for update;
  if not found then raise exception 'Wallet not found'; end if;

  v_fee_pct := public.get_setting_numeric('trading_fee_pct', 0);

  if p_side = 'buy' then
    if p_amount is not null then
      v_gross := round(p_amount, 2);
      v_qty   := round(v_gross / v_price, v_asset.quantity_decimals);
    else
      v_qty   := round(p_quantity, v_asset.quantity_decimals);
      v_gross := round(v_qty * v_price, 2);
    end if;
    if v_qty <= 0 then raise exception 'Order size is too small'; end if;
    if v_gross < v_asset.min_order_amount then
      raise exception 'Minimum order amount for % is %', v_asset.symbol, v_asset.min_order_amount;
    end if;

    v_fee := round(v_gross * v_fee_pct / 100, 2);
    v_net := v_gross + v_fee;
    if v_wallet.balance < v_net then raise exception 'Insufficient balance'; end if;

    update public.wallets set balance = balance - v_net
    where id = v_wallet.id returning * into v_wallet;

    insert into public.holdings (user_id, asset_id, quantity, avg_entry_price)
    values (p_user_id, p_asset_id, v_qty, v_price)
    on conflict (user_id, asset_id) do update set
      avg_entry_price = case
        when public.holdings.quantity + excluded.quantity > 0 then
          ((public.holdings.quantity * public.holdings.avg_entry_price) + (excluded.quantity * excluded.avg_entry_price))
          / (public.holdings.quantity + excluded.quantity)
        else excluded.avg_entry_price end,
      quantity = public.holdings.quantity + excluded.quantity;

  else  -- sell
    if p_quantity is not null then
      v_qty := round(p_quantity, v_asset.quantity_decimals);
    else
      v_qty := round(p_amount / v_price, v_asset.quantity_decimals);
    end if;
    if v_qty <= 0 then raise exception 'Order size is too small'; end if;
    v_gross := round(v_qty * v_price, 2);
    if v_gross < v_asset.min_order_amount then
      raise exception 'Minimum order amount for % is %', v_asset.symbol, v_asset.min_order_amount;
    end if;

    select * into v_holding from public.holdings
    where user_id = p_user_id and asset_id = p_asset_id for update;
    if not found or v_holding.quantity < v_qty then
      raise exception 'Insufficient holdings to sell';
    end if;

    v_fee := round(v_gross * v_fee_pct / 100, 2);
    v_net := v_gross - v_fee;
    v_pnl := round(v_gross - v_fee - (v_qty * v_holding.avg_entry_price), 2);

    update public.holdings
    set quantity = quantity - v_qty, realized_pnl = realized_pnl + v_pnl
    where id = v_holding.id;

    update public.wallets set balance = balance + v_net
    where id = v_wallet.id returning * into v_wallet;
  end if;

  insert into public.orders (user_id, asset_id, client_order_id, side, quantity, price, gross_amount, fee, net_amount, realized_pnl, status)
  values (p_user_id, p_asset_id, p_client_order_id, p_side, v_qty, v_price, v_gross, v_fee, v_net, v_pnl, 'filled')
  returning * into v_order;

  insert into public.wallet_transactions
    (user_id, wallet_id, type, status, direction, amount, fee, balance_after, currency, method, description, order_id, processed_at)
  values
    (p_user_id, v_wallet.id,
     case when p_side = 'buy' then 'trade_buy'::public.transaction_type else 'trade_sell'::public.transaction_type end,
     'completed',
     case when p_side = 'buy' then 'debit' else 'credit' end,
     v_net, v_fee, v_wallet.balance, v_wallet.currency, 'trade',
     initcap(p_side::text) || ' ' || v_qty::text || ' ' || v_asset.symbol || ' @ ' || v_price::text,
     v_order.id, now());

  return v_order;
end;
$$;

-- ---------------------------------------------------------------------
-- request_deposit: creates a pending deposit for an admin to approve
-- ---------------------------------------------------------------------
create or replace function public.request_deposit(
  p_user_id    uuid,
  p_amount     numeric,
  p_method     text,
  p_details    jsonb default '{}'::jsonb,
  p_proof_path text  default null
)
returns public.wallet_transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
  v_wallet  public.wallets;
  v_tx      public.wallet_transactions;
  v_amount  numeric := round(p_amount, 2);
  v_min     numeric := public.get_setting_numeric('min_deposit', 0);
begin
  select * into v_profile from public.profiles where id = p_user_id;
  if not found or not v_profile.is_active then raise exception 'Your account is not active'; end if;
  if v_amount < v_min then raise exception 'Minimum deposit is %', v_min; end if;

  if (select count(*) from public.wallet_transactions
      where user_id = p_user_id and type = 'deposit' and status = 'pending') >= 5 then
    raise exception 'You have too many pending deposits. Please wait for them to be reviewed';
  end if;

  select * into v_wallet from public.wallets where user_id = p_user_id;
  if not found then raise exception 'Wallet not found'; end if;

  insert into public.wallet_transactions
    (user_id, wallet_id, type, status, direction, amount, currency, method, description, details, proof_path)
  values
    (p_user_id, v_wallet.id, 'deposit', 'pending', 'credit', v_amount, v_wallet.currency, p_method,
     'Deposit via ' || p_method, coalesce(p_details, '{}'::jsonb), p_proof_path)
  returning * into v_tx;

  return v_tx;
end;
$$;

-- ---------------------------------------------------------------------
-- request_withdrawal: reserves funds (moves them to locked_balance)
-- ---------------------------------------------------------------------
create or replace function public.request_withdrawal(
  p_user_id uuid,
  p_amount  numeric,
  p_method  text,
  p_details jsonb default '{}'::jsonb
)
returns public.wallet_transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
  v_wallet  public.wallets;
  v_tx      public.wallet_transactions;
  v_amount  numeric := round(p_amount, 2);
  v_min     numeric := public.get_setting_numeric('min_withdrawal', 0);
  v_fee     numeric;
  v_total   numeric;
begin
  select * into v_profile from public.profiles where id = p_user_id;
  if not found or not v_profile.is_active then raise exception 'Your account is not active'; end if;
  if public.get_setting_bool('kyc_required_for_withdrawal', true) and v_profile.kyc_status <> 'approved' then
    raise exception 'Identity verification (KYC) is required before withdrawing';
  end if;
  if v_amount < v_min then raise exception 'Minimum withdrawal is %', v_min; end if;

  select * into v_wallet from public.wallets where user_id = p_user_id for update;
  if not found then raise exception 'Wallet not found'; end if;

  v_fee   := round(v_amount * public.get_setting_numeric('withdrawal_fee_pct', 0) / 100, 2);
  v_total := v_amount + v_fee;
  if v_wallet.balance < v_total then raise exception 'Insufficient balance'; end if;

  update public.wallets
  set balance = balance - v_total, locked_balance = locked_balance + v_total
  where id = v_wallet.id returning * into v_wallet;

  insert into public.wallet_transactions
    (user_id, wallet_id, type, status, direction, amount, fee, balance_after, currency, method, description, details)
  values
    (p_user_id, v_wallet.id, 'withdrawal', 'pending', 'debit', v_amount, v_fee, v_wallet.balance, v_wallet.currency,
     p_method, 'Withdrawal via ' || p_method, coalesce(p_details, '{}'::jsonb))
  returning * into v_tx;

  return v_tx;
end;
$$;

-- ---------------------------------------------------------------------
-- admin_process_transaction: approve / reject a pending deposit or withdrawal
-- ---------------------------------------------------------------------
create or replace function public.admin_process_transaction(
  p_tx_id    uuid,
  p_admin_id uuid,
  p_action   text,
  p_reason   text default null
)
returns public.wallet_transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tx     public.wallet_transactions;
  v_wallet public.wallets;
  v_total  numeric;
begin
  perform public._assert_admin(p_admin_id);
  if p_action not in ('approve', 'reject') then raise exception 'Action must be approve or reject'; end if;

  select * into v_tx from public.wallet_transactions where id = p_tx_id for update;
  if not found then raise exception 'Transaction not found'; end if;
  if v_tx.status <> 'pending' then raise exception 'Transaction has already been processed'; end if;

  select * into v_wallet from public.wallets where id = v_tx.wallet_id for update;

  if v_tx.type = 'deposit' then
    if p_action = 'approve' then
      update public.wallets
      set balance = balance + v_tx.amount, total_deposited = total_deposited + v_tx.amount
      where id = v_wallet.id returning * into v_wallet;
    end if;

  elsif v_tx.type = 'withdrawal' then
    v_total := v_tx.amount + v_tx.fee;
    if p_action = 'approve' then
      update public.wallets
      set locked_balance = locked_balance - v_total, total_withdrawn = total_withdrawn + v_tx.amount
      where id = v_wallet.id returning * into v_wallet;
    else
      update public.wallets
      set locked_balance = locked_balance - v_total, balance = balance + v_total
      where id = v_wallet.id returning * into v_wallet;
    end if;

  else
    raise exception 'Only deposits and withdrawals can be processed';
  end if;

  update public.wallet_transactions
  set status = case when p_action = 'approve' then 'completed'::public.transaction_status
                    else 'rejected'::public.transaction_status end,
      balance_after = v_wallet.balance,
      rejection_reason = case when p_action = 'reject' then p_reason else null end,
      processed_by = p_admin_id,
      processed_at = now()
  where id = v_tx.id
  returning * into v_tx;

  insert into public.notifications (user_id, type, title, body, data)
  values (
    v_tx.user_id,
    'transaction',
    initcap(v_tx.type::text) || case when v_tx.status = 'completed' then ' approved' else ' rejected' end,
    case when v_tx.status = 'completed'
         then 'Your ' || v_tx.type::text || ' of ' || v_tx.amount::text || ' ' || v_tx.currency || ' was approved.'
         else 'Your ' || v_tx.type::text || ' of ' || v_tx.amount::text || ' ' || v_tx.currency || ' was rejected.'
              || coalesce(' Reason: ' || p_reason, '') end,
    jsonb_build_object('transaction_id', v_tx.id, 'reference', v_tx.reference)
  );

  return v_tx;
end;
$$;

-- ---------------------------------------------------------------------
-- admin_adjust_balance: manual credit (+) or debit (-) with an audit trail
-- ---------------------------------------------------------------------
create or replace function public.admin_adjust_balance(
  p_admin_id uuid,
  p_user_id  uuid,
  p_amount   numeric,
  p_reason   text
)
returns public.wallet_transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_wallet public.wallets;
  v_tx     public.wallet_transactions;
  v_amount numeric := round(p_amount, 2);
begin
  perform public._assert_admin(p_admin_id);
  if v_amount = 0 then raise exception 'Amount cannot be zero'; end if;
  if p_reason is null or length(trim(p_reason)) < 5 then raise exception 'A reason is required'; end if;

  select * into v_wallet from public.wallets where user_id = p_user_id for update;
  if not found then raise exception 'Wallet not found'; end if;
  if v_wallet.balance + v_amount < 0 then raise exception 'Adjustment would make the balance negative'; end if;

  update public.wallets set balance = balance + v_amount
  where id = v_wallet.id returning * into v_wallet;

  insert into public.wallet_transactions
    (user_id, wallet_id, type, status, direction, amount, balance_after, currency, method, description, processed_by, processed_at)
  values
    (p_user_id, v_wallet.id, 'adjustment', 'completed',
     case when v_amount > 0 then 'credit' else 'debit' end,
     abs(v_amount), v_wallet.balance, v_wallet.currency, 'admin', p_reason, p_admin_id, now())
  returning * into v_tx;

  insert into public.notifications (user_id, type, title, body, data)
  values (p_user_id, 'transaction', 'Balance adjusted',
          'Your balance was ' || case when v_amount > 0 then 'credited' else 'debited' end || ' by ' || abs(v_amount)::text
          || ' ' || v_wallet.currency || '.',
          jsonb_build_object('transaction_id', v_tx.id, 'reference', v_tx.reference));

  return v_tx;
end;
$$;

-- ---------------------------------------------------------------------
-- apply_asset_price: single entry point for price changes
-- ---------------------------------------------------------------------
create or replace function public.apply_asset_price(
  p_asset_id       uuid,
  p_price          numeric,
  p_record_history boolean default true
)
returns public.assets
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_asset   public.assets;
  v_prev    numeric;
  v_new_day boolean;
begin
  if p_price is null or p_price <= 0 then raise exception 'Price must be greater than zero'; end if;

  select * into v_asset from public.assets where id = p_asset_id for update;
  if not found then raise exception 'Asset not found'; end if;

  v_new_day := v_asset.price_updated_at is null or v_asset.price_updated_at::date < current_date;
  v_prev := case
    when v_asset.price <= 0 then p_price
    when v_new_day then v_asset.price
    else coalesce(v_asset.previous_close, v_asset.price) end;

  update public.assets set
    price            = p_price,
    previous_close   = v_prev,
    change_percent   = round((p_price - v_prev) / v_prev * 100, 4),
    day_high         = case when v_new_day or day_high is null then p_price else greatest(day_high, p_price) end,
    day_low          = case when v_new_day or day_low  is null then p_price else least(day_low,  p_price) end,
    price_updated_at = now()
  where id = p_asset_id
  returning * into v_asset;

  if p_record_history then
    insert into public.price_history (asset_id, price) values (p_asset_id, p_price);
  end if;

  return v_asset;
end;
$$;

-- ---------------------------------------------------------------------
-- get_portfolio: wallet + holdings valued at current prices
-- ---------------------------------------------------------------------
create or replace function public.get_portfolio(p_user_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_wallet   public.wallets;
  v_holdings jsonb;
  v_value    numeric;
  v_cost     numeric;
  v_realized numeric;
begin
  select * into v_wallet from public.wallets where user_id = p_user_id;
  if not found then raise exception 'Wallet not found'; end if;

  select coalesce(jsonb_agg(to_jsonb(r) order by r.market_value desc), '[]'::jsonb)
  into v_holdings
  from (
    select h.asset_id, a.symbol, a.name, a.asset_class, a.logo_url,
           h.quantity, h.avg_entry_price,
           a.price as current_price,
           round(h.quantity * h.avg_entry_price, 2) as cost_basis,
           round(h.quantity * a.price, 2)           as market_value,
           round(h.quantity * (a.price - h.avg_entry_price), 2) as unrealized_pnl,
           case when h.avg_entry_price > 0
                then round((a.price - h.avg_entry_price) / h.avg_entry_price * 100, 2) else 0 end as pnl_percent,
           h.realized_pnl
    from public.holdings h
    join public.assets a on a.id = h.asset_id
    where h.user_id = p_user_id and h.quantity > 0
  ) r;

  select coalesce(sum(h.quantity * a.price), 0),
         coalesce(sum(h.quantity * h.avg_entry_price), 0)
  into v_value, v_cost
  from public.holdings h join public.assets a on a.id = h.asset_id
  where h.user_id = p_user_id and h.quantity > 0;

  select coalesce(sum(realized_pnl), 0) into v_realized from public.holdings where user_id = p_user_id;

  return jsonb_build_object(
    'wallet', jsonb_build_object(
      'currency',        v_wallet.currency,
      'balance',         v_wallet.balance,
      'locked_balance',  v_wallet.locked_balance,
      'total_deposited', v_wallet.total_deposited,
      'total_withdrawn', v_wallet.total_withdrawn
    ),
    'holdings', v_holdings,
    'summary', jsonb_build_object(
      'holdings_value',  round(v_value, 2),
      'cost_basis',      round(v_cost, 2),
      'unrealized_pnl',  round(v_value - v_cost, 2),
      'realized_pnl',    round(v_realized, 2),
      'total_equity',    round(v_wallet.balance + v_wallet.locked_balance + v_value, 2)
    )
  );
end;
$$;

-- ---------------------------------------------------------------------
-- Lock the doors: only service_role (edge functions) may call these.
-- ---------------------------------------------------------------------
revoke all on function public._assert_admin(uuid)                                              from public, anon, authenticated;
revoke all on function public.execute_trade(uuid, uuid, public.order_side, numeric, numeric, text) from public, anon, authenticated;
revoke all on function public.request_deposit(uuid, numeric, text, jsonb, text)                from public, anon, authenticated;
revoke all on function public.request_withdrawal(uuid, numeric, text, jsonb)                   from public, anon, authenticated;
revoke all on function public.admin_process_transaction(uuid, uuid, text, text)                from public, anon, authenticated;
revoke all on function public.admin_adjust_balance(uuid, uuid, numeric, text)                  from public, anon, authenticated;
revoke all on function public.apply_asset_price(uuid, numeric, boolean)                        from public, anon, authenticated;
revoke all on function public.get_portfolio(uuid)                                              from public, anon, authenticated;

grant execute on function public._assert_admin(uuid)                                              to service_role;
grant execute on function public.execute_trade(uuid, uuid, public.order_side, numeric, numeric, text) to service_role;
grant execute on function public.request_deposit(uuid, numeric, text, jsonb, text)                to service_role;
grant execute on function public.request_withdrawal(uuid, numeric, text, jsonb)                   to service_role;
grant execute on function public.admin_process_transaction(uuid, uuid, text, text)                to service_role;
grant execute on function public.admin_adjust_balance(uuid, uuid, numeric, text)                  to service_role;
grant execute on function public.apply_asset_price(uuid, numeric, boolean)                        to service_role;
grant execute on function public.get_portfolio(uuid)                                              to service_role;

-- ===== 20261006000006_rls_policies.sql =====
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

-- ===== 20261006000007_storage.sql =====
-- =====================================================================
-- 07  Storage buckets and policies
--
-- Files live under  <bucket>/<user_id>/<filename>
-- so ownership can be checked from the first folder segment.
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('kyc-documents',  'kyc-documents',  false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('deposit-proofs', 'deposit-proofs', false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('avatars',        'avatars',        true,  2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- KYC documents: owner can upload/read their own, admins can read all
create policy "kyc docs: owner upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'kyc-documents' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "kyc docs: owner or admin read" on storage.objects
  for select to authenticated
  using (bucket_id = 'kyc-documents' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- Deposit proofs: same pattern
create policy "deposit proofs: owner upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'deposit-proofs' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "deposit proofs: owner or admin read" on storage.objects
  for select to authenticated
  using (bucket_id = 'deposit-proofs' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- Avatars: public read (bucket is public), owner writes
create policy "avatars: owner upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars: owner update" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars: owner delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- ===== 20261006000008_realtime.sql =====
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

-- ===== seed.sql =====
-- =====================================================================
-- Seed data (safe to re-run). Prices are PLACEHOLDERS: the update-prices
-- edge function overwrites them for coingecko / twelvedata assets, and
-- 'manual' assets are priced from the admin panel.
-- =====================================================================

insert into public.assets
  (symbol, name, asset_class, price, price_provider, provider_symbol, quantity_decimals, min_order_amount)
values
  -- crypto (CoinGecko ids)
  ('BTC',    'Bitcoin',            'crypto',    65000,  'coingecko', 'bitcoin',      8, 10),
  ('ETH',    'Ethereum',           'crypto',    3200,   'coingecko', 'ethereum',     8, 10),
  ('SOL',    'Solana',             'crypto',    150,    'coingecko', 'solana',       6, 10),
  ('XRP',    'XRP',                'crypto',    0.55,   'coingecko', 'ripple',       4, 10),
  -- forex (Twelve Data symbols)
  ('EURUSD', 'Euro / US Dollar',   'forex',     1.08,   'twelvedata', 'EUR/USD',     2, 10),
  ('GBPUSD', 'British Pound / US Dollar', 'forex', 1.27, 'twelvedata', 'GBP/USD',    2, 10),
  ('USDJPY', 'US Dollar / Japanese Yen',  'forex', 150,  'twelvedata', 'USD/JPY',    2, 10),
  -- stocks
  ('AAPL',   'Apple Inc.',         'stock',     190,    'twelvedata', 'AAPL',        4, 5),
  ('TSLA',   'Tesla, Inc.',        'stock',     240,    'twelvedata', 'TSLA',        4, 5),
  ('NVDA',   'NVIDIA Corporation', 'stock',     120,    'twelvedata', 'NVDA',        4, 5),
  ('MSFT',   'Microsoft Corporation', 'stock',  420,    'twelvedata', 'MSFT',        4, 5),
  -- commodities
  ('XAUUSD', 'Gold / US Dollar',   'commodity', 2400,   'twelvedata', 'XAU/USD',     4, 10),
  ('WTI',    'Crude Oil (WTI)',    'commodity', 80,     'manual',     null,          2, 10)
on conflict (symbol) do nothing;

-- Placeholder payment methods: replace the details with your real accounts.
insert into public.payment_methods (name, type, currency, details, instructions, min_amount, sort_order)
select * from (values
  ('Bank Transfer', 'bank_transfer', 'USD',
   '{"bank_name":"YOUR BANK","account_name":"YOUR COMPANY LTD","account_number":"0000000000"}'::jsonb,
   'Transfer the exact amount, then upload your payment receipt.', 10::numeric, 1),
  ('USDT (TRC20)', 'crypto', 'USD',
   '{"network":"TRC20","address":"REPLACE_WITH_YOUR_WALLET_ADDRESS"}'::jsonb,
   'Send only USDT on the TRC20 network, then upload a screenshot of the transaction.', 20::numeric, 2)
) as v(name, type, currency, details, instructions, min_amount, sort_order)
where not exists (select 1 from public.payment_methods);
