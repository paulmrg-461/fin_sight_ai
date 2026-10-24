-- RLS verification for FinSight AI.
--
-- Run against a real Supabase database with:
--   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_test.sql
--
-- The script creates two synthetic JWT subjects inside a transaction and rolls
-- back at the end. It fails loudly if one user can read another user's rows.

begin;

-- User A inserts and reads their own transaction.
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

insert into public.transactions
  (id, amount, type, category, description, date, updated_at)
values
  ('rls-check-a', 10, 'expense', 'Test', 'RLS check', now(), now());

do $$
begin
  if (select count(*) from public.transactions where id = 'rls-check-a') <> 1 then
    raise exception 'RLS failure: owner cannot read their own transaction';
  end if;
end $$;

-- User B must not see or modify User A's transaction.
reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

do $$
begin
  if (select count(*) from public.transactions where id = 'rls-check-a') <> 0 then
    raise exception 'RLS failure: user B can read user A transactions';
  end if;
end $$;

update public.transactions
  set amount = 999
  where id = 'rls-check-a';

do $$
begin
  if (select amount from public.transactions where id = 'rls-check-a') is not null then
    raise exception 'RLS failure: user B can update user A transactions';
  end if;
end $$;

delete from public.transactions where id = 'rls-check-a';

do $$
begin
  if (select count(*) from public.transactions where id = 'rls-check-a') <> 0 then
    raise exception 'RLS failure: user B can delete user A transactions';
  end if;
end $$;


-- Receivables: owner isolation.
reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

insert into public.receivables
  (id, debtor_name, total_amount, remaining_amount, date_lent, status,
   payment_history, created_at, updated_at)
values
  ('rls-receivable-a', 'Ana', 1000, 600, now(), 'active',
   '[]'::jsonb, now(), now());

do $$
begin
  if (select count(*) from public.receivables where id = 'rls-receivable-a') <> 1 then
    raise exception 'RLS failure: owner cannot read their own receivable';
  end if;
end $$;

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

do $$
begin
  if (select count(*) from public.receivables where id = 'rls-receivable-a') <> 0 then
    raise exception 'RLS failure: user B can read user A receivables';
  end if;
end $$;

update public.receivables
  set remaining_amount = 0
  where id = 'rls-receivable-a';

do $$
begin
  if (select remaining_amount from public.receivables where id = 'rls-receivable-a') is not null then
    raise exception 'RLS failure: user B can update user A receivables';
  end if;
end $$;

delete from public.receivables where id = 'rls-receivable-a';

do $$
begin
  if (select count(*) from public.receivables where id = 'rls-receivable-a') <> 0 then
    raise exception 'RLS failure: user B can delete user A receivables';
  end if;
end $$;

reset role;
rollback;
