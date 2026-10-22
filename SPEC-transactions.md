# Spec: transactions (foundation slice)

## Objective

Establish FinSight AI's core architecture and deliver the first vertical domain/data slice: recording and listing financial transactions locally, with an explicit failure model, dependency injection, and a TDD-backed test suite.

**Success criteria**

- Clean Architecture folders exist under `lib/core/` and `lib/features/transactions/`.
- Domain is pure Dart (no Flutter, get_it, or I/O imports).
- All repository and use-case methods return `Result<T>` (`Either<Failure, T>`).
- Transactions persist across app restarts and are readable/sorted newest first.
- Invalid transactions are rejected with a `ValidationFailure`.
- Remote sync failures never lose locally stored data.
- `flutter analyze` is clean and `flutter test --coverage` is green.

## Tech Stack

- Flutter 3.50 beta / Dart 3.14
- `fpdart` (Either), `get_it` + `injectable` (DI), `path_provider` (storage path)
- `mocktail`, `flutter_test` (tests), `build_runner`/`injectable_generator` (DI codegen)

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --coverage
```

## Project Structure

```text
lib/core/{di,error,usecase}                 # cross-cutting primitives
lib/features/transactions/domain/{entities,repositories,usecases}
lib/features/transactions/data/{models,datasources,repositories}
lib/app                                     # app shell (no feature logic)
test/core, test/features/transactions       # mirrors lib/
```

## Code Style

```dart
@override
Future<Result<Transaction>> call(AddTransactionParams params) async {
  if (!params.amount.isFinite || params.amount <= 0) {
    return Left(const ValidationFailure(
      'Amount must be greater than zero.',
      code: 'invalid_amount',
    ));
  }
  return _repository.addTransaction(/* mapped entity */);
}
```

Conventions: `snake_case.dart`, `PascalCase` types, `camelCase` members, explicit return types, named arguments for multi-field constructors, no `print`.

## Testing Strategy

- Unit tests for entities, use-case validation/failure propagation, and mappers.
- Repository tests with mocked data sources cover success, cache failure, and offline fallback.
- Data-source tests use a real temp file to prove persistence and corruption handling.
- Target ≥ 90% coverage for domain and data.

## Boundaries

- **Always:** write tests first, keep domain pure, map exceptions to failures, run analyze + tests.
- **Ask first:** schema changes, new dependencies, swapping the local store, Supabase configuration.
- **Never:** commit secrets, silently swallow failures, delete failing tests, put I/O in domain.

## Acceptance Scenarios

1. `AddTransactionUseCase` rejects zero, negative, and non-finite amounts.
2. `AddTransactionUseCase` trims category/note, rounds the amount, and generates a UUID.
3. `GetTransactionsUseCase` returns transactions sorted newest first.
4. JSON persistence survives a new data-source instance.
5. A corrupt store returns `CacheFailure` instead of crashing.
6. Remote upload failure keeps the transaction locally with `isSynced = false`.

## Open Questions

- Should amounts use integer minor units instead of `double`? (deferred; documented trade-off)
- Which sync conflict policy for multi-device edits? (planned: last-write-wins on `updatedAt`)
