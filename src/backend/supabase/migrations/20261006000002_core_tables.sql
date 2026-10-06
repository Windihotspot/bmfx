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
