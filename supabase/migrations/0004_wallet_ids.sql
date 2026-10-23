-- Preserve the local bank/cash wallet assignment across syncs.
alter table public.transactions
  add column if not exists wallet_id text;
