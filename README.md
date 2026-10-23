# FinSight AI

Offline-first personal finance app built with Flutter. Local Hive storage is the source of truth for the UI; Supabase (PostgreSQL + RLS) is the remote system of record.

## Features

- **Dashboard** — income/expense/balance/savings KPIs, category pie chart, monthly comparison bar chart, recent activity, date-range filtering, and pull-to-refresh.
- **Transactions** — income/expense tracking with date-range and category filters, receipt paths, and deletion.
- **Debts** — balances, progress bars, payment history, and a compounded-interest payoff calculator.
- **OCR** — receipt scanning with ML Kit, tolerant text extraction, editable preview, Hive persistence, and automatic expense creation.
- **AI Coach** — Groq-powered insights generated from real transaction context, with deterministic JSON prompts and graceful failure handling.
- **Sync** — offline change queue, Supabase PostgREST push/pull, last-write-wins conflict resolution, pending-count indicator, and manual/startup sync.
- **Foundation** — Clean Architecture, functional `Result` errors, get_it + injectable, GoRouter, typed environment configuration, and emerald light/dark themes.

## Architecture

```text
lib/
├── app/                         # App shell + BLoC providers
├── core/
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
    ├── transactions/{domain,data,presentation}
    ├── debts/{domain,data,presentation}
    ├── ocr/{domain,data,presentation}
    ├── ai_coach/{domain,data,presentation}
    ├── dashboard/{domain,data,presentation}
    ├── sync/{domain,data,presentation}
    └── ... (presentation-only feature shells)
supabase/migrations/             # Postgres schema + RLS policies
```

See [ARCHITECTURE.md](ARCHITECTURE.md) and the `SPEC-*.md` files for contracts.

## Setup

Requirements: Flutter 3.50 beta / Dart 3.14. OCR runs on Android/iOS via Google ML Kit; integration tests replace OCR, Groq, image picking, and sync with fakes.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The committed `.env` contains empty placeholders. Inject real secrets at build time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=GROQ_API_KEY=your-groq-key
```

### Supabase

1. Apply [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql) to create `transactions` and `debts` with RLS.
2. Sync requires an authenticated Supabase session; the auth slice is still pending. Without credentials or auth, the app stays fully offline and the dashboard shows a cloud-off indicator.

## Quality gates

```bash
flutter analyze
flutter test --coverage
flutter test -d linux integration_test/app_flow_test.dart
```

Current status:

- **374 unit/widget tests** passing.
- **7 integration tests** passing on Linux desktop.
- Coverage: transactions 100%, debts 98.1/100%, OCR 98.8/99.1%, AI Coach 100%, dashboard 93.1/97.6%, sync 100/91.5%, core 90.1%.
- Integration benchmarks: app launch + dashboard ≈ 160–290 ms, transactions render ≈ 230–280 ms.

## Routes

| Name | Path |
| --- | --- |
| `dashboard` | `/dashboard` |
| `transactions` | `/transactions` |
| `debts` | `/debts` |
| `ocr` | `/ocr` |
| `ai-coach` | `/ai-coach` |

## Conventions

- TDD: red → green → refactor; every behavior has a test.
- Domain stays pure Dart (no Flutter, DI, or I/O imports).
- Sealed, `Equatable` BLoC states; every screen renders loading, success, empty, and error.
- External services are abstracted behind data-source interfaces and faked in tests.
- Conventional commits; every feature is committed and pushed before it is reported as done.

Operating instructions for agents live in [AGENTS.md](AGENTS.md). Session state and pending work live in [MEMORY.md](MEMORY.md).
