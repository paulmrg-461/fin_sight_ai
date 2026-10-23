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

- **Hive CE** boxes (`transactions`, `debts`, `receipts`, `budgets`, `wallets`, `wallet_transfers`, `categories`, `scheduled_payments`, `sync_queue`, `sync_meta`, `settings`) are opened once at startup by `StorageModule` and injected via `AppBoxes`.
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
- `ReceiptImagePicker` abstracts camera/gallery; `FileReceiptImageStore` copies picked images into `<documents>/receipts` so previews survive cache cleanup; failed scans delete the orphaned copy.

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

### Auth

- `AuthRepository` signs in/up with Supabase Auth (GoTrue REST), restores and refreshes sessions, and exposes the access token to sync.
- Sessions are persisted with `flutter_secure_storage` (Keychain/Keystore) through `SessionStorage`; tests inject a fake storage.
- `AuthBloc` + `LoginScreen` + dashboard `AccountButton` handle sign-in, sign-up, sign-out, and session restoration.
- RLS is verified against a real database with `supabase/tests/rls_test.sql` and `supabase/verify_rls.sh`.

### Sync

- Transactions, debts, and budgets stamp `updatedAt` / `isSynced`, persist locally, and enqueue a `SyncOperation` (`<entityType>:<entityId>`). Transaction `walletId` round-trips through PostgREST.
- Deletes write `deletedAt` tombstones and enqueue upserts; local queries hide tombstones while sync keeps them idempotent.
- `HiveSyncLocalDataSource` stores the queue and `lastSyncedAt` in Hive; repeated edits collapse into the latest operation.
- `SupabaseRestSyncDataSource` talks to PostgREST over `http.Client` with the authenticated JWT, mapping camelCase models to snake_case columns (including `deleted_at`).
- `SyncRepositoryImpl` pushes pending operations, resolves conflicts last-write-wins by `updatedAt`, pulls newer remote rows/tombstones (transactions, debts, budgets), persists `lastSyncedAt`, retries with exponential backoff, and purges tombstones older than 30 days.
- `SyncBloc` + `SyncStatusChip` expose pending count, offline/configured/authenticated state, and manual sync. Startup restores auth then syncs.
- Receipts remain local-only. Without credentials or a session, sync returns a non-fatal offline report.

### Money

- `WalletEntity` (bank/cash) + `WalletTransferEntity`; `WalletCalculator` derives balances from opening balances, transactions, and transfers.
- Default stable wallets (`wallet-bank`, `wallet-cash`) are created on first load.
- `WalletRepositoryImpl` reconciles actual balances by adjusting the opening balance and validates transfers against available funds.
- `WalletBloc` + `WalletScreen` expose total money, per-wallet balances, reconciliation, and account→cash transfers.
- Transaction `walletId` is persisted and synced (`0004_wallet_ids.sql`); wallet definitions/transfers are local-only for now.

### Currency

- `AppCurrency` supports COP (default, `es_CO`) and USD (`en_US`) with locale-aware `MoneyFormatter`.
- The preference is stored in the Hive `settings` box; `CurrencyBloc` exposes it app-wide.
- `MoneyText` renders every monetary surface with the active currency.
- `SettingsScreen` (`/settings`) switches currency; amounts are **not** converted.

### Categories

- `CategoryEntity` stores `id`, `name`, `isArchived`, and timestamps; transactions and budgets keep the category **name**, so history stays valid.
- Localized defaults are seeded once into the Hive `categories` box using the device language (`Platform.localeName`); archived rows prevent reseeding.
- `CategoryRepositoryImpl` validates non-empty/unique names and maps storage errors to `CacheFailure`.
- `CategoryBloc` + `/categories` support create, rename, archive, restore, and a “show archived” toggle. Pickers only show active categories.
- The transaction, scheduled-payment, and budget dialogs read the same catalog through `CategoryBloc`.

### Scheduled payments

- `ScheduledPaymentEntity` supports `monthly` and `yearly` frequencies, a preserved `dayOfMonth` (month-end clamping without drift), category, optional wallet, notes, and active state.
- `ScheduleCalculator` owns the date math (month lengths, leap years, catch-up).
- `ScheduledPaymentRepositoryImpl` persists schedules locally and materializes due periods through `TransactionRepository`, so wallet balances, budgets, dashboards, and sync treat them as ordinary expenses.
- Generated expenses use a deterministic UUID v5 per `(schedule, dueDate)`, making retries idempotent. Startup processing runs before the dashboard loads; the screen also processes on load and after adding a payment, showing an in-app banner with the created count.
- “Pay now” records today’s expense and advances the schedule; it is a no-op when the period was already paid today. Pausing stops automatic charges; deleting keeps already-recorded expenses.
- Schedules and category definitions are local-only in this slice; their generated transactions sync normally.

### Localization

- `lib/l10n/app_en.arb` and `app_es.arb` are the single source of user-facing copy; `flutter gen-l10n` produces `AppLocalizations`.
- `LocaleRepository` persists `system` / `en` / `es` in the Hive `settings` box; `LocaleBloc` loads and changes it app-wide.
- `FinSightApp` rebuilds `MaterialApp.router` with the selected locale and `appLocalizationsDelegates` (our ARB delegate plus the `material_ui`/`cupertino_ui` global delegates).
- Widgets read copy through `context.l10n`; no hardcoded UI strings remain in feature screens.
- Currency labels are localized; amounts keep their stored numeric value with no FX conversion.

### Budgets

- `BudgetEntity` holds a category limit for a month; `BudgetProgress` adds spending, percentage, remaining, and over-budget state.
- `BudgetRepositoryImpl` aggregates expenses from `TransactionRepository` for the month and derives categories from transactions plus budgets.
- `BudgetBloc` + `BudgetScreen` provide monthly progress cards, add/delete actions, and category suggestions.
- Budgets use the same queue/tombstone/LWW sync pipeline (`budgets` table in `0003_budgets.sql`).

## 5. Routing and Navigation

- `GoRouter` with named routes: `/dashboard`, `/transactions`, `/debts`, `/budgets`, `/money`, `/scheduled-payments`, `/categories`, `/settings`, `/ocr`, `/ai-coach`, `/login`.
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
- Supabase Auth uses `SUPABASE_URL` + `SUPABASE_ANON_KEY`; the session access token authorizes PostgREST requests.

## 8. Dependency Injection

- `get_it` is the service locator; `injectable` generates the graph into `injection.config.dart`.
- Composition root: `configureDependencies()` in `lib/core/di/injection.dart`.
- `StorageModule` pre-resolves Hive boxes; feature modules provide data sources; repositories and use cases are `@lazySingleton`; blocs are `@injectable` factories.
- `CoreModule` provides the shared `http.Client`, `Uuid`, `Clock`, and `AppEnv`.
- `SyncModule` binds the Hive sync queue to the `SyncQueue` port injected into the transactions and debts repositories.
- Auth data sources/storage/repository and budget data sources are annotated `@LazySingleton`; async Hive boxes are opened in `StorageModule`.
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
| Sync | Queue, PostgREST mapping, push/pull, conflicts, offline mode | `mocktail`, `http/testing.dart`, real Hive queue |
| Auth | GoTrue REST, secure storage, repository, BLoC | `mocktail`, `http/testing.dart` |
| Budgets | Aggregation, month filtering, BLoC | `mocktail`, real Hive |

Commands:

```bash
flutter analyze
flutter test --coverage
flutter test -d linux integration_test/app_flow_test.dart
```

Domain and data coverage target: ≥ 90%, enforced by `tool/check_coverage.dart`. Integration benchmarks print launch and render timings and assert upper bounds. CI (`.github/workflows/ci.yml`) runs format, analyze, the coverage gate, and Linux integration tests under Xvfb.

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
| PostgREST over `http.Client` | No heavy Supabase SDK, fully mockable HTTP layer | Manual row mapping and auth headers |
| Last-write-wins by `updatedAt` | Simple, deterministic conflict policy | Loses concurrent non-conflicting edits |
| Secure storage for sessions | Keychain/Keystore instead of plaintext | Linux needs libsecret; tests use a fake |
| Soft-delete tombstones | Deletions propagate across devices | Local tombstones require eventual cleanup |
| Synced budgets | Consistent offline-first behavior across slices | More rows/tables to migrate |
| Local wallets/transfers | Simple first money slice | Balances/transfers do not sync yet |
| App-wide currency setting | Consistent formatting, no FX complexity | No exchange-rate conversion |
| Persistent receipt images | Previews survive cache cleanup | Requires orphan cleanup/compaction |
| Exponential sync backoff | Avoids hammering a failing backend | Delayed retries after failures |

## 11. Roadmap

1. Run RLS verification against a real Supabase project (script ready).
2. Sync wallets and transfers.
3. Sync receipt metadata; streaming AI responses.
4. Money as integer minor units.
5. Screenshot/golden tests in CI.
