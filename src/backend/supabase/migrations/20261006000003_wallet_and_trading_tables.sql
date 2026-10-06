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
