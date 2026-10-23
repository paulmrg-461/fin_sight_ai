-- FinSight AI — full schema bundle (0001 + 0002 + 0003)
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

-- ============================================================
-- 0002_tombstones.sql
-- ============================================================

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

-- ============================================================
-- 0003_budgets.sql
-- ============================================================

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
