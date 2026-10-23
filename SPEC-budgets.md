# Spec: budgets and categories

## Objective

Set monthly spending limits per category and track progress from real transactions, with categories derived from existing data.

## Entities

`BudgetEntity extends Entity`: `id`, `category`, `monthlyLimit`, `month` (normalized first day), optional `updatedAt`.

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
- `HiveBudgetLocalDataSource` stores budgets in the `budgets` box, filters by month, sorts categories.
- `BudgetRepositoryImpl` injects `TransactionRepository`:
  - Expenses for the month are grouped by category and compared with each budget.
  - Categories are the union of budget categories and transaction categories, sorted.

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
