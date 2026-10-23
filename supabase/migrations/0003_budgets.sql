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
