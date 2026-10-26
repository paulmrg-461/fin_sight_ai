-- FinSight AI — sync category catalog, schedules, wallets, and transfers.
--
-- Numbering note: plan 007 referenced `0005_definitions_sync.sql`, but 0005 is
-- already taken by receivables. This migration ships as 0006.
--
-- `category_id` is reserved for a future canonical category reference. The app
-- still stores category names, so it remains nullable and unused for now.

create table if not exists public.categories (
  id text primary key,
  user_id uuid not null default auth.uid(),
  name text not null,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists categories_user_updated_idx
  on public.categories (user_id, updated_at);

create table if not exists public.scheduled_payments (
  id text primary key,
  user_id uuid not null default auth.uid(),
  name text not null,
  amount numeric(14, 2) not null,
  type text not null default 'expense' check (type in ('income', 'expense')),
  category text not null,
  category_id text,
  frequency text not null check (frequency in ('monthly', 'yearly')),
  next_due_date timestamptz not null,
  day_of_month int not null,
  wallet_id text,
  notes text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null,
  updated_at timestamptz not null default now(),
  last_paid_at timestamptz,
  deleted_at timestamptz
);

create index if not exists scheduled_payments_user_updated_idx
  on public.scheduled_payments (user_id, updated_at);

create table if not exists public.wallets (
  id text primary key,
  user_id uuid not null default auth.uid(),
  name text not null,
  type text not null check (type in ('bank', 'cash')),
  opening_balance numeric(14, 2) not null default 0,
  currency text not null default 'COP',
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists wallets_user_updated_idx
  on public.wallets (user_id, updated_at);

create table if not exists public.wallet_transfers (
  id text primary key,
  user_id uuid not null default auth.uid(),
  from_wallet_id text not null,
  to_wallet_id text not null,
  amount numeric(14, 2) not null,
  date timestamptz not null,
  note text not null default '',
  created_at timestamptz not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists wallet_transfers_user_updated_idx
  on public.wallet_transfers (user_id, updated_at);

alter table public.transactions
  add column if not exists category_id text;

alter table public.budgets
  add column if not exists category_id text;

alter table public.categories enable row level security;
alter table public.scheduled_payments enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_transfers enable row level security;

drop policy if exists "categories_owner_all" on public.categories;
create policy "categories_owner_all"
  on public.categories
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "scheduled_payments_owner_all" on public.scheduled_payments;
create policy "scheduled_payments_owner_all"
  on public.scheduled_payments
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "wallets_owner_all" on public.wallets;
create policy "wallets_owner_all"
  on public.wallets
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "wallet_transfers_owner_all" on public.wallet_transfers;
create policy "wallet_transfers_owner_all"
  on public.wallet_transfers
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.categories
  to authenticated;
grant select, insert, update, delete on table public.scheduled_payments
  to authenticated;
grant select, insert, update, delete on table public.wallets
  to authenticated;
grant select, insert, update, delete on table public.wallet_transfers
  to authenticated;

revoke all on table public.categories from anon;
revoke all on table public.scheduled_payments from anon;
revoke all on table public.wallets from anon;
revoke all on table public.wallet_transfers from anon;

revoke truncate, references, trigger on table public.categories
  from authenticated;
revoke truncate, references, trigger on table public.scheduled_payments
  from authenticated;
revoke truncate, references, trigger on table public.wallets
  from authenticated;
revoke truncate, references, trigger on table public.wallet_transfers
  from authenticated;
