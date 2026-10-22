# Task List — FinSight AI foundation + features

## Core infrastructure

- [x] `Entity` and sealed `Failure` hierarchy
- [x] GoRouter named routes (`/dashboard`, `/transactions`, `/debts`, `/ocr`, `/ai-coach`)
- [x] Emerald light/dark themes + `ThemeController`
- [x] `.env` + `flutter_dotenv` typed through `AppEnv`
- [x] get_it + injectable graph with Hive boxes
- [x] DI, routing, theme, env, and app-shell tests

## Transactions

- [x] `TransactionEntity` and repository contract
- [x] Add / Get / GetByDateRange / Delete use cases
- [x] `TransactionModel` + JSON round-trip
- [x] Hive data source + repository implementation
- [x] `TransactionBloc` + sealed states
- [x] Screen, form, list, date/category filters
- [x] Use case, model, data source, repository, and BLoC tests

## Debts

- [x] `DebtEntity`, `PaymentRecord`, `DebtPayoffCalculator`
- [x] Add / Get / MakePayment / Delete / CalculatePayoff use cases
- [x] `DebtModel` + JSON round-trip
- [x] Hive data source + repository implementation
- [x] `DebtBloc` + sealed states
- [x] List, add, and detail screens with progress and payment history
- [x] Calculator, use case, model, data source, repository, and BLoC tests

## Verification

- [x] `flutter analyze` — no issues
- [x] `flutter test --coverage` — 171 tests passing
- [x] Domain and data coverage ≥ 90%
- [x] Commit and push
