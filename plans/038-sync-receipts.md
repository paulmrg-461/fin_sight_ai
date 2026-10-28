# 038 — Sync receipt metadata

**Priority:** P2 · **Effort:** M · **Depends on:** 005 (sync resilience), 007 (definitions sync), 028 (entity isolation)

## Problem

Scanned receipts live only in the local Hive box. Reinstalling, switching
devices, or clearing local data silently loses the merchant, date, total,
currency, and line items; the existing sync queue covers every other ledger
entity.

## Scope

- Add `updated_at` / sync metadata to the receipt model and stamp writes.
- Enqueue an upsert in the receipt repository after each local save, following
  the savings-goal pattern: the local write is authoritative and a queue
  failure never rolls it back.
- Add `receipt` as a sync entity with push, pull, LWW conflict resolution, and
  isolated failures.
- Ship migration `0008_receipts.sql` with owner-only RLS, matching the other
  tables.
- Cover the repository, model, remote row mapping, and the sync passes.

## Out of scope

- Uploading the receipt image itself; only metadata syncs. `image_path` is
  stored for reference, and the preview already hides missing files.
- Deleting receipts (no delete affordance exists yet).
- Receipt search or filtering.

## Design

- `ReceiptEntity` gains optional `updatedAt` and `isSynced`, plus
  `lastModified => updatedAt ?? date`. Business equality ignores sync metadata,
  as in the other entities.
- `ReceiptModel` serializes both fields; `fromJson` tolerates older rows
  without them, so existing local data keeps working.
- `ReceiptRepositoryImpl.saveReceipt` writes with `updatedAt = clock.now()` and
  `isSynced = false`, then enqueues `SyncEntityType.receipt`.
- `SyncRepositoryImpl` takes `ReceiptLocalDataSource`, pushes with a remote
  fetch for LWW, marks accepted rows `isSynced`, and merges pulled rows only
  when newer. Delete operations are ignored because receipts never enqueue
  them.
- `SupabaseRestSyncDataSource` maps `receipt_date`, `merchant_name`,
  `total_amount`, `currency`, `items`, and `updated_at`; `image_path` defaults
  to an empty string when absent.
- The sync diagnostics chip labels the entity as **Receipts**.

## SQL

`supabase/migrations/0008_receipts.sql` creates `public.receipts` with
`user_id uuid default auth.uid()`, owner RLS, and grants for `authenticated`
only. Also appended to `supabase/apply_all.sql` and covered by
`supabase/tests/rls_test.sql`.

**Live deployment is pending:** no database connection string is available in
this workspace, so 0007 and 0008 still need to be applied to the hosted project
before receipt sync can succeed outside local/offline mode.

## Verification

```bash
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart
flutter test -d linux integration_test/app_flow_test.dart
```

## Risks

- A missing `receipts` table surfaces as an isolated `supabase_http_404`
  failure; the rest of the sync pass continues.
- Receipts pulled from another device point at an `image_path` that does not
  exist locally. The preview checks `File.existsSync()` and simply omits the
  image.
