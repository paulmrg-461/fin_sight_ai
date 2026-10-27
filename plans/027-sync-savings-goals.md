# Plan 027: Sync savings goals with Supabase

> **Executor instructions**: Follow the definitions/LWW pipeline. Tombstones are
> upserts with `deleted_at`; never hard-delete synced goals.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 005, 026
- **Category**: sync / migration
- **Planned at**: commit 20c3dea, 2026-10-27
- **Status**: DONE

## What shipped

- Migration `0007_savings_goals.sql`: owner RLS, updated/active indexes,
  `contributions` jsonb, `target_date`, `updated_at`, `deleted_at`.
- `SyncEntityType.savingsGoal`; repository stamps `updatedAt`/`isSynced`, queues
  upserts on add/contribution, and writes a tombstone + upsert on delete.
- Model/data source carry sync metadata; visible reads hide tombstones, sync
  merges use `getAllGoals`, and tombstones purge after 30 days.
- Remote mapping (`savings_goals`, snake_case) and push/pull/merge with existing
  LWW rules; pull runs after wallets/transfers and before the ledger.
- RLS test covers owner isolation; local migration+RLS validation passes.
- Plan 026's “local-only” note is superseded.

## Tests

- Savings repository queue upsert/tombstone and purge.
- Supabase snake_case round-trip for goals.
- Sync push, conflict (remote newer), and tombstone pull.
- Full analyze/coverage/integration gates.

## Done criteria

- [x] Savings goals enqueue and round-trip through sync.
- [x] Pull/merge respects LWW and tombstones.
- [x] Migration is in `apply_all` and RLS verification.
- [x] Analyze, coverage gate, and Linux integration pass.
