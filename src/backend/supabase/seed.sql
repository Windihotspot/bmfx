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
