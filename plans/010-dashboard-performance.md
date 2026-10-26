# Plan 010: Cut dashboard and startup ledger scans

> **Executor instructions**: Follow step by step; update the status row. STOP if
> the dashboard state contract cannot absorb the bundle without changing the
> UI states.
>
> **Drift check**: `git diff --stat 4e42297..HEAD -- lib/features/dashboard lib/features/transactions/data lib/main.dart test/features/dashboard integration_test/app_flow_test.dart`

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 003
- **Category**: perf
- **Planned at**: commit `4e42297`, 2026-10-23
- **Status**: DONE (two range reads per refresh; benchmark seeds 300 transactions). Seeded launch logs 199 ms inside the full suite and 1018–1128 ms when run alone (cold first-run warmup), so PERF-02 is filed as `plans/012-startup-lazy-loading.md` with instrumentation as its first step.

## Why this matters

Every dashboard refresh currently performs six full reads of the transaction
box: summary fetches current + previous, breakdown refetches current, comparison
refetches current + previous, and recent activity fetches the range again.
`HiveTransactionLocalDataSource` deserializes and sorts the entire box on each
read, so cost is O(lifetime transactions) × 6 and grows forever. The existing
launch benchmark awaits an empty dashboard, so it cannot detect this.

After this plan, one dashboard refresh performs **two** range reads (current and
previous) and derives all four outputs from them.

## Current state

- `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart:62-90` —
  sequential summary, breakdown, comparison, transactions calls.
- `lib/features/dashboard/data/repositories/dashboard_repository_impl.dart:22-82`
  — summary fetches current+previous; breakdown fetches current; comparison
  fetches current+previous.
- `lib/features/transactions/data/datasources/hive_transaction_local_data_source.dart:71-117`
  — every range query calls `_readAll()`, `removeWhere`, `sort`.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart:25-29` —
  refreshes on every return from a feature route.
- `lib/features/dashboard/domain/services/dashboard_calculator.dart` — pure
  calculations used by the repository.
- `lib/features/dashboard/presentation/bloc/dashboard_state.dart` — loaded
  state holds summary/breakdown/comparison/recent/start/end.

Conventions: pure calculations stay in `DashboardCalculator`; repositories
return `Result<T>`; BLoC emits loading/loaded/empty/failure.

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
- `lib/features/dashboard/domain/**`, `data/repositories/dashboard_repository_impl.dart`,
  `presentation/bloc/**`
- `test/features/dashboard/**`
- `test/app/app_test.dart`, `integration_test/support/harness.dart`,
  `integration_test/app_flow_test.dart` (mock/wiring updates)
- `plans/README.md`

**Out of scope**
- Changing Hive indices or migrating the transaction box.
- Deferring non-dashboard BLoC loads (follow-up only if Step 5 shows it is
  needed).
- Chart rendering changes.

## Steps

### Step 1: Define a dashboard bundle

Add to `lib/features/dashboard/domain/entities/dashboard_entities.dart`:

```dart
class DashboardData {
  const DashboardData({
    required this.summary,
    required this.breakdown,
    required this.comparison,
    required this.recentTransactions,
    required this.start,
    required this.end,
  });
  ...
}
```

Add `GetDashboardDataUseCase` with `DashboardRangeParams` that calls a new
repository method `getDashboardData({required start, required end})`.

### Step 2: Implement one fetch per range in the repository

In `DashboardRepositoryImpl.getDashboardData`:
1. `current = await _fetch(start, end)` once.
2. `previous = await _fetch(previousStart, previousEnd)` once.
3. Build summary, breakdown, comparison from the same lists via
   `DashboardCalculator`.
4. `recent = current.sorted by date desc, take 5`.
5. Return `Right(DashboardData(...))`.

Keep the existing individual methods temporarily for compatibility but mark
them deprecated in comments; remove them once no callers remain.

**Verify**: repository test with a fake `TransactionRepository` that counts
calls asserts exactly 2 range calls per `getDashboardData`, and outputs match
the old methods' values.

### Step 3: Collapse the BLoC

1. Replace the four use-case dependencies in `DashboardBloc` with
   `GetDashboardDataUseCase` (single call).
2. Map the bundle into `DashboardLoaded` / `DashboardEmpty` exactly as today
   (`recentTransactions` from the bundle).
3. Remove the redundant `_getTransactionsByRange` call.
4. Update `lib/app/app.dart`, `lib/main.dart`, `integration_test/support/harness.dart`,
   and `test/app/app_test.dart` constructors/mocks.

**Verify**: existing dashboard BLoC tests updated; all states still covered.

### Step 4: Regression and call-count tests

Add:
- a unit test asserting two range reads, not six;
- a test with transactions in both months proving summary/comparison still use
  previous data;
- an empty-range test returning `DashboardEmpty`.

### Step 5: Make the benchmark meaningful

In `integration_test/app_flow_test.dart`, the benchmark currently seeds no
transactions. Seed ~300 transactions spanning 3 months through
`harness.addTransaction` before the benchmark, then measure launch + dashboard
render. Record the result with the existing `debugPrint` format. Do not assert a
strict wall-clock bound in CI; instead assert it completes and log the number
for tracking. If startup exceeds 1s with the seeded data, STOP and report
PERF-02 (startup lazy loading) as a follow-up rather than expanding this plan.

## Test plan

- Repository call-count and value-equivalence tests.
- BLoC state tests with the bundle.
- Empty-month and previous-month comparison edges.
- Seeded integration benchmark.

## Done criteria

- [x] One dashboard refresh performs exactly two range reads.
- [x] All dashboard states still render correctly.
- [x] Benchmark seeds data and logs a non-empty-dashboard number.
- [x] `flutter analyze`, unit coverage, coverage gate, Linux integration pass.
- [x] Old use cases removed (single `GetDashboardDataUseCase`).
- [x] `plans/README.md` updated.

## STOP conditions

- `DashboardLoaded` consumers expect separate loading states per section.
- The single fetch changes error semantics (one section failing should fail the
  whole dashboard; confirm this matches the current behavior).
- Seeding the benchmark makes the existing 30s test timeout flaky; report.

## Maintenance notes

- Future dashboard widgets must consume the bundle, not add another fetch.
- When Hive indices are introduced, revisit `getTransactionsByDateRange` to
  avoid full-box reads.
- Reviewer: check that recent activity is derived from `current`, not a new
  query.
