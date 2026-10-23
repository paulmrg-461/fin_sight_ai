# Spec: Supabase synchronization

## Objective

Keep the local Hive store as the source of truth while asynchronously pushing queued changes to Supabase and pulling remote updates, with last-write-wins conflict resolution.

## Scope

- Synced entities: **transactions** and **debts**, including soft-delete tombstones.
- Receipts stay local-only for now (metadata/path, not uploaded).
- Deletions create `deletedAt` tombstones that are pushed and pulled; UI queries hide them.
- The app remains fully usable without Supabase credentials or a session.

## Queue

`lib/core/sync/sync_operation.dart`

- `SyncEntityType`: `transaction`, `debt`.
- `SyncOperationType`: `upsert`, `delete`.
- `SyncOperation` fields: `id` (`<entityType>:<entityId>`), `entityType`, `entityId`, `operationType`, `queuedAt`, `payload`, `attempts`.
- `SyncQueue.enqueue` is the write-side port used by feature repositories.
- Queue rows collapse by id: repeated offline edits keep only the latest payload.

Storage: Hive boxes `sync_queue` and `sync_meta` (`lastSyncedAt`).

## Local writes

- `TransactionRepositoryImpl` and `DebtRepositoryImpl` stamp `updatedAt = clock.now()` and `isSynced = false`, persist locally, then enqueue an upsert.
- Deletes write a tombstone (`deletedAt`, `updatedAt`, `isSynced = false`) and enqueue an upsert; legacy delete operations remain supported.
- Queries filter tombstones; Hive retains them so the deletion can be retried/idempotent.
- A queue failure never fails the local write.

## Remote

`SyncRemoteDataSource` → `SupabaseRestSyncDataSource`:

- PostgREST over `http.Client` with `apikey` (anon key) and `Authorization: Bearer <access token>` from Supabase Auth.
- Transactions: `GET/POST/DELETE /rest/v1/transactions`; debts: `/rest/v1/debts`.
- Upserts use `on_conflict=id` and `Prefer: resolution=merge-duplicates,return=minimal`.
- Pulls use `updated_at=gt.<lastSyncedAt>&order=updated_at.asc`.
- Snake_case columns are mapped to the camelCase model JSON in both directions.
- Rows include `deleted_at`; tombstones round-trip like any other update.
- Error codes: `supabase_not_configured`, `supabase_unauthenticated`, `supabase_http_<status>`, `supabase_invalid_response`, `supabase_timeout`, `supabase_network_error`.

## Sync pass

`SyncRepositoryImpl.syncNow()`:

1. Read pending operations.
2. If Supabase is unconfigured or the user has no valid session, return a report with `isConfigured` / `isAuthenticated` flags and keep the queue.
3. For each operation:
   - Delete → remote delete, remove from queue.
   - Upsert → fetch remote row. If remote `updatedAt` is newer, write remote locally (conflict), remove from queue. Otherwise upsert and mark the local record `isSynced = true`.
   - On remote failure, increment `attempts`, set `nextAttemptAt` with exponential backoff (1s, 2s, 4s… capped at 1h), keep the operation, and return `ServerFailure`.
4. Pull transactions and debts updated since `lastSyncedAt`, merging only newer remote rows.
5. Persist `lastSyncedAt`.
6. Purge local tombstones older than 30 days (best effort).

## Presentation

- `SyncBloc`: `LoadSyncStatus`, `SyncNow`; states initial/loading/idle/in-progress/success/failure.
- `SyncStatusChip` in the dashboard AppBar shows pending count, offline/configured/authenticated state, and triggers manual sync; when authenticated it pushes/pulls.
- Startup restores the auth session and syncs when authenticated; successful login triggers `SyncNow`.
- Without credentials/session the chip explains whether configuration or sign-in is missing.

## Schema

`supabase/migrations/0001_init.sql` creates `transactions` and `debts` with `user_id default auth.uid()`, `updated_at` indexes, RLS enabled, and owner-only policies. `0002_tombstones.sql` adds `deleted_at` and active-row indexes.

**Auth is a prerequisite for real sync.** Without a session, sync returns an offline report and keeps the queue; local data is never lost. RLS verification lives in `supabase/tests/rls_test.sql` and `supabase/verify_rls.sh`.

## Tests

- Queue serialization/collapse/metadata with real Hive.
- PostgREST mapping, headers, query params, and error codes with `MockClient`.
- Push, pull, conflict, delete, requeue, and invalid payload paths with mocked data sources.
- Repository enqueue integration for transactions and debts, including tombstones.
- `SyncBloc` transitions and authenticated/unauthenticated reports.
- Backoff scheduling and tombstone purge behavior.
- Auth datasource/repository/BLoC tests (GoTrue REST + secure storage).

## Verification

```bash
flutter analyze
flutter test --coverage
flutter test -d linux integration_test/app_flow_test.dart
```
