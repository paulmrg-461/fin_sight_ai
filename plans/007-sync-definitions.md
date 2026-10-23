# Plan 007: Sync categories, schedules, wallets, and transfers

> **Executor instructions**: This is the largest plan. Follow steps in order and
> do not skip tests. Update the status row. STOP if any dependency plan is not
> merged.
>
> **Drift check**: `git diff --stat 4e42297..HEAD -- lib/core/sync lib/features/sync lib/features/categories lib/features/scheduled_payments lib/features/wallets supabase/migrations test/features/sync`

## Status

- **Priority**: P2
- **Effort**: L
- **Risk**: MED
- **Depends on**: 001, 002, 005, 006
- **Category**: direction / migration
- **Planned at**: commit `4e42297`, 2026-10-23

## Why this matters

"Sign in to sync" currently covers only transactions, debts, and budgets. A
second device gets transactions without the category catalog, recurring
schedules, wallets, or transfers. Generated expenses can reference a wallet id
that does not exist remotely, and rent never auto-creates on the other device.

After this plan, the full model syncs with the existing LWW/tombstone rules and
RLS, while generated expenses keep their deterministic idempotency.

## Current state

- `lib/core/sync/sync_operation.dart:2` — `SyncEntityType { transaction, debt, budget }`.
- `lib/features/categories/data/repositories/category_repository_impl.dart` —
  local only; no `SyncQueue`.
- `lib/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart`
  — local only; `deletePayment` hard-deletes; no tombstone.
- `lib/features/wallets/data/repositories/wallet_repository_impl.dart` — local
  only; default ids `wallet-bank`/`wallet-cash`.
- `supabase/migrations/0001_init.sql`, `0002_tombstones.sql`, `0003_budgets.sql`,
  `0004_wallet_ids.sql` — remote tables exist only for transactions/debts/budgets.
- `lib/features/sync/data/repositories/sync_repository_impl.dart` and
  `supabase_rest_sync_data_source.dart` — explicit per-entity push/pull/merge
  blocks; follow them as the pattern.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Generate DI | `dart run build_runner build --delete-conflicting-outputs` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues |
| Unit | `flutter test --coverage` | all pass |
| Coverage | `dart run tool/check_coverage.dart` | passed |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |
| RLS (manual) | `./supabase/verify_rls.sh` with `SUPABASE_DB_URL` | all policies pass |

## Scope

**In scope**
- `supabase/migrations/0005_definitions_sync.sql` (new)
- `supabase/tests/rls_test.sql`
- `lib/core/sync/sync_operation.dart`
- category/schedule/wallet entities, models, repositories
- `lib/features/sync/data/**`, `lib/features/sync/domain/**`
- tests under `test/features/sync`, `test/features/categories`,
  `test/features/scheduled_payments`, `test/features/wallets`
- `specs/SPEC-sync.md`, `supabase/README.md`, `README.md`

**Out of scope**
- Receipt metadata sync, FX conversion, multi-user collaboration.
- Changing the deterministic scheduled-transaction UUID contract.

## Steps

### Step 1: Add the migration

Create `supabase/migrations/0005_definitions_sync.sql` with tables and owner
RLS, matching the style of `0003_budgets.sql`:

```sql
create table if not exists public.categories (
  id text primary key,
  user_id uuid not null default auth.uid(),
  name text not null,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.scheduled_payments (
  id text primary key,
  user_id uuid not null default auth.uid(),
  name text not null,
  amount numeric(14,2) not null,
  category text not null,
  category_id text,
  frequency text not null check (frequency in ('monthly','yearly')),
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

create table if not exists public.wallets (
  id text primary key,
  user_id uuid not null default auth.uid(),
  name text not null,
  type text not null check (type in ('bank','cash')),
  opening_balance numeric(14,2) not null default 0,
  currency text not null default 'COP',
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.wallet_transfers (
  id text primary key,
  user_id uuid not null default auth.uid(),
  from_wallet_id text not null,
  to_wallet_id text not null,
  amount numeric(14,2) not null,
  date timestamptz not null,
  note text not null default '',
  created_at timestamptz not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
```

For each table: enable RLS, add `user_id = auth.uid()` `using`/`with check`
policies, grant to `authenticated`, revoke from `anon`, add
`(user_id, updated_at)` indexes. Add `category_id` to `public.transactions` and
`public.budgets` with `alter table ... add column if not exists category_id text;`.

Add RLS checks to `supabase/tests/rls_test.sql` for the four new tables.

**Verify**: SQL parses (`psql --single-transaction -f ...` on a scratch DB) or
the project's `supabase db lint` if available; do not apply to production.

### Step 2: Extend sync types and entities

- `SyncEntityType`: add `category`, `scheduledPayment`, `wallet`,
  `walletTransfer`.
- `CategoryEntity`: add `isSynced` (default false) and `deletedAt` (null).
- `ScheduledPaymentEntity`: add `isSynced`, `deletedAt`; `deletePayment` writes
  a tombstone instead of hard delete.
- `WalletEntity` / `WalletTransferEntity`: add `isSynced`, `deletedAt`,
  `updatedAt` where missing.
- Models: JSON round-trip for all new fields; `deletedAt`/`isSynced` optional.

**Verify**: model round-trip tests; existing tests updated.

### Step 3: Enqueue definitions

Inject `SyncQueue?` into the category, schedule, wallet repositories (optional
to preserve tests) and enqueue:
- category upsert on add/rename/archive (payload includes `is_archived`);
- schedule upsert on add/update/pause/resume/pay and tombstone on delete;
- wallet upsert on balance reconciliation/default creation;
- transfer upsert on transfer creation.
Set `updatedAt = clock.now()`, `isSynced = false` before enqueue. Queue failures
must not fail the local write (copy `_enqueue` from
`transaction_repository_impl.dart`).

**Verify**: repository tests assert one queue operation per write with the right
entity type/id.

### Step 4: Remote mapping and push

In `SupabaseRestSyncDataSource`, add table mapping:
- categories → `categories` (snake_case columns, `is_archived`);
- schedules → `scheduled_payments` (`next_due_date`, `day_of_month`, `is_active`,
  `last_paid_at`, `category_id`);
- wallets → `wallets` (`opening_balance`);
- transfers → `wallet_transfers` (`from_wallet_id`, `to_wallet_id`).

Push each in `SyncRepositoryImpl._push` with `on_conflict=id` upserts, following
the existing transaction/debt blocks. Include `category_id` in transaction and
budget payloads (from plan 006).

**Verify**: sync repo tests with fake remote assert each entity maps to the
right table and round-trips.

### Step 5: Pull and merge

Extend `_pull`/`_merge` for the four entities with the existing LWW rule
(`updatedAt` newer wins; tombstones hide rows). Pull categories first, then
schedules/wallets/transfers, then transactions/debts/budgets, so generated
expenses resolve their references. Use paging from plan 005.

Conflict notes:
- Schedules: LWW on `updatedAt`; keep `lastPaidAt`/`nextDueDate` from the newer
  row.
- Generated expenses: deterministic ids mean two devices writing the same
  period collide on the same row; last write wins, no duplicate.
- Wallets: `wallet-bank`/`wallet-cash` stable ids make defaults converge; LWW
  applies to opening balances.

**Verify**: sync tests for each entity, including tombstone pull and LWW.

### Step 6: Docs and flags

Update `specs/SPEC-sync.md` (entity list/fields), `README.md` (sync scope),
`supabase/README.md` (migration order), and MEMORY known gaps. Note that pulled
definitions require a second sync pass on first run if transactions reference
categories that arrive later.

## Test plan

- Data: JSON round-trips with new fields for all entities; tombstone scheduling.
- Repositories: queue enqueue on every write.
- Sync repo: push/pull/merge per entity, LWW, tombstones, deterministic schedule
  collision.
- RLS: owner isolation for the four tables.
- Integration: seed a fake remote, sync as A, sign out (plan 002), sync as B,
  assert B's definitions and transactions are independent.

## Done criteria

- [ ] Migration 0005 applies cleanly to a scratch DB; RLS tests pass.
- [ ] All four entities enqueue and round-trip through sync.
- [ ] Pull order is categories → definitions → ledger.
- [ ] `flutter analyze`, unit coverage, coverage gate, Linux integration pass.
- [ ] Docs updated; `plans/README.md` updated.

## STOP conditions

- Migration numbering conflicts with an unmerged migration.
- Deterministic scheduled-expense ids collide across users in a way that breaks
  RLS (they include only schedule id + date; verify ids are globally unique
  because schedule ids are UUIDs).
- Pull order cannot resolve references without a second pass; report the design
  gap rather than inventing a merge order.

## Maintenance notes

- Any new definition entity must join the pull order and RLS tests.
- Consider the adapter refactor (per-entity sync adapter) after this lands to
  avoid a sixth copy of push/pull blocks.
- Reviewer: verify tombstone deletes never remove generated expenses.
