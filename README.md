# FinSight AI

Offline-first personal finance app built with Flutter. Local storage is the single source of truth for the UI; Supabase (PostgreSQL + RLS) is the remote system of record and async sync target.

This repository currently contains the **foundation slice**: Clean Architecture scaffolding, functional error handling, dependency injection, and the `transactions` domain/data layers with a full test suite.

## Architecture

```text
lib/
├── app/                         # App shell and theme
├── core/
│   ├── di/                      # get_it + injectable composition root
│   ├── error/                   # Failure and exception taxonomy
│   └── usecase/                 # UseCase / Result contracts
└── features/
    └── transactions/
        ├── domain/              # Transaction entity, repository contract, use cases
        └── data/                # JSON model, local/remote data sources, repository
```

- `Result<T> = Either<Failure, T>` (`fpdart`) at every layer boundary.
- Local-first writes; remote sync is best effort and never rolls back local state.
- JSON-file store behind `TransactionLocalDataSource`, swappable for Isar/Drift.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full blueprint and [SPEC-transactions.md](SPEC-transactions.md) for the slice specification.

## Prerequisites

- Flutter 3.50 beta / Dart 3.14 (see `pubspec.yaml`)
- A connected device or desktop target

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Regenerate dependency injection after changing `@injectable` annotations:

```bash
dart run build_runner build
```

## Quality gate

```bash
flutter analyze
flutter test --coverage
```

Current status: analyzer clean, 62 tests passing, 100% domain and 99.3% data coverage.

## Project conventions

- TDD: red → green → refactor; no behavior without a test.
- Domain layer stays pure Dart (no Flutter, DI, or I/O imports).
- Feature-first structure with strict `domain`/`data`/`presentation` boundaries.
- Conventional commits (`feat:`, `fix:`, `test:`, `docs:`).

Operating instructions for agents live in [AGENTS.md](AGENTS.md).
