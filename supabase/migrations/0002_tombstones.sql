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
