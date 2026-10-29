# Project Memory — FinSight AI

_Last updated: 2026-10-28. Read this before starting a new session._

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
| Biometric app lock (opt-in, lifecycle-aware) | Done |
| Receipt metadata sync (queue + Supabase) | Done |
| Android home-screen widget | Done |
| Hive at-rest encryption (AES + secure key) | Done |
| Desktop storage in app support (one-time copy) | Done |
| Drawer account and sync rows (app bar simplified) | Done |
| Screen protection + receipt image cleanup | Done |
| Annual reports + PDF sharing | Done |
| Chart semantics, conflict snackbar, drawer/empty goldens | Done |
| App-wide UI polish (halos, progress bars, day groups, annual bars) | Done |
| WCAG AA contrast audit + regression test | Done |
| Animated shell tab transitions | Done |
| Integration suite (38 flows + benchmarks) | Done |

### Current checkpoint (2026-10-28, latest)

- HEAD: `d107c44` on `develop` and `main` (both pushed, in sync).
- Gates: `flutter analyze` clean, **1147** unit/widget tests, coverage gate green, **38** Linux integration tests.
- Android debug APK builds with biometrics, widget, encryption, and `--dart-define-from-file=.env`.
- Benchmarks: launch/dashboard ~226 ms, transactions render ~182 ms with 300 seeded transactions.
- Integration command: `flutter test -d linux integration_test/app_flow_test.dart`.
- Local run command: `flutter run -d linux --dart-define-from-file=.env`. The app is **not running** right now (last session closed with `Lost connection to device`).
- Branch policy: work on `develop`, commit + push every feature, fast-forward into `main` and push.
- Recent commits (newest first): `d107c44` animated tabs, `1e6723b` transaction form + contrast, `4931fe5` settings/coach/OCR/schedules/wide layouts, `8e53f62` percent pills, `7a1eb6c` UI polish pass, `3300944` money/category primitives, `3310e91` annual PDF, `b9c4d11` chart semantics/conflicts/goldens, `9b08815` FLAG_SECURE + receipt images, `34d77de` drawer account/sync, `c7c3553` desktop storage, `13b66e8` DI biometric fix, `5a4c80d` hosted schema memory, `35af517` Supabase scripts.
- Latest plans: `037` app lock, `038` receipt sync, `039` Android widget, `040` Hive encryption, `041` desktop storage, `042` drawer account/sync, `043` a11y/conflicts/goldens, `044` annual PDF, `045` money/category primitives, `046` UI polish.
- Environment: `.env` exists locally, is gitignored, and has `SUPABASE_URL`, `SUPABASE_ANON_KEY` (publishable), and `GROQ_API_KEY` set. The **Groq key has been pasted in chat twice and must be rotated**; the Supabase publishable key is safe to expose. Never print or commit these values.
- Hosted Supabase schema (`0001`–`0008`) is applied; the receipts/savings tables resolve (401 for `anon`, not PGRST205). A database-level `verify_rls.sh` run is still pending because no DB URL is stored.

## UI polish pass (plan 046)

- Shared empty/error states now use a glowing icon halo and a gradient card wash; section headers gained a gradient accent bar.
- Theme-level polish: segmented buttons, extended FAB, popup menus, taller app bars, stadium nav indicator, roomier list tiles.
- New `AppProgressBar` (animated, rounded, gradient, semantics) replaced every raw progress indicator across budgets, savings, debts, receivables, wallets, and budget alerts; `AppPercentPill` unifies budget/savings/debt percentages.
- Transactions group by day with Today/Yesterday headers and a daily net; budgets show a category badge, percentage pill, animated bar, and remaining/over indicator.
- Annual reports render two proportional mini bars per month (income vs expenses) for a quick yearly trend.
- Settings gained icon badges and section labels; AI Coach a gradient header; OCR shared empty/error states; schedules group into Overdue/Today/Week/Upcoming/Paused; the dashboard is two-column at ≥900 px.
- Transaction form has a hero amount field and tinted expense/income selector; the theme now passes a WCAG AA contrast test (deep ink on emerald, accessible error pairs).
- Shell navigation uses a custom `StatefulShellRoute` container: the active branch fades/slides in, inactive branches stay mounted offstage, so state and test semantics are preserved.
- Goldens regenerated (drawer at full height, empty state, budget alerts) and verified stable; a new widget test covers the day grouping.

## UI, reporting, and primitives (2026-10-28)

- `FLAG_SECURE` follows the app-lock preference; receipt images moved to app support on desktop with a one-time legacy copy and are deleted on sign-out.
- Dashboard charts expose semantics summaries; sync conflicts surface as a snackbar; drawer and empty-state goldens guard the navigation and guidance layouts.
- Reports gained an annual mode with a 12-month breakdown and a pure-Dart PDF shared through `ReportExporter.sharePdf`.
- Phase 1 of the data-model work landed `Money` (integer minor units) and `CategoryResolver`; entities still use `double`/names until their per-slice migrations.

## Drawer account and sync (plan 042)

- Dashboard app bar now has only the menu, logo, search, and period picker.
- `AccountTile` replaces `AccountButton`: **Sign in** (subtitle "Sign in to sync") or **Sign out** with the existing confirmation, closing the drawer before dispatching `SignOutRequested`.
- `SyncStatusChip(expanded: true)` renders a **Sync** ListTile in the drawer with the status text as subtitle; tapping keeps the login/retry/sync behaviour and the entity-failure dialog.
- Integration helpers `openDrawer`, `scrollDrawerTo`, `tapDrawerItem`, and `closeDrawer` drive the new flows; the sync-offline diagnosis test now reads the drawer subtitle.

## Desktop run fix (2026-10-28)

- Running `flutter run -d linux` exposed a DI bug: injectable tried to resolve `LocalAuthentication` for `LocalAuthBiometricService` because its constructor took an optional plugin instance. The service now creates the plugin internally, and `injection_test` asserts `BiometricService`, `SecurityPreferences`, and `SecurityCubit` resolve.
- Linux boxes moved to `~/.local/share/pro.devpaul.fin_sight_ai` (plan 041); the first desktop launch copies legacy `*.hive` files from `~/Documents` without deleting the originals or copying `.lock` files. Receipt images still live under the documents directory.

## Hive at-rest encryption (plan 040)

- `HiveEncryption` keeps a 32-byte AES key (`hive_encryption_key`, base64) in `flutter_secure_storage`; missing/malformed keys are regenerated and storage failures return `null` (plaintext fallback, matching the old behavior).
- `EncryptedBoxOpener` opens boxes with `HiveAesCipher`, and only migrates plaintext when `allowLegacyMigration` is true: it copies entries, deletes the old file, and reopens encrypted.
- `StorageModule` reads the unencrypted `storage_meta` flag first. Once `encrypted` is set, a missing/wrong key throws instead of feeding ciphertext to the plaintext reader; on first successful launch the flag is written.
- Tests cover key generation/reuse/malformed fallback, fresh encrypted boxes, one-time migration, refused legacy fallback, wrong-key safety, and raw-file checks that plaintext no longer appears.
- **Caveat:** losing the secure-storage key makes local boxes unreadable. `main.dart` now catches startup failures and shows `StartupFailureApp` with a non-destructive recovery message instead of crashing to a blank screen.

## Android home-screen widget (plan 039)

- `WidgetDataBridge` publishes a `DashboardWidgetSnapshot` over `devpaul.fin_sight_ai/widget`; `AndroidWidgetDataBridge` formats with the persisted currency and swallows missing-plugin failures.
- `DashboardBloc` takes an optional bridge and publishes after `DashboardLoaded`; bridge failures never alter dashboard state, and existing tests construct the bloc without one.
- `MainActivity` stores the snapshot in `fin_sight_widget` preferences (`WidgetStore`) and triggers `FinanceWidgetProvider.refreshAll`.
- `FinanceWidgetProvider` renders a resizable 4×2 RemoteViews card (balance, "Spent", currency) and opens the app on tap; resources live in `res/layout`, `res/xml`, `res/drawable`, and `values/strings.xml`.
- Tests: channel payload/formatting, graceful no-channel behavior, and dashboard publish/failure paths. APK debug build compiles the Kotlin side.
- Manual installation pending while the Samsung device is unreachable on the LAN.

## Receipt metadata sync (plan 038)

- `ReceiptEntity` gained `updatedAt` / `isSynced` with `lastModified = updatedAt ?? date`; business equality ignores sync metadata and old local rows still parse.
- `ReceiptRepositoryImpl` stamps writes and enqueues `SyncEntityType.receipt`; a queue failure never rolls back the local save.
- `SyncRepositoryImpl` pushes receipts with remote LWT/LWW, pulls with an isolated entity failure, and merges only newer rows. Receipts are never hard-deleted.
- `SupabaseRestSyncDataSource` maps `receipt_date`, `merchant_name`, `total_amount`, `currency`, `items`, `image_path`, and `updated_at`.
- Migration `0008_receipts.sql` adds owner-only RLS and grants, mirrored in `apply_all.sql` and the RLS test.
- Images do not sync; a pulled receipt points at a device-local path and the preview hides the missing file.
- **Pending:** 0007 and 0008 must still be applied to the hosted Supabase project; no DB connection string is available here.

## App lock with biometrics (plan 037)

- `BiometricService` wraps `local_auth` behind an interface; `LocalAuthBiometricService` treats plugin errors as "unavailable" instead of crashing.
- `SecurityPreferences` persists `biometric_lock_enabled` in the settings box; storage faults leave the app unlocked.
- `SecurityCubit` reconciles the stored flag with device support, so a restored backup on a device without biometrics cannot lock the user out. `setEnabled` refuses to enable when unsupported.
- `AppLockGate` wraps the router child (after onboarding), locks on load and on `AppLifecycleState.paused`, and shows a themed lock screen with retry. Duplicate prompts are blocked.
- Settings has a security card with an adaptive switch and localized English/Spanish copy; the switch is disabled while loading or unsupported.
- Android: `MainActivity` is a `FlutterFragmentActivity` and the manifest declares `USE_BIOMETRIC`.
- Tests: cubit persistence/capability, gate lock/unlock paths, settings providers, and an integration flow that keeps the dashboard hidden until unlock.
- Known gap: this is presentation gating only; Hive boxes are still unencrypted.

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

## Sync 404 troubleshooting

- The sync chip now opens a dialog with the actual failure and a Retry action; debug builds log `SYNC failed: <code>` and transport details.
- Pulls are isolated per entity: `SyncReport.failures` lists `SyncEntityFailure(entity, code, message)`, and a missing table no longer aborts other entities. Partial passes report the failing entities for Retry.
- `supabase_http_404` maps to “cloud schema is out of date; apply migrations”. This happened on the Samsung because `0007_savings_goals.sql` was not applied; pulls request every table even when no local savings goals exist.
- Release builds now declare `android.permission.INTERNET` in the main manifest (previously only debug/profile had it).

## CSV import (plan 036)

- `TransactionCsvImporter` parses EN/ES headers or headerless rows, quotes/newlines, ISO/day-first dates, LatAm thousands/decimals, parentheses negatives, and per-row errors.
- `ImportTransactionsCsvUseCase` dedupes against the ledger and within the file, imports via `AddTransactionUseCase` (UUID + validation + sync queue), and returns imported/skipped/failed counts.
- `/import-csv` (drawer) is paste-first; after success it reloads `TransactionBloc`.
- Tests: parser/dedupe/use case/cubit + integration import and re-import skip.

## Onboarding (plan 035)

- `OnboardingGate` wraps the router inside `MaterialApp.router`; it reads `OnboardingService.isCompleted()` and shows a 3-page tour until Skip/Get started.
- `HiveOnboardingService` stores `onboarding_completed_v1` in settings; write failures never trap the user.
- Pages cover welcome, offline-first privacy, and first actions; EN/ES, themed, accessible dots.
- Tests: widget gate (incomplete/complete) and integration first-launch skip flow.

## Golden + release CI (plan 034)

- `BudgetAlertsCard` has a committed golden (`test/.../goldens/budget_alerts_card.png`); `.gitignore` re-includes `test/**/goldens/*.png` because the machine-level excludes hide PNGs.
- CI's normal test job fails on golden drift; a new `release-apk` job builds `flutter build apk --release --dart-define-from-file=example.env` with Java 17.
- Release signing still uses debug keys; the job verifies compilation, INTERNET/desugaring, and plugin registration, not store readiness.

## Budget alerts (plan 033)

- Dashboard `BudgetAlertsCard` lists categories at 80%+ of their monthly limit from `BudgetBloc` (top 3, sorted), with percentage, red over-limit bars, and spent/limit amounts; opens `/budgets`.
- Hidden when nothing is close to the limit; no new storage reads or notifications.

## Monthly reports + sharing (plan 032)

- `/reports` navigates months, reads current + previous ranges, and reuses `DashboardCalculator` for summary/comparison/breakdown.
- `ReportsBloc` exposes loading/loaded/empty/failure plus share status; share builds `TransactionCsv`, writes a temp file, and opens the native sheet via `share_plus`.
- `ReportExporter` keeps sharing testable: `ShareReportExporter` is injectable, the integration harness uses `FakeReportExporter`.
- Tests: BLoC share states, MonthlyReport equality, exporter default/failure paths, integration report + share.
- `share_plus` added; Linux/Android debug builds verified.

## Global search (plan 031)

- `/search` from the dashboard app bar searches the already-loaded `TransactionBloc`, `DebtBloc`, `SavingsBloc`, `ScheduledPaymentBloc`, and `ReceivableBloc` states (case-insensitive; 10 results per section).
- Results navigate to their section; empty query and no-results have dedicated states; copy is EN/ES.
- It does not hit Hive or add dependencies; a transaction date filter can narrow what the search sees.
- Integration covers transaction/debt/goal matches and the no-results state.

## Debt impact + savings v2 (plans 029–030)

- Debt extra payments now report interest saved and months earlier versus the minimum, computed from two plans at the same instant; the impact card only appears when something improves.
- Savings goals can be edited (name/target/date) without losing contributions; edits queue a sync upsert.
- Goals with a future target date show the monthly amount needed to reach the target.
- Tests cover the extra-payment comparison, goal update validation/repository/BLoC, monthly pace, and the integration edit flow.

## Savings goals (plan 026)

- Hive `savings_goals` box (cleared via `LocalDataScope`) with `SavingsGoalEntity` + `SavingsContribution` (saved/remaining/progress/completion).
- Use cases validate goal name/target and contributions; amounts are rounded to 2 decimals.
- `/savings` (drawer entry): total-saved hero, goal cards with progress/target date, create and add-money dialogs, confirmed delete.
- Dashboard shows a savings summary (saved/target, count, next target date) from `SavingsBloc`; the AI context includes goal totals for insights and chat.
- Savings goals sync via `0007_savings_goals.sql`, `SyncEntityType.savingsGoal`, queue/tombstone upserts, and the standard LWW merge; tombstones purge after 30 days.
- Tests: domain/data/BLoC, AI context, and an integration create+contribute flow.

## Free-form coach chat (plan 025)

- `/ai-coach/chat` uses `CoachChatBloc` + `AskCoachUseCase`; answers are plain text from the same Groq datasource.
- `CoachContextBuilder` now builds the shared transaction/debt/language context for both insights and chat.
- `CoachMessage` history is stored in `ai_insights` (`chat_messages`, newest 100) and cleared with account data; the user turn is saved before the network call and kept on failure.
- UI: suggestion prompts, user/coach bubbles, send progress, localized errors, confirmed clear action; entry from the coach app bar.
- Tests cover use case, repository prompt/plain text, Hive store cap/corruption, BLoC success/failure/clear, and the integration chat flow.

## AI debt context + history (plan 024)

- `AiCoachBloc` appends active debt context to every prompt: count, total remaining, total minimums, and highest rate; debt failures are ignored.
- `InsightHistoryEntry` stores each successful generation (timestamp + kind + insights). The per-language history is newest-first, capped at 20, stored in `ai_insights`, and cleared on sign-out.
- The coach screen renders a localized **History** expansion with date/time, trigger (`Insights`/`Analyze spending`/`Savings tips`), and contents; latest insights remain the offline fallback.
- Tests cover cache history/kind/cap, debt prompt context, history exposure, and history equality.

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

Blocked on environment:

1. Samsung test device is unreachable (`192.168.0.2:46105`, `:5555`, mDNS) — install the latest debug APK and add the home widget manually.
2. Hosted schema is applied: PostgREST now resolves `savings_goals` and `receipts` (42501 permission denied for anon, versus PGRST205 for a missing table), so the SQL bundle created both. Still pending: a database-level RLS check (`verify_rls.sh`) because no `SUPABASE_DB_URL` is available here. `validate_local.sh` applies 0001–0008 and the RLS suite successfully in Docker.
3. Rotate the Groq key and Supabase DB password shared during setup.

Specified, not implemented (large multi-phase work):

4. Money as integer minor units — see `specs/SPEC-money-minor-units.md`.
5. Canonical `categoryId` on transactions, budgets, schedules — see `specs/SPEC-category-ids.md`.

Smaller follow-ups:

6. Streaming AI responses and receipt search.
7. Consider exact alarms or a timezone plugin if reminders need minute precision or correct DST labels.
8. Additional golden/screenshot coverage beyond the budget alerts card.

## Conventions to keep

- English docs, Conventional Commits, atomic commit + push per functionality.
- Domain pure Dart; `Result<T> = Either<Failure, T>` at boundaries.
- Sealed + `Equatable` BLoC states; screens handle loading/success/empty/error.
- External services behind interfaces and faked in tests.
- Never commit real credentials; secrets are injected with `--dart-define` or a local, untracked `.env`.
