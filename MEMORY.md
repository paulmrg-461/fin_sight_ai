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

## Current slice: Auth + tombstones + budgets + CI (IMPLEMENTED, pending commit/push)

Goal: queue local writes offline, push them to Supabase, pull remote changes, and resolve conflicts last-write-wins.

### Decisions

- Use Supabase **PostgREST over `http.Client`** (no `supabase_flutter` dependency).
- Credentials from `AppEnv` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); missing config yields `supabase_not_configured` and a non-fatal offline report.
- Queue lives in `lib/core/sync/sync_operation.dart`; key = `<entityType>:<entityId>` so repeated edits collapse.
- Sync scope: **transactions and debts**. Receipts remain local-only for now.
- Conflict policy: if remote `updatedAt` is newer than the local payload, remote wins and is written locally; otherwise push local.
- Deletes write `deletedAt` tombstones and are pushed/pulled; local queries hide tombstones while they remain for idempotent sync.
- Local store remains the source of truth; a remote failure never rolls back a local write.
- Sync queue failures must not fail the business write.
- UI: app-level `SyncBloc` + dashboard AppBar `SyncStatusChip` (manual sync + pending count), auto-sync status on startup.
- Hive boxes: `sync_queue`, `sync_meta`, `budgets`.
- Auth: Supabase GoTrue REST + `flutter_secure_storage`; sync uses the access token and reports unauthenticated state.
- Budgets are local-only for now; aggregation comes from `TransactionRepository`.
- SQL: `0001_init.sql`, `0002_tombstones.sql`, RLS test script.

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
- [x] Supabase Auth (GoTrue REST), secure session storage, refresh, login UI.
- [x] JWT-authenticated sync with offline/unauthenticated reporting.
- [x] RLS verification SQL + `supabase/verify_rls.sh`.
- [x] Soft-delete tombstones for transactions and debts.
- [x] Budgets/categories slice (domain/data/presentation + route).
- [x] GitHub Actions CI.
- [x] `flutter analyze`, unit + integration tests.
- [x] Commit + push.

## Verification

- `flutter analyze` clean.
- 467 unit/widget tests passing.
- 9 integration tests passing on Linux.
- Coverage: auth 94.9/92.0%, budgets 92.5/93.7%, sync 100/91.8%, core 91.6%.
- SQL: `0001_init.sql`, `0002_tombstones.sql`, `tests/rls_test.sql`.

## Known gaps / next

1. Run the RLS script against a real Supabase project (needs credentials).
2. Sync budgets and receipt metadata.
3. Receipt image persistence (currently stores only the picked path).
4. Tombstone compaction and sync backoff.
5. Streaming AI responses and conversation memory.
6. Money as integer minor units instead of `double`.

## Conventions to keep

- English docs, Conventional Commits, atomic commit + push per functionality.
- Domain pure Dart; `Result<T> = Either<Failure, T>` at boundaries.
- Sealed + `Equatable` BLoC states; screens handle loading/success/empty/error.
- External services behind interfaces and faked in tests.
- Never commit real credentials; `.env` only has empty placeholders.
