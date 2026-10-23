# Plan 005: Make sync resilient to bad operations and bounded pulls

> **Executor instructions**: Follow step by step; verify each step; update the
> status row. STOP if the sync contract change would require a database
> migration not listed here.
>
> **Drift check**: `git diff --stat 4e42297..HEAD -- lib/features/sync lib/features/transactions/data lib/features/debts/data lib/features/budgets/data integration_test/support/harness.dart test/features/sync`

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: none
- **Category**: bug / tests
- **Planned at**: commit `4e42297`, 2026-10-23

## Why this matters

One rejected queue operation currently aborts the whole sync pass and rethrows,
so no later write is pushed and `_pull()` never runs. The next pass retries the
same poison operation forever. Separately, the pull watermark is the device
clock taken after the fetch, and pulls are unbounded: rows written remotely
during the pull window or beyond PostgREST's max-row cap are never fetched.

After this plan, one bad operation cannot block the queue, irrecoverable
payloads are quarantined, pulls page until exhausted, and the watermark only
advances to the newest server value actually received.

## Current state

- `lib/features/sync/data/repositories/sync_repository_impl.dart:107-124` —
  serial push loop; on `ServerException` it requeues and `rethrow`s; `_pull()`
  only runs after a clean loop; watermark = `clock.now()`.
- `lib/features/sync/data/repositories/sync_repository_impl.dart:146-152` —
  `FormatException` returns `sync_invalid_payload` without removing/requeueing
  the operation.
- `lib/features/sync/data/datasources/supabase_rest_sync_data_source.dart:125-132`
  — `select=*`, `updated_at=gt.<local timestamp>`, `order=updated_at.asc`, no
  `limit`/`Range`.
- `lib/features/sync/data/repositories/sync_repository_impl.dart:245-338` —
  per-entity pulls and merges.
- `integration_test/support/harness.dart:172-175` — transaction/debt
  repositories are constructed without a `syncQueue`; budgets pass one.

Conventions: `Result<T>` at boundaries; `SyncReport`; exponential backoff in
`SyncOperation`; tests in `test/features/sync/data/repositories/sync_repository_impl_test.dart`
with fake local/remote data sources.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues |
| Unit | `flutter test --coverage` | all pass |
| Coverage | `dart run tool/check_coverage.dart` | passed |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |

## Scope

**In scope**
- `lib/features/sync/data/repositories/sync_repository_impl.dart`
- `lib/features/sync/data/datasources/supabase_rest_sync_data_source.dart`
- `lib/features/sync/domain/**` if a report field is added
- `integration_test/support/harness.dart`
- `test/features/sync/**`
- `integration_test/app_flow_test.dart` (one queue/pending assertion)

**Out of scope**
- New synced entity types (plan 007).
- Changing conflict policy from LWW.
- Server-side `updated_at` triggers (document as follow-up).

## Steps

### Step 1: Isolate per-operation failures

In `syncNow`'s push loop:
- On `ServerException`: requeue with backoff and **continue** to the next
  operation; record `failed++`.
- On `FormatException`: remove the operation from the queue (it can never
  succeed) and record `discarded++`; do not abort.
- After the loop, always run `_pull()` and `_purgeTombstones()`, even when some
  pushes failed.
- Return `Right(SyncReport(...))`; add `failed` and `discarded` integers to
  `SyncReport` (domain entity) and include them in tests. Do not log payloads
  or financial amounts.
- Keep the `attempts`/`nextAttemptAt` backoff for failed operations.

**Verify**: new repository test with `[bad, good]` operations asserts `good` is
removed from the queue, `bad` remains with attempts+1, and pull still ran.

### Step 2: Anchor the pull watermark to received data

Change `_pull()` to collect the maximum `updatedAt` of all rows actually
received (before merge). After a successful pull:
- if at least one row was received → `setLastSyncedAt(maxUpdatedAt)`;
- if none → keep the previous watermark (do not advance to local now).

Keep `SyncReport.pulled` as the count of merged rows.

**Verify**: test where the fake remote returns a row with `updatedAt` in the
past and another with a future value; watermark equals the max, not
`clock.now()`. Test empty pull leaves the previous watermark unchanged.

### Step 3: Page the pull

Add `limit`/`offset` (or `Range`) to each remote fetch method in
`SupabaseRestSyncDataSource`:
- `fetchTransactions({updatedAfter, int limit = 500, int offset = 0})`;
- same for debts and budgets.
- Query includes `limit` and `offset` (or `Range: <offset>-<offset+limit-1>`),
  preserving `order=updated_at.asc`.

In `_pull`, loop per entity until a page returns fewer than `limit` rows, with
a hard cap (e.g. 100 pages) to avoid infinite loops. Merge each page
incrementally; collect the global max `updatedAt` across pages.

**Verify**: fake remote with 2 pages (500 + 3 rows) asserts all rows merged and
three fetch calls; a single short page stops after one call.

### Step 4: Wire the test harness and add an integration assertion

In `integration_test/support/harness.dart`, construct
`TransactionRepositoryImpl(..., syncQueue: syncLocal)` and
`DebtRepositoryImpl(..., syncQueue: syncLocal)` (matching the production graph
in `lib/core/di/injection.config.dart`).

Add an integration assertion: after adding a transaction, the pending count
shown by `SyncStatusChip` increases (sync remains unconfigured), proving the
offline write was queued.

**Verify**: `flutter test -d linux integration_test/app_flow_test.dart` passes.

## Test plan

Extend `test/features/sync/data/repositories/sync_repository_impl_test.dart`
with:
- one poison FormatException followed by a valid operation (valid one pushes,
  poison is removed);
- one ServerException followed by a valid operation (valid one pushes, failed
  one is requeued, pull runs);
- watermark uses max received `updatedAt`;
- empty pull keeps the previous watermark;
- pagination happy path and short-page stop.

Follow the existing fake local/remote data source patterns in that file.

## Done criteria

- [ ] A failing operation no longer prevents later pushes or pulls.
- [ ] `SyncReport` exposes failed/discarded counts and tests assert them.
- [ ] Pull watermark never uses `clock.now()` for advancement.
- [ ] Pull pages until short page; cap enforced.
- [ ] Harness wires the queue; integration pending count test passes.
- [ ] `flutter analyze`, unit coverage, coverage gate, Linux integration pass.
- [ ] `plans/README.md` updated.

## STOP conditions

- `SyncReport` is consumed by UI in a way that requires a UI change beyond the
  pending-count chip.
- PostgREST rejects `offset` for the configured project (verify with a fake,
  then STOP and report if only `Range` works).
- A pull page contains rows older than the current watermark (server ordering
  violation); report instead of silently skipping.

## Maintenance notes

- Server `updated_at` is still client-supplied; a server trigger is the
  long-term fix. Keep the max-received watermark until then.
- New synced entities must implement paging in the same loop.
- Reviewer: confirm failed operations still respect backoff and do not spin.
