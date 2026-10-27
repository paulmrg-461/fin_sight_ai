# Project Memory — FinSight AI

_Last updated: 2026-10-26. Read this before starting a new session._

## Delivered and pushed

| Area | Status |
| --- | --- |
| Core infrastructure (DI, routing, theme, env, domain base) | Done |
| Transactions slice | Done |
| Debts slice | Done |
| Receivables / money lent (edit + sync) | Done |
| OCR slice (ML Kit + parser + preview + auto expense) | Done |
| AI Coach slice (Groq + prompts + insights) | Done |
| Dashboard analytics (fl_chart + aggregation) | Done |
| Money wallets (bank/cash, reconciliation, transfers) | Done |
| Currency preference (COP/USD) | Done |
| Localization (English/Spanish, persisted selector) | Done |
| Category catalog (defaults, create, rename, archive) | Done |
| Scheduled payments (create/edit, projection, reminders) | Done |
| Budget month navigation + copy previous | Done |
| Transaction search, CSV copy, duplicate | Done |
| Definitions sync (categories, schedules, wallets, transfers) | Done |
| AI Coach language + offline cache | Done |
| Localized failures + AI output language | Done |
| Platform scaffolds tracked (Android/iOS/Linux/macOS/Windows/web) | Done |
| Integration suite (30 flows + benchmarks) | Done |

### Current checkpoint (2026-10-26)

- HEAD: `fab8193` on `develop` and `main` (in sync, pushed).
- Gates: `flutter analyze` clean, **968** unit/widget tests, coverage gate green, **30** Linux integration tests.
- Benchmarks: launch/dashboard ~224 ms, transactions render ~183 ms with 300 seeded transactions.
- Integration command: `flutter test -d linux integration_test/app_flow_test.dart`.
- Branch policy: work on `develop`, commit + push every feature, fast-forward into `main` and push.
- Recent commits (newest first): `fab8193` local reminders, `7b7d168` platform scaffolds, `d070227` duplicate transaction, `dc565ee` dashboard committed card, `6fff33b` AI insight cache, `0e355ea` AI language, `53e3fd4` localized failures, `7e4e609` copy previous budgets, `c79884d` budget months, `5e3e73b` CSV copy, `e65ec1b` transaction search, `89b181e` schedule editing.

## Debt payment plan + dashboard overview (plan 023)

- `DebtPaymentPlan`/`DebtInstallment` (pure domain) plus `DebtPayoffCalculator.buildPaymentPlan` compute monthly payment, interest, principal, remaining, total interest, and total paid; the final payment is shortened and non-amortizing payments return `null`.
- `calculatePayoffDate` now derives from the plan, so the payoff date and schedule cannot diverge.
- `PayoffEstimate.plan` drives a **Payment plan** card in debt details with every installment; an empty monthly-payment field falls back to the debt minimum.
- The dashboard has a **Current debts** card (active count, total remaining, next due creditor/date/minimum, opens `/debts`) fed by `DebtBloc` and hidden when no active debt remains.
- Tests: plan math, model equality, bloc plan attachment, dashboard widget, and the debt-detail integration flow.

## Duplicate transaction (plan 022)

- The edit form exposes **Save as copy**: it dispatches `AddTransaction` with the current fields, today's date, and no id.
- The original row and receipt path are untouched; the copy gets a fresh id and a normal sync upsert.
- Integration covers the copy path and asserts distinct ids with equal amounts.

## Dashboard committed card (plan 021)

- `DashboardBloc` calls `GetCommittedCashflowUseCase` for the next 30 days and exposes `DashboardLoaded.committed30`; projection failures hide the card.
- `Committed30DaysCard` shows the total and next three commitments, and opens `/scheduled` on tap; it only renders when payments exist.
- `MainShell` refreshes the dashboard when its bottom-navigation tab is selected, so schedules/debts added in other branches appear immediately without extra startup reads.
- Tests: BLoC projection, widget preview/tap, and an integration flow where a debt minimum appears on the dashboard.

## AI insight cache (plan 020)

- `ai_insights` is a user-owned Hive box (cleared by `LocalDataScope` on sign-out) storing the last insights per language.
- `InsightCache`/`HiveInsightCache` parse defensively; corrupt entries are skipped and cache errors never reach the UI.
- `AiCoachBloc` writes on successful load/analyze/suggest; a failed load falls back to the cache with `AiCoachLoaded.fromCache`, and failed analyses keep the insights already on screen.
- The screen shows a “Showing saved insights. Reconnect to refresh.” banner in that state.
- Tests cover per-language storage, corrupt data, offline fallback, write-on-success, and sign-out clearing.

## AI Coach language (plan 019)

- `LoadInsights`, `AnalyzeSpending`, and `GetSuggestions` carry a `languageCode`; the AI Coach screen passes `Localizations.localeOf(context).languageCode`.
- `AiCoachBloc` appends “Write the response in Spanish/English.” to the context, including the empty-ledger context.
- Prompts and the repository stay language-agnostic; tests assert the Spanish instruction reaches the use case and English remains the default.
- Insights are regenerated per tap, so cached-language handling is not needed yet.

## Localized failures (plan 018)

- `FailureText.failureText` (extension on `BuildContext`) maps the domain's stable English messages to ARB strings; exact mappings plus prefix families (`Unable to read/save/delete/update/…`, `Could not …`) and an English fallback.
- Every failure-rendering screen uses the helper: transactions, debts, receivables, budgets, wallets, schedules, categories, dashboard, OCR, AI coach, sync, and login.
- The mapping is message-based to avoid threading failure codes through every state; migrating states to carry `Failure.code` remains a future refactor.
- Known gap: AI-generated insight content still arrives from the model in English.

## Copy previous budgets (plan 017)

- Empty months read the previous month and expose `previousBudgetCount`; the UI only offers **Copy previous month** when that count is positive.
- `CopyPreviousBudgets` recreates each previous limit for the selected month through `AddBudgetUseCase` (new ids), then reloads; the source month is untouched.
- Tests: BLoC captures one add per limit with the selected month; integration creates a previous-month budget, moves forward, copies it, and verifies the limit.

## Budget month navigation (plan 016)

- `BudgetBloc` keeps `_selectedMonth` (current month by default); `ChangeBudgetMonth` normalizes it and reloads only that month.
- `AddBudget` targets the selected month, while edits preserve each budget's stored month.
- `BudgetLoaded`/`BudgetEmpty` expose `month`; `/budgets` renders a localized previous/next selector above the hero or empty state.
- Tests: BLoC verifies the requested month is queried; integration creates a budget, visits the previous month, and returns.

## CSV export (plan 015)

- `TransactionCsv.build` emits a stable header (`date,type,category,description,amount,wallet`), ISO dates, raw positive amounts, English type tokens, and RFC-4180 escaping.
- The transactions app bar copies the **visible** rows (date range, category chips, and search apply) to the clipboard and shows a pluralized confirmation.
- It uses Flutter's clipboard only: no platform plugin, and the integration test verifies both the snackbar and the clipboard text.

## Transaction search (plan 014)

- `SearchTransactions` filters the active period in memory: the bloc caches `_periodTransactions` after each load, so typing does not hit Hive.
- Matches description, category, or formatted amount, case-insensitively; composes with the date-range filter and is preserved across add/edit/delete reloads.
- `LoadTransactions` clears both the date range and the query; `TransactionEmpty` carries the query so the UI shows “No matching transactions” with a clear-search action.
- `TransactionScreen` owns the controller, shows the search field for loaded/empty states, and restores the active query when returning to the screen.
- Tests: clearing restores the cache with a single read; integration covers search, no-match, and clear.

## Schedule editing (plan 013)

- `ScheduledPaymentRepository.updatePayment` merges editable fields into the stored row, preserving `id`, `createdAt`, and `lastPaidAt`; it stamps `updatedAt`, clears `isSynced`, and enqueues exactly one upsert.
- `UpdateScheduledPaymentUseCase` mirrors add validation and normalizes the due date; `UpdateScheduledPayment` reloads without reprocessing due periods.
- `ScheduledPaymentForm(initial:)` prefills the form and switches the title/button to “Edit scheduled payment” / “Save changes”; the card popup menu exposes Edit alongside pause/resume and delete.
- Tests: repository audit-date and queue assertions, use-case validation, BLoC success/failure, and an integration edit flow that keeps the same id.

## Local reminders (plan 009 Phase B)

- `flutter_local_notifications` + `timezone`; `ReminderScheduler` interface and `LocalReminderScheduler` implementation registered through `ReminderModule`.
- Reminder at 09:00 local on the next due date; no reminder for due-today/overdue payments because in-app processing owns them.
- Stable FNV-1a notification id per payment; `scheduleFor` replaces, inactive schedules cancel, delete cancels by id, an empty list cancels all.
- `ScheduledPaymentBloc` reschedules all stored payments after every reload (covers due-processing date changes), so add/pause/update/delete/pay stay aligned.
- Android: `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED`, plugin boot/scheduled receivers, `inexactAllowWhileIdle` (no exact-alarm approval). iOS: `UNUserNotificationCenter` delegate + runtime alert/badge/sound permission.
- Desktop/web/tests are no-ops; the integration harness uses the real scheduler, which no-ops on Linux.
- Platform scaffolds (Android/iOS/desktop/web) are tracked after commit `7b7d168`, so these files are versioned.

## Committed cashflow (plan 009 Phase A)

- `GetCommittedCashflowUseCase` projects the next 30/90 days from active expense schedules and active debt minimums; income and paused schedules are excluded, overdue sources advance into the window, and results are date-sorted.
- The projection is read-only; due processing remains the only writer. Debt minimums recur monthly on the debt due day.
- `ScheduledPaymentBloc` computes both windows on every reload (projection failures hide the card) and exposes them on `ScheduledPaymentLoaded`/`ScheduledPaymentEmpty`.
- `CommittedCashflowCard` on `/scheduled` shows the total, the next three payments, and a 30/90-day toggle; it hides when both windows are unavailable.
- Phase B (local due-date notifications) was previously blocked because `android/` and `ios/` were hidden by a machine-level excludes file. The platform scaffolds are now tracked in git, so Phase B can proceed (plugin + permissions still required).

## Definitions sync (plan 007)

- Synced entities now include `category`, `scheduledPayment`, `wallet`, and `walletTransfer`; `SyncEntityType` lists definitions before ledger entities and the pull order is categories → schedules → wallets → transfers → transactions → debts → budgets → receivables.
- `CategoryEntity`, `ScheduledPaymentEntity`, `WalletEntity`, and `WalletTransferEntity` carry `isSynced`, `deletedAt`, and `lastModified`; models round-trip the new fields and default legacy rows to visible/unsynced.
- Repositories enqueue upserts on every write: category add/rename/archive, schedule add/pause/resume/pay/rename plus tombstones on delete, wallet reconciliation/default creation, and transfer creation. Queue failures never fail the local write.
- Hive data sources split visible reads from `getAll*` (including tombstones) and purge tombstones older than 30 days.
- Remote mapping uses `categories`, `scheduled_payments` (incl. `type`, `next_due_date`, `is_active`, `last_paid_at`), `wallets`, and `wallet_transfers`; LWW and tombstones match the existing pipeline.
- Migration: `supabase/migrations/0006_definitions_sync.sql` (0005 was already receivables), added to `apply_all.sh`/`.sql`, with RLS coverage for the four tables. `supabase/validate_local.sh` applies all six migrations plus the RLS suite to a throwaway Postgres 16 container (Docker) and runs in CI. The user applied `0006` (and the earlier migrations) to the live project on 2026-10-26; capture the RLS script output on the next connection.
- `category_id` is reserved on `transactions`/`budgets` but remains unpopulated; category names stay canonical. Category defaults are device-local until first edit, so a second device may keep its own default names until a category is mutated or pulled.
- Tests: model/data-source/repository enqueue tests, PostgREST mapping for all four entities, sync push/pull/LWW/tombstone/order tests.

## Dashboard performance (plan 010)

- `DashboardRepository.getDashboardData` performs exactly two range reads (current and previous month) and derives summary, breakdown, comparison, and recent activity (top 5) from those lists.
- `DashboardData` is the single bundle consumed by `DashboardBloc`; the separate summary/breakdown/comparison use cases and repository methods were removed.
- Seeded benchmark (300 transactions, 3 months): dashboard launch 199 ms and transactions render 180 ms inside the full suite; the benchmark run alone in a fresh process measures 1018–1128 ms launch and ~294–305 ms render, which points at cold-start warmup.
- Startup is now split: `main.dart` blocks only on the dashboard plus currency/locale/auth, then `StartupLoader` runs due-schedule processing, feature blocs, and sync after the first frame. Seeded benchmark: 227–233 ms in the full suite; a cold single-test process still logs ~1092 ms from debug-mode first-use warmup.
- Tests assert the two-read contract, previous-month values, empty periods, list content equality, and failure propagation.

## Editing, confirmation, and undo (plan 008)

- Transactions and budgets update in place with the same id, an `updatedAt` stamp, and one queued upsert; `UpdateTransactionUseCase` / `UpdateBudgetUseCase` validate input at the domain boundary.
- `TransactionForm(initial:)` prefills every field and dispatches `UpdateTransaction`; transaction rows expose an edit button next to delete.
- Budget cards open a prefilled dialog (`New budget` vs `Edit budget`) backed by `UpdateBudget`.
- Deletes require an `AlertDialog`; deleting a transaction shows a SnackBar with `Undo`, which re-adds the same entity id (clearing the tombstone) through `AddTransaction(id:)`.
- `CategoryDropdown` keeps a stale category (renamed or archived) selectable, so existing transactions can still be saved.
- Coverage: repository/usecase/BLoC/widget tests plus integration flows for edit, delete confirmation, undo, and budget edit/delete.

## Receivables (Me deben)

- Domain/data: `ReceivableEntity`, `ReceivablePayment`, `ReceivableStatus`; Hive `receivables` box behind `ReceivableLocalDataSource`; repository enqueues sync upserts/tombstones through `SyncQueue`.
- Payments are validated in `MakeReceivablePaymentUseCase`, clamped to the remaining balance in `ReceivableRepositoryImpl`, and a full payment flips the record to `paid`.
- Presentation: `/receivables` list with gradient hero, debtor cards, add form, detail screen, and payment dialog; empty/error use the shared `AppEmptyState`/`AppErrorState`.
- Entry points: drawer “Me deben” under More, dashboard quick action `quick-action-receivables`, and a compact dashboard summary card driven by `ReceivableBloc`.
- Localization: EN/ES keys added and localizations regenerated. `LocalDataScope` clears the `receivables` box with the other user-owned boxes on sign-out.
- Tests: entity/model/data source/repository/use-case/BLoC/widget coverage plus the integration flow (add 1000 → pay 400 → dashboard 600 → restart persistence).
- In-place editing: debtor, dates, notes and (before any payment) the amount; the amount locks once payments exist.
- Sync resilience: failed operations are requeued without blocking later ops or pulls, invalid payloads are discarded, pulls page at 500 rows up to 100 pages, and the watermark advances only to the newest received `updatedAt`.
- Sync: `receivables` table (`0005_receivables.sql`), queue upserts/tombstones, PostgREST mapping, pull/merge, and tombstone purge. Apply the migration to the live project before relying on remote sync.

## Categories and scheduled payments

- Categories: Hive `categories` box, seeded once with EN/ES defaults from `Platform.localeName`; transactions/budgets store names, not ids.
- `/categories` supports create, rename, archive/restore, and show-archived; pickers read `CategoryBloc`.
- Scheduled payments: Hive `scheduled_payments` box; monthly/yearly with preserved `dayOfMonth` and month-end clamping.
- Due processing runs at startup (before dashboard blocs) and on screen load; generated expenses use deterministic UUID v5 per schedule+due date, then sync normally.
- Banner counts are carried into `LoadScheduledPayments(previousAutoCreated: ...)` so startup-created expenses are announced.
- “Pay now” is idempotent per day; paused schedules never auto-charge; deleting keeps recorded expenses.
- Category renames now cascade by name to transactions, budgets, and schedules; canonical category ids remain a future step for syncing definitions.
- Bug fixed in this slice: `AddTransactionUseCase` now forwards `walletId`, so new expenses affect wallet balances.

## i18n slice (English / Spanish)

- ARBs: `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`; generation via `l10n.yaml` + `flutter gen-l10n`.
- `LocaleRepository` (Hive `settings` box) stores `system` / `en` / `es`; `LocaleBloc` drives `MaterialApp.router`.
- `context.l10n` is the only way screens read copy; currency labels are localized, amounts are not converted.
- `appLocalizationsDelegates` combines the ARB delegate with `material_ui`/`cupertino_ui` global delegates (Flutter 3.50+ requirement).
- Settings exposes System/English/Español; integration test switches EN → ES → EN.
- Widget tests must provide both `CurrencyBloc` and `LocaleBloc`; `MaterialApp` needs `appLocalizationsDelegates` or Spanish falls back with "No MaterialLocalizations found".
- Locale state changes complete asynchronously; in widget tests wait on `localeBloc.stream` with `tester.runAsync` instead of relying only on `pumpAndSettle`.
- Known gap: domain `Failure` messages and AI-generated insights are still English-only.

## UI/UX polish (branch `develop`)

- Centralized Material 3 theme: emerald/teal/sky palette, navy canvas, custom
  typography, 20 px cards, 16 px inputs, 14–16 px buttons, 74 px navigation bar,
  rounded dialogs/sheets, and fade page transitions.
- New reusable widgets: `AppContent`, `BrandGradientCard`, `AppSectionHeader`,
  `AppEmptyState`, `AppErrorState`.
- Redesigned dashboard (balance hero, period pill, action tiles, donut total),
  login (brand gradient + card), money (hero + account bars), scheduled
  (expected-income hero), settings (grouped cards + brand footer), and drawer
  header.
- Transactions now use responsive content, card spacing, a date-filter pill, and
  shared empty/error states. Budgets and debts gained gradient summary heroes,
  responsive lists, and consistent card rhythm; receivables shipped with the
  same system.
- Navigation tab label is the short “Scheduled”/“Pagos”; drawer keeps the long
  label. Haptic selection on bottom tabs.
- Tests updated for action tiles (`quick-action-<route>`) and text duplicates
  introduced by responsive hero cards.

## Branding

- Source artwork: `assets/branding/logo_mark.svg` (rounded mark),
  `logo_icon_square.svg` (opaque app icon), `logo_foreground.svg` (Android
  adaptive foreground).
- In-app mark: `AppLogo` (`lib/app/branding/app_logo.dart`) in the dashboard
  app bar, drawer header, and login screen.
- Platform icons/splash generated in Android (legacy + adaptive + launch),
  iOS, macOS, Windows, and web. Linux platform files are ignored by the
  environment's global excludes.

## Local environment (never commit)

- `.env` is gitignored, local-only, and never bundled as an asset; run the app with `./tool/run_dev.sh` (which uses `--dart-define-from-file=.env`). Never put a `flutter run` command inside `.env`; `tool/run_dev.sh` now rejects those lines before launching. `.vscode/launch.json` (local, ignored) also passes `.env`.
- After changing `.env`, stop the app completely: `--dart-define` values are compile-time and hot reload does not apply them.
- `.env` only stores `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `GROQ_API_KEY`. Never paste real keys into chat or docs; rotate any exposed key.
- `.env` no longer ships inside app bundles. Any key that was present in a local build must be rotated (Groq key and Supabase DB password).
- `devtools_options.yaml` is generated by Flutter DevTools and intentionally left untracked.

## Sync, auth, and budgets

Goal: queue local writes offline, push them to Supabase, pull remote changes, and resolve conflicts last-write-wins.

### Decisions

- Use Supabase **PostgREST over `http.Client`** (no `supabase_flutter` dependency).
- Credentials from `AppEnv` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); missing config yields `supabase_not_configured` and a non-fatal offline report.
- Queue lives in `lib/core/sync/sync_operation.dart`; key = `<entityType>:<entityId>` so repeated edits collapse.
- Sync scope: **transactions, debts, budgets, and receivables**. Receipts remain local-only for now.
- Conflict policy: if remote `updatedAt` is newer than the local payload, remote wins and is written locally; otherwise push local.
- Deletes write `deletedAt` tombstones and are pushed/pulled; local queries hide tombstones while they remain for idempotent sync.
- Local store remains the source of truth; a remote failure never rolls back a local write.
- Sync queue failures must not fail the business write.
- UI: app-level `SyncBloc` + dashboard AppBar `SyncStatusChip` (manual sync + pending count), auto-sync status on startup.
- Hive boxes: `sync_queue`, `sync_meta`, `budgets`.
- Auth: Supabase GoTrue REST + `flutter_secure_storage`; sync uses the access token and reports unauthenticated state.
- Budgets are synced with the same queue/tombstone/LWW pipeline; aggregation comes from `TransactionRepository`.
- SQL: `0001_init.sql`, `0002_tombstones.sql`, RLS test script.

### Session persistence

- Supabase GoTrue owns the refresh-token lifetime. The project **must** set
  Authentication → Sessions → Refresh token expiry to **60 days or longer**;
  the client cannot extend it and an expired refresh token forces a new login.
- `AuthRepositoryImpl.restoreSession()` keeps the stored session when a refresh
  fails transiently (`auth_timeout`, `auth_network_error`, `auth_not_configured`,
  `auth_http_429`, `auth_http_5xx`), so the app opens offline signed in. Only
  permanent rejections (400/401/invalid response) clear the stored session;
  local ledger data and the owner survive until an explicit sign-out.
- `SessionKeeper` (inside `FinSightApp`) refreshes on `AppLifecycleState.resumed`
  while authenticated and runs a timer at `expiresAt - 5 min`, clamped to at
  least 5 minutes from now to avoid a retry loop; it is cancelled on
  unauthenticated/error states and on dispose.

### Progress

- [x] `SyncOperation`, enums, `SyncQueue` interface in `lib/core/sync/`.
- [x] `updatedAt` + `isSynced` on `TransactionEntity` and `DebtEntity`.
- [x] JSON mapping for the new fields in `TransactionModel` and `DebtModel`.
- [x] Enqueue operations from `TransactionRepositoryImpl` and `DebtRepositoryImpl`.
- [x] `SyncLocalDataSource` + Hive implementation (queue + last sync metadata).
- [x] `SyncRemoteDataSource` + Supabase REST implementation.
- [x] `SyncRepositoryImpl` (push, pull, conflict resolution, reports).
- [x] `SyncNowUseCase`, `GetSyncStatusUseCase`, `SyncBloc`, `SyncStatusChip`.
- [x] DI: boxes, module providers, app/main wiring.
- [x] Tests: queue, remote HTTP, sync repository, bloc, repository enqueue paths.
- [x] Docs: `specs/SPEC-sync.md`, ARCHITECTURE, README, tasks.
- [x] Supabase Auth (GoTrue REST), secure session storage, refresh, login UI.
- [x] JWT-authenticated sync with offline/unauthenticated reporting.
- [x] RLS verification SQL + `supabase/verify_rls.sh`.
- [x] Soft-delete tombstones for transactions and debts.
- [x] Budgets/categories slice (domain/data/presentation + route).
- [x] GitHub Actions CI.
- [x] Persistent receipt images + orphan cleanup.
- [x] Sync exponential backoff + tombstone purge.
- [x] Coverage gate script wired into CI.
- [x] `flutter analyze`, unit + integration tests.
- [x] Commit + push.

## Verification

- `flutter analyze` clean.
- 750 unit/widget tests passing.
- 19 integration tests passing on Linux.
- Coverage gate passes: auth 94.9/92.7%, budgets 93.2/96.0%, categories 97.9/100%, scheduled payments 94.1/100%, sync 100/90.9%, wallets 91.5/94.5%, transactions 100/100%, debts 98.1/100%, core 93.1%.
- SQL migrations `0001_init.sql` through `0004_wallet_ids.sql` applied; RLS script available.

## Known gaps / next

1. Poblar `categoryId` canónico en transacciones y presupuestos.
2. Re-run `supabase/verify_rls.sh` against the live project and capture the result; rotate the database password exposed during setup.
3. Populate canonical `category_id` on transactions and budgets.
4. Sync receipt metadata; streaming AI responses.
5. Consider exact alarms or a timezone plugin if reminders need minute precision or correct DST labels.
6. Money as integer minor units instead of `double`.
7. Golden/screenshot tests in CI.
8. Rotate the Groq key and Supabase DB password shared during setup.
9. Defer non-critical startup loads and due-schedule processing (PERF-02, plan 012).

## Conventions to keep

- English docs, Conventional Commits, atomic commit + push per functionality.
- Domain pure Dart; `Result<T> = Either<Failure, T>` at boundaries.
- Sealed + `Equatable` BLoC states; screens handle loading/success/empty/error.
- External services behind interfaces and faked in tests.
- Never commit real credentials; secrets are injected with `--dart-define` or a local, untracked `.env`.
