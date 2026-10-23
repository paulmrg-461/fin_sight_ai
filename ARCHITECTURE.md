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

- **Hive CE** boxes (`transactions`, `debts`, `receipts`) are opened once at startup by `StorageModule` and injected via `AppBoxes`.
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

### OCR

- Entity: `ReceiptEntity` with `imagePath`, `merchantName`, date, total, currency, and `ReceiptItem` lines.
- `MlKitOcrDataSource` (Google ML Kit, Android/iOS) returns raw text; `ReceiptParser` extracts fields with tolerant heuristics.
- `ReceiptRepositoryImpl` validates empty scans, maps OCR/storage errors, and persists receipts in Hive.
- `OcrBloc` scans, saves, and lists receipts. Saving a newly scanned receipt also creates an expense transaction with the receipt id (idempotent retries).
- `ReceiptImagePicker` abstracts camera/gallery; `OcrScreen` and `ReceiptPreviewScreen` handle editing, loading, empty, and error states.

### AI Coach

- `FinancialInsightEntity` types: suggestion, alert, analysis.
- `GroqApiDatasource` calls Groq chat completions with the key from `AppEnv`, a 15s timeout, and stable error codes.
- `PromptTemplates` define deterministic JSON contracts for insights, spending, savings, budget optimization, and debt payoff.
- `InsightParser` accepts JSON arrays/objects, code fences, or plain text (fallback analysis).
- `AiCoachBloc` builds context from real transactions, then calls the get-insights, analyze-spending, and savings use cases. Insights render as chat-like `InsightCard`s.

### Dashboard

- `DashboardRepositoryImpl` aggregates transactions into summary, category breakdown, and monthly comparison.
- `DashboardCalculator` owns savings rate, percentages, and month-over-month math.
- `DashboardBloc` supports `LoadDashboard`, `RefreshData`, and `ChangeDateRange`; the default period is the current month.
- `DashboardPage` combines summary cards, fl_chart pie/bar charts, recent activity, pull-to-refresh, a date-range picker, theme toggle, and quick actions.

## 5. Routing and Navigation

- `GoRouter` with named routes: `/dashboard`, `/transactions`, `/debts`, `/ocr`, `/ai-coach`.
- `AppRoutes` centralizes names and paths; `buildRouter()` is a pure function for testability.
- Feature screens are provided by `FinSightApp` through app-level `MultiBlocProvider`, so pushed routes inherit their blocs.
- The dashboard exposes quick actions that push feature routes and refresh analytics on return.
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
- `GroqApiDatasource` consumes `AppEnv.groqApiKey` through DI; a missing key fails with `groq_not_configured`.

## 8. Dependency Injection

- `get_it` is the service locator; `injectable` generates the graph into `injection.config.dart`.
- Composition root: `configureDependencies()` in `lib/core/di/injection.dart`.
- `StorageModule` pre-resolves Hive boxes; feature modules provide data sources; repositories and use cases are `@lazySingleton`; blocs are `@injectable` factories.
- `CoreModule` provides the shared `http.Client`, `Uuid`, `Clock`, and `AppEnv`.
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
| Integration | Full user flows, persistence, navigation, benchmarks | `integration_test`, real Hive, fake OCR/Groq/image picker |

Commands:

```bash
flutter analyze
flutter test --coverage
flutter test -d linux integration_test/app_flow_test.dart
```

Domain and data coverage target: ≥ 90%. Integration benchmarks print launch and render timings and assert upper bounds.

## 10. Key Decisions

| Decision | Rationale | Trade-off |
| --- | --- | --- |
| `fpdart` `Either` instead of throwing | Explicit failure paths, exhaustiveness | Slightly more verbose call sites |
| Hive CE for local storage | No native setup, fast, testable, works offline | JSON map schema requires explicit migrations |
| Local-first writes | Instant UI and offline resilience | Conflict resolution required in the sync slice |
| Sealed + `Equatable` BLoC states | Exhaustive UI rendering and testable transitions | More classes per feature |
| Manual entity equality | Keeps domain pure Dart | More boilerplate |
| Supabase over Firebase | Relational queries, RLS, predictable pricing | Team must own SQL and migrations |
| Google ML Kit for OCR | No bundled trained data, fast on-device text recognition | Android/iOS only; other platforms surface a handled failure |
| Groq over on-device LLM | Fast, cheap hosted inference with JSON prompts | Network dependency and API-key management |
| fl_chart for analytics | Lightweight, themeable Flutter charts | Limited advanced chart types |

## 11. Roadmap

1. Supabase sync with conflict resolution and retry/backoff.
2. Budgets and category management.
3. Receipt image storage and cleanup policies.
4. Streaming AI responses and conversation memory.
5. CI pipelines for unit, integration, and screenshot tests.
