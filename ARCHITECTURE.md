# Architectural Blueprint — FinSight AI

## 1. System Overview

FinSight AI is an offline-first personal finance app built with Flutter. Local storage is the single source of truth for the UI; Supabase (PostgreSQL + RLS) is the remote system of record and sync target.

```text
┌─────────────────────────────┐
│ Presentation (BLoC/Cubit)   │
└──────────────┬──────────────┘
               │ events / states
┌──────────────▼──────────────┐
│ Domain (entities, use cases,│
│ repository contracts)       │
└──────────────▲──────────────┘
               │ Result<T>
┌──────────────┴──────────────┐
│ Data (models, data sources, │
│ repository implementations) │
└───────┬─────────────┬───────┘
        │             │
┌───────▼──────┐ ┌────▼──────────────────┐
│ Hive CE      │ │ Supabase (planned)    │
│ (truth)      │ │ REST / RLS            │
└──────────────┘ └───────────────────────┘
```

### Dependency rule

`presentation → domain ← data`. The domain layer imports neither Flutter nor infrastructure packages. `data` implements interfaces declared by `domain`; `presentation` depends on use cases only.

## 2. Layer Contracts

| Layer | Owns | Must not |
| --- | --- | --- |
| `core` | Base `Entity`/`Failure`, exceptions, `UseCase`/`Result`, DI, routing, theme, utils, storage containers | Contain feature business rules |
| `domain` | Entities, repository interfaces, use cases, pure calculators | Import Flutter, get_it, databases, HTTP |
| `data` | DTOs/mappers, Hive data sources, repository implementations | Expose DTOs to presentation |
| `presentation` | Blocs, screens, widgets | Call data sources or repositories directly |

Error handling is explicit: repositories and use cases return `Either<Failure, T>` (`Result<T>`). Exceptions are caught at the data-layer boundary and mapped to `ServerFailure`, `CacheFailure`, or `ValidationFailure`.

## 3. Offline-First Storage

- **Hive CE** boxes (`transactions`, `debts`) are opened once at startup by `StorageModule` and injected via `AppBoxes`.
- Each feature owns a local data source interface with a Hive implementation; the repository depends on the interface.
- Records are stored as JSON maps keyed by entity id. This keeps boxes schema-agnostic and migrations explicit.
- Local writes happen before any network call. Remote sync is a later slice; a remote failure must never roll back a local write.
- Invalid or corrupted entries surface as `CacheFailure` / `CacheException` instead of silently disappearing.

## 4. Feature Slices

### Transactions

- Entity: `id`, `amount`, `type` (`income`/`expense`), `category`, `description`, `date`, `receiptImagePath`.
- Use cases: `AddTransactionUseCase`, `GetTransactionsUseCase`, `GetTransactionsByDateRangeUseCase`, `DeleteTransactionUseCase`.
- Repository: `addTransaction`, `getTransactions`, `deleteTransaction`, `getTransactionsByDateRange`.
- Validation: finite amount `> 0`, trimmed non-empty category, description ≤ 500 characters, UUID v4 ids, amount rounded to 2 decimals.
- Presentation: `TransactionBloc` with `LoadTransactions`, `AddTransaction`, `DeleteTransaction`, `FilterByDateRange`. Sealed states: initial, loading, loaded, empty, failure. `TransactionScreen` hosts the add form (bottom sheet), date filter, and `TransactionList` with category chips.

### Debts

- Entity: `id`, `creditorName`, `totalAmount`, `remainingAmount`, `interestRate`, `minimumPayment`, `dueDate`, `status`, `paymentHistory`.
- Use cases: `AddDebtUseCase`, `GetDebtsUseCase`, `MakePaymentUseCase`, `DeleteDebtUseCase`, `CalculatePayoffUseCase`.
- Pure calculator: `DebtPayoffCalculator` compounds monthly interest and returns `null` when the payment cannot cover interest.
- Payments clamp to the remaining balance, mark the debt paid at zero, and append a `PaymentRecord`.
- Presentation: `DebtBloc` with `LoadDebts`, `AddDebt`, `MakePayment`, `DeleteDebt`, `CalculatePayoff`. Screens: list with progress bars, add form, detail with payment history and payoff projection.

## 5. Routing and Navigation

- `GoRouter` with named routes: `/dashboard`, `/transactions`, `/debts`, `/ocr`, `/ai-coach`.
- `AppRoutes` centralizes names and paths; `buildRouter()` is a pure function for testability.
- Feature screens are provided by `FinSightApp` through app-level `MultiBlocProvider`, so pushed routes inherit their blocs.
- `DebtDetailScreen` and `AddDebtScreen` are pushed with `MaterialPageRoute` and share the debt bloc instance.

## 6. Theme System

- Design tokens in `AppColors`: emerald `#10B981`, dark canvas `#0F172A`, light canvas `#F8FAFC`.
- `AppTheme.light` / `AppTheme.dark` build Material 3 schemes from the emerald seed.
- `ThemeController extends ChangeNotifier` owns `ThemeMode`; the app shell listens and swaps `themeMode`.
- The dashboard exposes an accessible light/dark toggle.

## 7. Configuration and Secrets

- `flutter_dotenv` loads `.env` (asset) at startup. The committed `.env` contains empty placeholders only.
- `AppEnv` prefers `--dart-define` values and falls back to `.env`; missing configuration degrades to empty strings.
- Production credentials are injected with `--dart-define=SUPABASE_URL=...` and never committed.
- Future Groq/Supabase clients consume `AppEnv` through DI.

## 8. Dependency Injection

- `get_it` is the service locator; `injectable` generates the graph into `injection.config.dart`.
- Composition root: `configureDependencies()` in `lib/core/di/injection.dart`.
- `StorageModule` pre-resolves Hive boxes; repositories and use cases are `@lazySingleton`; blocs are `@injectable` factories.
- Tests resolve the graph with a fake `PathProviderPlatform` and a temporary Hive directory.

Regenerate after changing annotations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 9. Testing Strategy

| Level | Scope | Tooling |
| --- | --- | --- |
| Unit | Entities, validation, calculators, mappers, use cases | `flutter_test`, `mocktail` |
| Data integration | Hive data sources against a temp directory | `flutter_test`, `hive_ce` |
| State | BLoC transitions and emitted states | `bloc_test`, `mocktail` |
| Widget | App shell, navigation, theme switching | `flutter_test` |
| DI | Full graph resolution | `get_it`, fake path provider |

Commands:

```bash
flutter analyze
flutter test --coverage
```

Domain and data coverage target: ≥ 90%.

## 10. Key Decisions

| Decision | Rationale | Trade-off |
| --- | --- | --- |
| `fpdart` `Either` instead of throwing | Explicit failure paths, exhaustiveness | Slightly more verbose call sites |
| Hive CE for local storage | No native setup, fast, testable, works offline | JSON map schema requires explicit migrations |
| Local-first writes | Instant UI and offline resilience | Conflict resolution required in the sync slice |
| Sealed + `Equatable` BLoC states | Exhaustive UI rendering and testable transitions | More classes per feature |
| Manual entity equality | Keeps domain pure Dart | More boilerplate |
| Supabase over Firebase | Relational queries, RLS, predictable pricing | Team must own SQL and migrations |

## 11. Roadmap

1. Supabase sync with conflict resolution and retry/backoff.
2. Budgets, categories, and dashboard aggregates.
3. Receipt OCR ingestion into transactions.
4. Groq-powered insights with deterministic JSON contracts.
5. Receipt image picking and local file management.
