-- FinSight AI — synced savings goals
create table if not exists public.savings_goals (
  id text primary key,
  user_id uuid not null default auth.uid(),
  name text not null,
  target_amount numeric(14, 2) not null,
  target_date timestamptz,
  contributions jsonb not null default '[]'::jsonb,
  created_at timestamptz not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists savings_goals_user_updated_idx
  on public.savings_goals (user_id, updated_at);

create index if not exists savings_goals_user_active_idx
  on public.savings_goals (user_id, updated_at)
  where deleted_at is null;

alter table public.savings_goals enable row level security;

drop policy if exists "savings_goals_owner_all" on public.savings_goals;
create policy "savings_goals_owner_all"
  on public.savings_goals
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.savings_goals
  to authenticated;
revoke all on table public.savings_goals from anon;
revoke truncate, references, trigger on table public.savings_goals
  from authenticated;
