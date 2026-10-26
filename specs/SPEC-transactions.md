# Spec: transactions

## Objective

Let users record income and expenses, browse them offline, filter by date and category, and delete mistakes. All data lives locally first (Hive CE) and is available without connectivity.

**Success criteria**

- Users can add income/expense transactions with amount, category, description, date, and optional receipt path.
- Invalid amounts, missing categories, and overlong descriptions are rejected with `ValidationFailure`.
- The list is newest first, filterable by an inclusive date range, by category, and by free text (description, category, or formatted amount).
- The visible rows can be copied as CSV (`date,type,category,description,amount,wallet`), with RFC-4180 escaping; filters define what gets exported. Text search filters the cached period in memory and composes with the other filters.
- Deletions are persisted immediately.
- Every behavior is covered by unit, data, and BLoC tests.

## Entity

`TransactionEntity extends Entity`

| Field | Type | Rules |
| --- | --- | --- |
| `id` | `String` | UUID v4 |
| `amount` | `double` | Finite, `> 0`, 2 decimals |
| `type` | `TransactionType` | `income` or `expense` |
| `category` | `String` | Trimmed, non-empty |
| `description` | `String` | Trimmed, ≤ 500 characters |
| `date` | `DateTime` | Inclusive range filter |
| `receiptImagePath` | `String?` | Trimmed; empty becomes `null` |

## Repository

```dart
ResultFuture<TransactionEntity> addTransaction(TransactionEntity transaction);
ResultFuture<List<TransactionEntity>> getTransactions();
ResultFuture<void> deleteTransaction(String id);
ResultFuture<List<TransactionEntity>> getTransactionsByDateRange({
  required DateTime start,
  required DateTime end,
});
```

## Use cases

- `AddTransactionUseCase` — validates and normalizes input.
- `GetTransactionsUseCase` — returns all, newest first.
- `GetTransactionsByDateRangeUseCase` — validates `start <= end`.
- `DeleteTransactionUseCase` — rejects blank ids.

## Data

- `TransactionModel extends TransactionEntity` with `fromJson` / `toJson`.
- `HiveTransactionLocalDataSource` writes JSON maps keyed by id and sorts newest first.
- `TransactionRepositoryImpl` maps `CacheException` to `CacheFailure`.

## Presentation

`TransactionBloc` events: `LoadTransactions`, `AddTransaction`, `DeleteTransaction`, `FilterByDateRange`.

States: `TransactionInitial`, `TransactionLoading`, `TransactionLoaded`, `TransactionEmpty`, `TransactionFailure`.

Screens/widgets: `TransactionScreen` (form bottom sheet, date range picker, text search, CSV copy, retry/empty states) and `TransactionList` (category filter, edit/delete actions).

## Verification

```bash
flutter analyze
flutter test --coverage
```
