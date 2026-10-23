# Project Memory — FinSight AI

_Last updated: 2026-10-22. Read this before starting a new session._

## Delivered and pushed

| Area | Status |
| --- | --- |
| Core infrastructure (DI, routing, theme, env, domain base) | Done |
| Transactions slice | Done |
| Debts slice | Done |
| OCR slice (ML Kit + parser + preview + auto expense) | Done |
| AI Coach slice (Groq + prompts + insights) | Done |
| Dashboard analytics (fl_chart + aggregation) | Done |
| Integration suite (7 flows + benchmarks) | Done |

- Last pushed commit: `0f47edc test(integration): add end-to-end flows and performance benchmarks`.
- Branch: `main`, in sync with `origin/main`.
- Gates: `flutter analyze` clean, 324 unit/widget tests, 7 integration tests.
- Integration command: `flutter test -d linux integration_test/app_flow_test.dart`.

## Current slice: Supabase sync (IMPLEMENTED, pending commit/push)

Goal: queue local writes offline, push them to Supabase, pull remote changes, and resolve conflicts last-write-wins.

### Decisions

- Use Supabase **PostgREST over `http.Client`** (no `supabase_flutter` dependency).
- Credentials from `AppEnv` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); missing config yields `supabase_not_configured` and a non-fatal offline report.
- Queue lives in `lib/core/sync/sync_operation.dart`; key = `<entityType>:<entityId>` so repeated edits collapse.
- Sync scope: **transactions and debts**. Receipts remain local-only for now.
- Conflict policy: if remote `updatedAt` is newer than the local payload, remote wins and is written locally; otherwise push local.
- Deletes are pushed immediately; remote deletes from other devices are not pulled (documented limitation until tombstones exist).
- Local store remains the source of truth; a remote failure never rolls back a local write.
- Sync queue failures must not fail the business write.
- UI: app-level `SyncBloc` + dashboard AppBar `SyncStatusChip` (manual sync + pending count), auto-sync status on startup.
- Hive boxes to add: `sync_queue`, `sync_meta`.
- SQL migration will live in `supabase/migrations/0001_init.sql`; RLS/auth slice is still pending, so real sync requires configured Supabase auth.

### Progress

- [x] `SyncOperation`, enums, `SyncQueue` interface in `lib/core/sync/`.
- [x] `updatedAt` + `isSynced` on `TransactionEntity` and `DebtEntity`.
- [x] JSON mapping for the new fields in `TransactionModel` and `DebtModel`.
- [x] Enqueue operations from `TransactionRepositoryImpl` and `DebtRepositoryImpl`.
- [x] `SyncLocalDataSource` + Hive implementation (queue + last sync metadata).
- [x] `SyncRemoteDataSource` + Supabase REST implementation.
- [x] `SyncRepositoryImpl` (push, pull, conflict resolution, reports).
- [x] `SyncNowUseCase`, `GetSyncStatusUseCase`, `SyncBloc`, `SyncStatusChip`.
- [x] DI: boxes, module providers, app/main wiring.
- [x] Tests: queue, remote HTTP, sync repository, bloc, repository enqueue paths.
- [x] Docs: `SPEC-sync.md`, ARCHITECTURE, README, tasks.
- [x] `flutter analyze`, unit + integration tests.
- [x] Commit + push.

## Verification (sync slice)

- `flutter analyze` clean.
- 374 unit/widget tests passing.
- 7 integration tests passing on Linux.
- Coverage: sync domain 100%, sync data 91.5%, core 90.1%.
- SQL migration: `supabase/migrations/0001_init.sql`.

## Known gaps / next after sync

1. Supabase auth (anonymous or email) + RLS verification against a real project.
2. Tombstones for remote deletes.
3. Receipt image persistence (currently stores only the picked path).
4. Budgets/categories slice.
5. CI workflow for analyze + unit + integration tests.
6. Money as integer minor units instead of `double`.

## Conventions to keep

- English docs, Conventional Commits, atomic commit + push per functionality.
- Domain pure Dart; `Result<T> = Either<Failure, T>` at boundaries.
- Sealed + `Equatable` BLoC states; screens handle loading/success/empty/error.
- External services behind interfaces and faked in tests.
- Never commit real credentials; `.env` only has empty placeholders.
