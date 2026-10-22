# Architectural Blueprint — FinSight AI

## 1. System Overview

FinSight AI is an offline-first personal finance application built with Flutter. Local storage is the single source of truth for the UI; Supabase (PostgreSQL + RLS) is the remote system of record and sync target.

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
│ Local store  │ │ Supabase (async sync) │
│ (truth)      │ │ REST / RLS            │
└──────────────┘ └───────────────────────┘
```

### Dependency rule

`presentation → domain ← data`. The domain layer imports neither Flutter nor infrastructure packages. `data` implements interfaces declared by `domain`; `presentation` depends on use cases only.

## 2. Layer Contracts

| Layer | Owns | Must not |
| --- | --- | --- |
| `core` | Failures, exceptions, `UseCase` contract, DI composition root, shared services | Contain feature business rules |
| `domain` | Entities, repository interfaces, use cases | Import Flutter, get_it, databases, HTTP |
| `data` | DTOs/mappers, data sources, repository implementations | Expose DTOs to presentation |
| `presentation` | Cubits/BLoCs, screens, widgets | Call data sources or repositories directly |

Error handling is explicit: repositories return `Either<Failure, T>` (`Result<T>`). Exceptions are caught at the data-layer boundary and mapped to `ServerFailure`, `CacheFailure`, or `ValidationFailure`.

## 3. Offline-First Synchronization Flow

```text
[ UI (BLoC) ] ◄── observe ── [ Local Store ] (source of truth)
                                   ▲
        Event                      │ local write
          ▼                        │
     [ UseCase ] ──► [ RepositoryImpl ] ──┐
                                           │ async, best effort
                                           ▼
                              [ Supabase (PostgreSQL + RLS) ]
```

1. **User action:** the user records an expense or scans a receipt.
2. **Local write:** the transaction is persisted locally before any network call.
3. **UI update:** the UI reflects the local write immediately.
4. **Remote sync:** a background worker (later slice) pushes records where `isSynced == false`; successful uploads are marked `isSynced = true`.

**Invariant:** a failed remote call never rolls back a successful local write. The record simply remains pending and is retried.

### Current slice (transactions)

- `TransactionLocalDataSource` is an interface. The current implementation is `JsonFileTransactionLocalDataSource`, which stores an atomic JSON document (`version` + `transactions[]`) in the app documents directory.
- Writes are serialized through an internal async mutex, and the payload is written to a temp file before rename.
- `NoopTransactionRemoteDataSource` represents an unconfigured Supabase backend: upload returns `false`, so records stay `isSynced = false` and are retried later.
- The interface isolates persistence from the domain. Swapping JSON for Isar (or Drift) is a data-layer change with no domain or UI impact.

## 4. Transaction Domain Model

| Field | Type | Rules |
| --- | --- | --- |
| `id` | `String` | UUID v4, immutable |
| `amount` | `double` | Finite, `> 0`, rounded to 2 decimals |
| `date` | `DateTime` | UTC in storage, ISO-8601 in JSON |
| `category` | `String` | Trimmed, non-empty |
| `type` | `TransactionType` | `income` or `expense` |
| `note` | `String` | Trimmed, ≤ 500 characters |
| `isSynced` | `bool` | Local sync flag, never trusted from the client for authorization |

`addTransaction` validates input in the use case and returns `ValidationFailure` with a stable `code` (`invalid_amount`, `missing_category`, `note_too_long`). The repository persists locally, then attempts upload. On upload success the local record is marked synced; on failure it is returned unsynced.

## 5. Dependency Injection

`get_it` is the service locator; `injectable` generates the registration graph.

- Composition root: `lib/core/di/injection.dart` → `configureDependencies()`.
- The generated file is `injection.config.dart` (build_runner).
- Lifetimes: repositories and use cases are `@lazySingleton`; data sources follow storage lifetime; async storage is `@preResolve` so the app starts with a ready local store.
- Tests construct collaborators directly (no global container), keeping unit tests deterministic.

Regenerate after changing annotations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 6. Low-Latency AI Architecture (Groq API) — planned slice

- `GroqApiClient` over `http`/`dio` with a strict 5-second timeout and bounded retries.
- API keys are injected via `--dart-define`/`flutter_dotenv`; never committed.
- Prompts enforce JSON-schema responses (Llama-3/Mixtral) for deterministic budget recommendations.
- AI calls run outside the critical path: cached locally, failure degrades gracefully.

## 7. Testing Strategy

| Level | Scope | Tooling |
| --- | --- | --- |
| Unit | Entities, validation, mappers, use cases | `flutter_test`, `mocktail` |
| Data integration | JSON store against a temp file system | `flutter_test`, `dart:io` |
| Widget | Screens and state rendering | `flutter_test`, `bloc_test` (later slice) |

Commands:

```bash
flutter analyze
flutter test --coverage
```

Target: ≥ 90% coverage for domain and data layers.

## 8. Key Decisions

| Decision | Rationale | Trade-off |
| --- | --- | --- |
| `fpdart` `Either` instead of throwing | Explicit failure paths, compile-time exhaustiveness | Slightly more verbose call sites |
| JSON-file store for the first slice | Zero codegen/plugin risk, fully testable, works on all platforms | Not queryable at scale; replace with Isar/Drift behind the same interface |
| Local-first writes | Instant UI, resilience to offline/network failures | Requires conflict resolution in the sync slice |
| Manual entity equality instead of `equatable` | Keeps the domain pure Dart | More boilerplate |
| Supabase over Firebase | Relational queries, RLS, predictable pricing | Team must own SQL and migrations |

## 9. Roadmap

1. Transactions sync with Supabase and conflict resolution (last-write-wins by `updatedAt`).
2. Budgets, categories, and dashboard aggregates.
3. Receipt OCR ingestion.
4. Groq-powered insights with deterministic JSON contracts.
5. Full presentation layer with four-state UI patterns.
