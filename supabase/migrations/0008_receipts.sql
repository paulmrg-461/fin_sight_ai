-- FinSight AI — synced receipt metadata
create table if not exists public.receipts (
  id text primary key,
  user_id uuid not null default auth.uid(),
  image_path text not null default '',
  merchant_name text not null,
  receipt_date timestamptz not null,
  total_amount numeric(14, 2) not null,
  currency text not null,
  items jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists receipts_user_updated_idx
  on public.receipts (user_id, updated_at);

alter table public.receipts enable row level security;

drop policy if exists "receipts_owner_all" on public.receipts;
create policy "receipts_owner_all"
  on public.receipts
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.receipts
  to authenticated;
revoke all on table public.receipts from anon;
revoke truncate, references, trigger on table public.receipts
  from authenticated;
