# Spec: budgets and categories

## Objective

Set monthly spending limits per category and track progress from real transactions, with categories derived from existing data.

## Entities

`BudgetEntity extends Entity`: `id`, `category`, `monthlyLimit`, `month` (normalized first day), `updatedAt`, `isSynced`, `deletedAt`.

`BudgetProgress`: `budget`, `spent`, derived `remaining`, `percentage` (`0..1`), `isOverBudget`.

## Repository

```dart
ResultFuture<BudgetEntity> addBudget(BudgetEntity budget);
ResultFuture<void> deleteBudget(String id);
ResultFuture<List<BudgetProgress>> getBudgetProgress(DateTime month);
ResultFuture<List<String>> getCategories();
```

## Use cases

- `AddBudgetUseCase`: trims category, requires a finite limit `> 0`, rounds to 2 decimals, normalizes the month, generates a UUID.
- `DeleteBudgetUseCase`: rejects blank ids.
- `GetBudgetProgressUseCase`: normalizes the month and aggregates.
- `GetCategoriesUseCase`: merges transaction and budget categories.

## Data

- `BudgetModel` JSON round-trip.
- `HiveBudgetLocalDataSource` stores budgets in the `budgets` box, filters by month/tombstones, sorts categories, and purges old tombstones.
- `BudgetRepositoryImpl` injects `TransactionRepository` and the `SyncQueue`:
  - Expenses for the month are grouped by category and compared with each budget.
  - Categories are the union of budget categories and transaction categories, sorted.
  - Adds/updates enqueue an upsert; deletes write a tombstone and enqueue an upsert.
- Budgets are synced through PostgREST (`budgets` table, `0003_budgets.sql`) with the same last-write-wins policy as transactions/debts.

## Presentation

- `BudgetBloc`: `LoadBudgets`, `AddBudget`, `DeleteBudget`; states initial/loading/loaded/empty/failure.
- `BudgetScreen`: monthly progress cards, over-budget highlighting, add dialog with category suggestions and limit, delete action.
- Route `/budgets`, plus a dashboard quick action.

## Tests

Entity/progress math, JSON mapping, Hive month filtering and corruption, repository aggregation and failure propagation, use-case validation, and BLoC transitions.

## Verification

```bash
flutter analyze
flutter test --coverage
flutter test -d linux integration_test/app_flow_test.dart
```

## Month navigation

`/budgets` selects one month at a time (current month by default). Previous/next controls dispatch `ChangeBudgetMonth`, which normalizes the month and reloads only that month. `AddBudget` targets the selected month; editing preserves the budget's stored month. `BudgetLoaded` and `BudgetEmpty` expose `month` so the selector stays in sync. An empty month reads the previous month and exposes `previousBudgetCount`; **Copy previous month** recreates those limits for the selected month with new ids through the normal add path.
