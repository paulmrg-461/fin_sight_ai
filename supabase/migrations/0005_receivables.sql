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
