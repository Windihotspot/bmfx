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
