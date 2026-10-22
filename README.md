# FinSight AI

Offline-first personal finance app built with Flutter. Local Hive storage is the source of truth for the UI; Supabase (PostgreSQL + RLS) is the planned remote system of record.

## Features

- **Transactions** — income/expense tracking with date-range and category filters, receipt paths, and deletion.
- **Debts** — balances, progress bars, payment history, and a compounded-interest payoff calculator.
- **Dashboard** — shortcuts to every feature and a light/dark theme toggle.
- **Foundation** — Clean Architecture, functional `Result` errors, get_it + injectable, GoRouter, Hive CE, and typed environment configuration.

## Architecture

```text
lib/
├── app/                         # App shell + BLoC providers
├── core/
│   ├── di/                      # get_it + injectable composition root
│   ├── domain/                  # Entity + Failure hierarchy
│   ├── error/                   # Infrastructure exceptions
│   ├── routing/                 # GoRouter + named routes
│   ├── services/                # Hive box container
│   ├── theme/                   # Tokens, themes, ThemeController
│   ├── usecase/                 # UseCase / Result contracts
│   └── utils/                   # Env, clock, constants, formatters
└── features/
    ├── transactions/{domain,data,presentation}
    ├── debts/{domain,data,presentation}
    ├── dashboard/presentation
    ├── ocr/presentation
    └── ai_coach/presentation
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the blueprint and the `SPEC-*.md` files for feature contracts.

## Setup

Requirements: Flutter 3.50 beta / Dart 3.14.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The committed `.env` contains empty placeholders. For production, inject secrets without touching the file:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=GROQ_API_KEY=your-groq-key
```

## Quality gate

```bash
flutter analyze
flutter test --coverage
```

Current status: analyzer clean, **171 tests passing**, 100% coverage for transactions domain/data, 98% for debts domain, 100% for debts data, and 93% for core.

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
- Conventional commits; every feature is committed and pushed before it is reported as done.

Operating instructions for agents live in [AGENTS.md](AGENTS.md).
