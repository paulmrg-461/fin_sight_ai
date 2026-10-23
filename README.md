# FinSight AI

Offline-first personal finance app built with Flutter. Local Hive storage is the source of truth for the UI; Supabase (PostgreSQL + RLS) is the remote system of record.

## Features

- **Dashboard** — income/expense/balance/savings KPIs, category pie chart, monthly comparison bar chart, recent activity, date-range filtering, and pull-to-refresh.
- **Transactions** — income/expense tracking with date-range and category filters, receipt paths, and soft-delete tombstones.
- **Debts** — balances, progress bars, payment history, and a compounded-interest payoff calculator.
- **Budgets** — monthly category limits with spending progress, over-budget highlighting, category suggestions, and offline-first sync.
- **Money** — total available split between bank account and cash, actual-balance reconciliation, and account→cash transfers.
- **Categories** — shared category catalog with localized defaults, manual create/rename, and archive/restore.
- **Scheduled payments** — monthly or yearly recurring expenses (rent, credits, subscriptions, phone plan) that are recorded automatically when due, with in-app notice, pause/resume, pay-now, and delete.
- **Currency** — COP by default with a persistent COP/USD switch and locale-aware formatting across the app.
- **Languages** — English and Spanish UI with a persisted System/English/Español selector and ARB-based localization.
- **OCR** — receipt scanning with ML Kit, tolerant text extraction, editable preview, persistent image storage, and automatic expense creation.
- **AI Coach** — Groq-powered insights generated from real transaction context, with deterministic JSON prompts and graceful failure handling.
- **Auth** — Supabase email/password sign-in/up, secure session storage, token refresh, and dashboard account control.
- **Sync** — authenticated Supabase PostgREST push/pull, offline queue, exponential backoff, last-write-wins conflicts, tombstone compaction, pending-count indicator, and manual/startup sync.
- **Foundation** — Clean Architecture, functional `Result` errors, get_it + injectable, GoRouter, typed environment configuration, and emerald light/dark themes.

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
cp example.env .env   # then fill your local credentials (never commit .env)
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The committed `example.env` contains empty placeholders; `.env` is gitignored. Localizations are generated with `flutter gen-l10n` (also triggered by `flutter run`/`flutter test`); their sources are `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`. Inject real secrets at build time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=GROQ_API_KEY=your-groq-key
```

### Supabase

1. Apply the migrations: `0001_init.sql` through `0004_wallet_ids.sql` (or `supabase db push`).
2. Sign in from the dashboard account button. Without a session the app stays offline and the sync chip says “Sign in to sync”.
3. Verify RLS against a real database:

```bash
export SUPABASE_DB_URL="postgresql://postgres:...@db.<project>.supabase.co:5432/postgres"
./supabase/verify_rls.sh
```

See [supabase/README.md](supabase/README.md) for details. The app defaults to **COP**; switch to USD from Settings without exchange-rate conversion.

Categories and scheduled-payment definitions are stored locally in Hive. Expenses generated by a schedule use the normal transaction pipeline, so they are queued and synchronized like any other expense. No extra migration is required for this slice.

## Quality gates

```bash
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart
flutter test -d linux integration_test/app_flow_test.dart
```

Current status:

- **668 unit/widget tests** passing.
- **13 integration tests** passing on Linux desktop.
- Coverage gate passes: auth 94.9/92.0%, budgets 93.2/95.6%, categories 97.9/100%, scheduled payments 100/100%, sync 100/90.9%, wallets 91.5/94.5%, transactions 100/100%, debts 98.1/100%, OCR 98.8/99.1%, AI Coach 100/100%, dashboard 93.1/97.6%, core 91.1%.
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
