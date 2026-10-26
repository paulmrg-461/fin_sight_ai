-- FinSight AI — full schema bundle (0001 + 0002 + 0003 + 0004)
-- Apply once in the Supabase SQL Editor or with supabase/apply_all.sh.

-- FinSight AI — initial Supabase schema
-- Requires Supabase Auth: user_id defaults to auth.uid() and RLS restricts rows
-- to their owner. The client must be authenticated for sync to succeed.

create extension if not exists "pgcrypto";

create table if not exists public.transactions (
  id text primary key,
  user_id uuid not null default auth.uid(),
  amount numeric(14, 2) not null,
  type text not null check (type in ('income', 'expense')),
  category text not null,
  description text not null default '',
  date timestamptz not null,
  receipt_image_path text,
  updated_at timestamptz not null default now()
);

create index if not exists transactions_user_updated_idx
  on public.transactions (user_id, updated_at);

alter table public.transactions enable row level security;

drop policy if exists "transactions_owner_all" on public.transactions;
create policy "transactions_owner_all"
  on public.transactions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Least-privilege grants: the app is authenticated-only and never uses anon
-- for data access. These grants make it safe to disable "Automatically expose
-- new tables" in the Supabase project settings.
grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.transactions
  to authenticated;
revoke all on table public.transactions from anon;
revoke truncate, references, trigger on table public.transactions from authenticated;

create table if not exists public.debts (
  id text primary key,
  user_id uuid not null default auth.uid(),
  creditor_name text not null,
  total_amount numeric(14, 2) not null,
  remaining_amount numeric(14, 2) not null,
  interest_rate numeric(6, 2) not null default 0,
  minimum_payment numeric(14, 2) not null,
  due_date timestamptz not null,
  status text not null check (status in ('active', 'paid')),
  payment_history jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists debts_user_updated_idx
  on public.debts (user_id, updated_at);

alter table public.debts enable row level security;

drop policy if exists "debts_owner_all" on public.debts;
create policy "debts_owner_all"
  on public.debts
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update, delete on table public.debts
  to authenticated;
revoke all on table public.debts from anon;
revoke truncate, references, trigger on table public.debts from authenticated;

-- 0002_tombstones.sql
-- FinSight AI — soft-delete tombstones
-- Keeps deleted rows visible to the sync client so deletions can propagate
-- between devices. UI queries filter deleted_at at the local layer.

alter table public.transactions
  add column if not exists deleted_at timestamptz;

alter table public.debts
  add column if not exists deleted_at timestamptz;

drop index if exists transactions_user_updated_idx;
create index if not exists transactions_user_updated_idx
  on public.transactions (user_id, updated_at);

drop index if exists debts_user_updated_idx;
create index if not exists debts_user_updated_idx
  on public.debts (user_id, updated_at);

create index if not exists transactions_user_active_idx
  on public.transactions (user_id, updated_at)
  where deleted_at is null;

create index if not exists debts_user_active_idx
  on public.debts (user_id, updated_at)
  where deleted_at is null;

-- 0003_budgets.sql
-- FinSight AI — synced monthly budgets
create table if not exists public.budgets (
  id text primary key,
  user_id uuid not null default auth.uid(),
  category text not null,
  monthly_limit numeric(14, 2) not null,
  month timestamptz not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists budgets_user_updated_idx
  on public.budgets (user_id, updated_at);

create index if not exists budgets_user_active_idx
  on public.budgets (user_id, updated_at)
  where deleted_at is null;

alter table public.budgets enable row level security;

drop policy if exists "budgets_owner_all" on public.budgets;
create policy "budgets_owner_all"
  on public.budgets
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update, delete on table public.budgets
  to authenticated;
revoke all on table public.budgets from anon;
revoke truncate, references, trigger on table public.budgets from authenticated;

-- 0004_wallet_ids.sql
-- Preserve the local bank/cash wallet assignment across syncs.
alter table public.transactions
  add column if not exists wallet_id text;


-- 0005_receivables.sql
-- FinSight AI — synced receivables ("Me deben")
create table if not exists public.receivables (
  id text primary key,
  user_id uuid not null default auth.uid(),
  debtor_name text not null,
  total_amount numeric(14, 2) not null,
  remaining_amount numeric(14, 2) not null,
  date_lent timestamptz not null,
  due_date timestamptz,
  notes text not null default '',
  status text not null check (status in ('active', 'paid')),
  payment_history jsonb not null default '[]'::jsonb,
  created_at timestamptz not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists receivables_user_updated_idx
  on public.receivables (user_id, updated_at);

create index if not exists receivables_user_active_idx
  on public.receivables (user_id, updated_at)
  where deleted_at is null;

alter table public.receivables enable row level security;

drop policy if exists "receivables_owner_all" on public.receivables;
create policy "receivables_owner_all"
  on public.receivables
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.receivables
  to authenticated;
revoke all on table public.receivables from anon;
revoke truncate, references, trigger on table public.receivables
  from authenticated;

-- 0006_definitions_sync.sql
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
