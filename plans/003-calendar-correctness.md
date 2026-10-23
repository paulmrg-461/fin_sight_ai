# Plan 003: Fix calendar-day storage for transactions and budgets

> **Executor instructions**: Follow step by step, run every verification, update
> the status row. STOP on drift or when the migration cannot be made
> idempotent.
>
> **Drift check**: `git diff --stat 4e42297..HEAD -- lib/features/transactions lib/features/budgets lib/core/utils lib/main.dart test/features/transactions test/features/budgets`

## Status

- **Priority**: P1
- **Effort**: S/M
- **Risk**: MED
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `4e42297`, 2026-10-23

## Why this matters

Transactions are created with `DateTime.now()` (time-of-day) and serialized
with `.toUtc()`, then displayed using the UTC date parts. In Colombia (UTC-5)
an expense recorded after 19:00 shows tomorrow's date; in UTC+ zones every
expense shows the previous day. Budget months have the same class of bug: a
local `DateTime(year, month)` is serialized with `.toUtc()` and compared by UTC
month parts, so budgets disappear in positive-offset zones.

After this plan, a user-selected calendar day is stored unambiguously and
renders the same day everywhere. Existing rows are migrated once.

## Current state

- `lib/features/transactions/presentation/widgets/transaction_form.dart:31` —
  `DateTime _date = DateTime.now();`.
- `lib/features/transactions/domain/usecases/add_transaction_usecase.dart:78-90`
  — forwards `params.date` unchanged.
- `lib/features/transactions/data/models/transaction_model.dart:99` —
  `'date': date.toUtc().toIso8601String()`; `:83` — `DateTime.parse(date)`.
- `lib/core/utils/date_formatters.dart:2` — reads `.day/.month/.year`.
- `lib/features/budgets/data/models/budget_model.dart:65` —
  `'month': month.toUtc().toIso8601String()`; `:56` parses with `DateTime.parse`.
- `lib/features/budgets/data/datasources/hive_budget_local_data_source.dart:21`
  — compares `budget.month.year/month` with a **local** normalized month.
- `lib/features/budgets/domain/usecases/budget_usecases.dart:97` —
  `normalizeBudgetMonth` returns `DateTime(date.year, date.month)`.

Conventions: pure date helpers live in `lib/core/utils/`; data models own
JSON mapping; repositories enqueue through `SyncQueue` (see
`lib/features/transactions/data/repositories/transaction_repository_impl.dart`).

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues |
| Tests | `flutter test --coverage` | all pass |
| Coverage | `dart run tool/check_coverage.dart` | passed |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |

## Scope

**In scope**
- `lib/core/utils/calendar_date.dart` (new)
- `lib/features/transactions/**` (use case, model, repository/tests)
- `lib/features/budgets/**` (model, data source, use case/tests)
- `lib/main.dart` (run migration before BLoCs)
- `lib/core/utils/app_constants.dart` (migration flag key)
- tests under `test/features/transactions`, `test/features/budgets`,
  `test/core/utils`
- `integration_test/support/harness.dart` only to run the migration

**Out of scope**
- Scheduled-payment dates (already local calendar dates).
- Debt `dueDate` (date-only field; verify but do not alter unless a test
  demonstrates the same bug).
- Postgres column types.

## Steps

### Step 1: Add a calendar-date helper

Create `lib/core/utils/calendar_date.dart`:

```dart
/// Calendar date stored as UTC noon so date parts are stable across zones.
DateTime calendarDate(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day, 12);

/// Calendar month stored as UTC noon on the first day.
DateTime calendarMonth(DateTime value) =>
    DateTime.utc(value.year, value.month, 1, 12);

/// True when the value already uses the UTC-noon convention (for tests).
bool isCalendarDate(DateTime value) =>
    value.isUtc && value.hour == 12 && value.minute == 0;
```

Do **not** call `.toLocal()` in display code; the UTC date parts are now the
canonical calendar day.

**Verify**: new unit tests in `test/core/utils/calendar_date_test.dart`
assert month/year/day preservation and the UTC flag.

### Step 2: Normalize new transactions

In `AddTransactionUseCase.call`, set
`date: calendarDate(params.date)` on the constructed entity. Update
`AddTransactionParams` docs to say the date is a calendar day.

`TransactionModel.toJson` keeps `.toUtc()` (already UTC) and `fromJson` keeps
`DateTime.parse`. No display change is needed because formatters already read
UTC parts.

**Verify**: update `test/features/transactions/domain/usecases/add_transaction_usecase_test.dart`
to pass a time-of-day date and assert `hour == 12`, `isUtc == true`, same
year/month/day; run it.

### Step 3: Normalize budgets

- `BudgetModel.toJson`: `'month': calendarMonth(month).toIso8601String()`.
- `fromJson`: after parse, `calendarMonth(parsed)` (normalizes legacy data on
  read).
- `HiveBudgetLocalDataSource.getBudgets`: compare `budget.month.year` and
  `budget.month.month` against the query's **local** `normalized.year/month`
  (as today); stored rows are UTC noon so parts match.
- `BudgetEntity.copyWith` / equality unchanged.

**Verify**: add a test in `test/features/budgets/data/models/budget_model_test.dart`
(or the existing model/data-source test) that round-trips a local
`DateTime(2026, 11)` and asserts year/month survive.

### Step 4: One-time migration for existing Hive rows

Create `lib/features/transactions/domain/usecases/migrate_calendar_dates_usecase.dart`
(or a core `core/services/calendar_migration.dart`) that:
1. Checks a Hive `settings` flag `calendar_migration_v1`; return `Right(null)`
   if set.
2. Reads all transactions (including soft-deleted) and budgets.
3. For each transaction: `final local = tx.date.toLocal();` then
   `date = calendarDate(local)`. If the value already equals the target, skip.
4. For each budget: `final local = budget.month.toLocal();` then
   `month = calendarMonth(local)`.
5. Persist through the existing repositories (`addTransaction` / `addBudget`)
   so updates get `updatedAt` and are enqueued for sync.
6. Set the flag only after all writes succeed.

Call it in `lib/main.dart` after `configureDependencies()` and the account-scope
check, **before** due-payment processing and BLoC creation.

**Verify**: unit test with a fake repo containing pre-plan dates; second run
performs no writes (flag idempotence).

### Step 5: Regression coverage

- Unit: a UTC-5-style evening input (`DateTime(2026, 10, 31, 20, 30)`) becomes
  `DateTime.utc(2026, 10, 31, 12)` and formats as `31/10/2026`.
- Integration: add a transaction dated today with a late timestamp via
  `harness.addTransaction`; assert the transaction list shows today's
  `formatDisplayDate(DateTime.now())` (not tomorrow).

## Test plan

Pattern: `test/features/transactions/data/repositories/transaction_repository_impl_test.dart`
for repository/migration tests; `test/features/budgets/data/repositories/budget_repository_impl_test.dart`
for budgets. Use temp Hive directories.

## Done criteria

- [ ] New transactions have `isUtc == true && hour == 12`.
- [ ] Budget round-trip preserves the calendar month.
- [ ] Migration flag exists in `settings` and is idempotent.
- [ ] `flutter analyze`, `flutter test --coverage`, coverage gate, and Linux
      integration all pass.
- [ ] `plans/README.md` updated.

## STOP conditions

- `date` is used as an instant (e.g. ordering by time-of-day) anywhere besides
  calendar display/grouping; report before normalizing.
- The migration would enqueue thousands of operations without a cap; report
  and propose batching.
- A user's legacy rows cannot be mapped without ambiguity.

## Maintenance notes

- New date-bearing entities must use `calendarDate`/`calendarMonth` and
  display UTC parts.
- If a future feature needs the exact time of day (e.g. audit log), store it in
  a separate field; do not overload `date`.
- Reviewer: check that range queries still include month boundaries in UTC-
  and UTC+ test environments.
