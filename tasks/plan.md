# Implementation Plan: core infrastructure, transactions, debts

## Overview

Deliver the app foundation (DI, routing, theme, environment, domain primitives) and two complete feature slices with TDD coverage.

## Architecture Decisions

- Hive CE local storage behind feature data-source interfaces.
- Sealed + `Equatable` BLoC states for exhaustive UI rendering.
- `Result<T> = Either<Failure, T>` at every boundary.
- Named GoRouter routes; providers at app level so pushed routes inherit blocs.
- `AppEnv` prefers `--dart-define` over `.env` placeholders.

## Task List

### Phase 1: Core infrastructure

- [x] Base `Entity` and `Failure` in `lib/core/domain/`.
- [x] `AppRouter`, named routes, and placeholder pages.
- [x] Emerald light/dark themes and `ThemeController`.
- [x] `.env` + `flutter_dotenv` via `AppEnv`.
- [x] get_it + injectable graph with pre-resolved Hive boxes.

### Phase 2: Transactions

- [x] Entity, repository contract, and four use cases.
- [x] `TransactionModel`, Hive data source, repository implementation.
- [x] BLoC, screen, form, list, date/category filters.
- [x] Unit, data, and BLoC tests.

### Phase 3: Debts

- [x] Entity, payoff calculator, repository contract, five use cases.
- [x] `DebtModel`, Hive data source, repository implementation.
- [x] BLoC, list/add/detail screens, progress and history widgets.
- [x] Payoff, use case, data, and BLoC tests.

### Phase 4: Verification

- [x] `flutter analyze` clean.
- [x] `flutter test --coverage` green.
- [x] Domain/data coverage ≥ 90%.
- [x] Commit and push.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Hive box corruption | Medium | Strict JSON parsing → `CacheFailure` |
| Interest math edge cases | High | Pure calculator with dedicated tests |
| Pricey UI rebuilds | Low | Scoped `BlocBuilder`/`ListenableBuilder` |
| Secrets in `.env` | High | Empty placeholders committed; production uses dart-define |
