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
