# Spec: Supabase synchronization

## Objective

Keep the local Hive store as the source of truth while asynchronously pushing queued changes to Supabase and pulling remote updates, with last-write-wins conflict resolution.

## Scope

- Synced entities: **transactions** and **debts**.
- Receipts stay local-only for now (metadata/path, not uploaded).
- Deletions are pushed; remote deletions are not pulled until tombstones exist.
- The app remains fully usable without Supabase credentials.

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
- Deletes enqueue a delete operation.
- A queue failure never fails the local write.

## Remote

`SyncRemoteDataSource` → `SupabaseRestSyncDataSource`:

- PostgREST over `http.Client` with `apikey` and `Authorization` headers.
- Transactions: `GET/POST/DELETE /rest/v1/transactions`; debts: `/rest/v1/debts`.
- Upserts use `on_conflict=id` and `Prefer: resolution=merge-duplicates,return=minimal`.
- Pulls use `updated_at=gt.<lastSyncedAt>&order=updated_at.asc`.
- Snake_case columns are mapped to the camelCase model JSON in both directions.
- Error codes: `supabase_not_configured`, `supabase_http_<status>`, `supabase_invalid_response`, `supabase_timeout`, `supabase_network_error`.

## Sync pass

`SyncRepositoryImpl.syncNow()`:

1. Read pending operations.
2. If Supabase is unconfigured, return a report with `isConfigured: false` and keep the queue.
3. For each operation:
   - Delete → remote delete, remove from queue.
   - Upsert → fetch remote row. If remote `updatedAt` is newer, write remote locally (conflict), remove from queue. Otherwise upsert and mark the local record `isSynced = true`.
   - On remote failure, increment `attempts`, keep the operation, and return `ServerFailure`.
4. Pull transactions and debts updated since `lastSyncedAt`, merging only newer remote rows.
5. Persist `lastSyncedAt`.

## Presentation

- `SyncBloc`: `LoadSyncStatus`, `SyncNow`; states initial/loading/idle/in-progress/success/failure.
- `SyncStatusChip` in the dashboard AppBar shows pending count, offline/configured state, and triggers manual sync.
- Startup dispatches `SyncNow`; without credentials it resolves to an offline report.

## Schema

`supabase/migrations/0001_init.sql` creates `transactions` and `debts` with `user_id default auth.uid()`, `updated_at` indexes, RLS enabled, and owner-only policies.

**Auth is a prerequisite for real sync.** Until the auth slice lands, sync fails safely with RLS/configuration errors and local data is preserved.

## Tests

- Queue serialization/collapse/metadata with real Hive.
- PostgREST mapping, headers, query params, and error codes with `MockClient`.
- Push, pull, conflict, delete, requeue, and invalid payload paths with mocked data sources.
- Repository enqueue integration for transactions and debts.
- `SyncBloc` transitions.

## Verification

```bash
flutter analyze
flutter test --coverage
flutter test -d linux integration_test/app_flow_test.dart
```
