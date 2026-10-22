# Task List — transactions foundation slice

## Phase 1: Foundation

- [x] Core failures and exceptions (`test/core/error/failures_test.dart`)
- [x] `UseCase` contract and `NoParams`
- [x] `Transaction` entity and `TransactionRepository` contract

## Phase 2: Data

- [x] `TransactionModel` JSON mapping
- [x] `JsonFileTransactionLocalDataSource` persistence + corruption handling
- [x] `TransactionRepositoryImpl` offline-first fallback
- [x] `NoopTransactionRemoteDataSource`

## Phase 3: Use Cases and Wiring

- [x] `GetTransactionsUseCase`
- [x] `AddTransactionUseCase` validation
- [x] get_it + injectable composition root
- [x] App shell

## Verification

- [x] `flutter analyze`
- [x] `flutter test --coverage`
- [x] Domain/data coverage ≥ 90%
