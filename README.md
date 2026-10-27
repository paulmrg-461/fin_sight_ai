# FinSight AI

<p align="center">
  <img src="assets/branding/logo_mark_512.png" width="128" alt="FinSight AI logo" />
</p>

Offline-first personal finance app built with Flutter. Local Hive storage is the source of truth for the UI; Supabase (PostgreSQL + RLS) is the remote system of record.

## Features

- **Dashboard** — balance hero, cash/card balances, receivables summary, income/expense/savings KPIs, category donut, monthly comparison, a 30-day committed-cashflow card, a current-debts overview, recent activity, date-range filtering, and pull-to-refresh.
- **Transactions** — income/expense tracking with date-range and category filters, receipt paths, in-place editing (same id, one sync update), duplicate-as-copy, text search over the active period, clipboard CSV export, delete confirmation with undo, and soft-delete tombstones.
- **Debts** — balances, progress bars, payment history, a compounded-interest payoff calculator, and a monthly amortization plan with interest/principal/remaining per installment; the dashboard shows current debt totals and the next due account.
- **Receivables (“Me deben”)** — money you lend, partial payments, remaining balance, progress, due dates, payment history, in-place editing, and Supabase sync.
- **Budgets** — monthly category limits with month navigation and previous-month copying, spending progress, over-budget highlighting, category suggestions, in-place editing from the budget card, delete confirmation, and offline-first sync.
- **Money** — total available split between bank account and cash, actual-balance reconciliation, and account→cash transfers.
- **Categories** — shared category catalog with localized defaults, manual create/rename (cascading to transactions, budgets, and schedules), and archive/restore.
- **Scheduled payments & salary** — monthly or yearly recurring expenses (rent, credits, subscriptions, phone plan) or income (salary) that is recorded automatically when due, with in-app notice, pause/resume, pay-now, delete, and an expected-monthly-income summary.
- **Currency** — COP by default with a persistent COP/USD switch and locale-aware formatting across the app.
- **Languages** — English and Spanish UI (including validation, storage, auth, and sync errors) with a persisted System/English/Español selector and ARB-based localization.
- **OCR** — receipt scanning with ML Kit, tolerant text extraction, editable preview, persistent image storage, and automatic expense creation.
- **AI Coach** — Groq-powered insights generated from real transaction context in the active language (EN/ES), with deterministic JSON prompts, active-debt context, per-language offline caching, a capped generation history, and graceful failure handling.
- **Auth** — Supabase email/password sign-in/up, secure session storage, token refresh, and dashboard account control.
- **Sync** — authenticated Supabase PostgREST push/pull for categories, scheduled payments, wallets, transfers, transactions, debts, budgets, and receivables, with offline queue, per-operation failure isolation, paginated pulls, last-write-wins conflicts, tombstone compaction, pending-count indicator, and manual/startup sync.
- **Foundation** — Clean Architecture, functional `Result` errors, get_it + injectable, GoRouter, typed environment configuration, and emerald light/dark themes.
- **Performance** — the dashboard derives every section from two range reads per refresh and paints before feature blocs, sync, and due-schedule processing load (`StartupLoader`); the integration benchmark seeds 300 transactions across three months to keep regressions visible.

## Architecture

```text
lib/
├── app/                         # App shell + BLoC providers
├── core/
│   ├── currency/                # COP/USD preference + MoneyText
│   ├── l10n/                    # Generated ARB localizations + context.l10n
│   ├── locale/                  # Language preference, use cases, LocaleBloc
│   ├── di/                      # get_it + injectable composition root
│   ├── domain/                  # Entity + Failure hierarchy
│   ├── error/                   # Infrastructure exceptions
│   ├── routing/                 # GoRouter + named routes
│   ├── services/                # Hive boxes, receipt image picker
│   ├── sync/                    # SyncOperation + SyncQueue port
│   ├── theme/                   # Tokens, themes, ThemeController
│   ├── usecase/                 # UseCase / Result contracts
│   └── utils/                   # Env, clock, constants, formatters
└── features/
    ├── auth/{domain,data,presentation}
    ├── transactions/{domain,data,presentation}
    ├── debts/{domain,data,presentation}
    ├── budgets/{domain,data,presentation}
    ├── wallets/{domain,data,presentation}
    ├── categories/{domain,data,presentation}
    ├── scheduled_payments/{domain,data,presentation}
    ├── ocr/{domain,data,presentation}
    ├── ai_coach/{domain,data,presentation}
    ├── dashboard/{domain,data,presentation}
    └── sync/{domain,data,presentation}
specs/                           # Feature specifications
supabase/migrations/             # Postgres schema + RLS + tombstones
supabase/tests/rls_test.sql      # Real-database RLS isolation checks
.github/workflows/ci.yml         # Analyze + unit + Linux integration tests
```

See [ARCHITECTURE.md](ARCHITECTURE.md) and the [specs](specs/) directory for feature contracts.

## Setup

Requirements: Flutter 3.50 beta / Dart 3.14. OCR runs on Android/iOS via Google ML Kit; integration tests replace OCR, Groq, image picking, and auth with fakes.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cp example.env .env   # local development; fill in your credentials
./tool/run_dev.sh     # runs flutter with --dart-define-from-file=.env
```

`example.env` contains empty placeholders. Copy it to `.env` only for local development: `.env` is gitignored, local-only, and must never be declared as a Flutter asset. `./tool/run_dev.sh` passes the file to Flutter for you; do not store a `flutter run` command inside `.env` (a missing line continuation silently drops later `--dart-define` flags). Localizations are generated with `flutter gen-l10n` (also triggered by `flutter run`/`flutter test`); their sources are `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`. Inject real secrets at build time (CI and release builds do not need `.env`):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=GROQ_API_KEY=your-groq-key
```

### Supabase

1. Apply the migrations: `0001_init.sql` through `0005_receivables.sql` (or `supabase db push`).
2. Sign in from the dashboard account button. Without a session the app stays offline and the sync chip says “Sign in to sync”.
3. Verify RLS against a real database:

```bash
export SUPABASE_DB_URL="postgresql://postgres:...@db.<project>.supabase.co:5432/postgres"
./supabase/verify_rls.sh
```

See [supabase/README.md](supabase/README.md) for details. The app defaults to **COP**; switch to USD from Settings without exchange-rate conversion.

**Session lifetime.** Supabase GoTrue owns the refresh token; the client cannot extend it. Set **Authentication → Sessions → Refresh token expiry** to **60 days or longer** (the access token/JWT expiry can stay at the default 1 hour) so users stay signed in across restarts and offline launches. Timeouts, network errors, and 429/5xx refresh failures keep the stored session; only an explicit sign-out erases local data.

Categories and scheduled-payment definitions are stored locally in Hive. Expenses generated by a schedule use the normal transaction pipeline, so they are queued and synchronized like any other expense. No extra migration is required for this slice.

## Quality gates

```bash
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart
flutter test -d linux integration_test/app_flow_test.dart
```

Current status:

- **866 unit/widget tests** passing.
- **21 integration tests** passing on Linux desktop.
- Coverage gate passes: auth 94.9/92.7%, budgets 93.2/96.0%, categories 97.9/100%, scheduled payments 94.1/100%, receivables 98.1/92.3%, sync 100/90.4%, wallets 91.5/94.5%, transactions 100/100%, debts 98.1/100%, OCR 98.8/99.1%, AI Coach 100/100%, dashboard 93.1/97.6%, core 93.1%.
- Integration benchmarks: app launch + dashboard ≈ 179 ms, transactions render ≈ 251 ms.
- CI: GitHub Actions runs format, analyze, coverage gate, and Linux integration tests under Xvfb.

## Routes

| Name | Path |
| --- | --- |
| `dashboard` | `/dashboard` |
| `transactions` | `/transactions` |
| `debts` | `/debts` |
| `budgets` | `/budgets` |
| `money` | `/money` |
| `scheduled-payments` | `/scheduled-payments` |
| `categories` | `/categories` |
| `receivables` | `/receivables` |
| `settings` | `/settings` |
| `ocr` | `/ocr` |
| `ai-coach` | `/ai-coach` |
| `login` | `/login` |

## Conventions

- TDD: red → green → refactor; every behavior has a test.
- Domain stays pure Dart (no Flutter, DI, or I/O imports).
- Sealed, `Equatable` BLoC states; every screen renders loading, success, empty, and error.
- External services are abstracted behind data-source interfaces and faked in tests.
- Conventional commits; every feature is committed and pushed before it is reported as done.

Operating instructions for agents live in [AGENTS.md](AGENTS.md). Session state and pending work live in [MEMORY.md](MEMORY.md).

## Local reminders

Scheduled payments request a local notification at **9:00 local time on the next
due date** (Android and iOS). Payments due today or already overdue are handled
by the in-app due processing instead, so the reminder never duplicates a charge.

- Android: `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`; the plugin receivers
  restore schedules after a reboot. Scheduling is inexact (`inexactAllowWhileIdle`)
  to avoid exact-alarm approval; the OS may drift by a few minutes.
- iOS: the app sets `UNUserNotificationCenter` as the delegate and requests
  alert/badge/sound permission on the first reminder.
- Linux, macOS, Windows, web, and tests use a no-op scheduler; navigation and
  integration tests remain deterministic.
