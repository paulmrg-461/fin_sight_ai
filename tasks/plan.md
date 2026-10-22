# Implementation Plan: transactions foundation slice

## Overview

Build the clean-architecture skeleton (failures, `Result`, DI) and a complete transactions domain/data slice with strict TDD and a runnable verification gate.

## Architecture Decisions

- `Result<T> = Either<Failure, T>` (fpdart) at every use-case/repository boundary.
- JSON file store behind `TransactionLocalDataSource`; swappable for Isar without domain changes.
- Local-first writes; remote upload is best effort and never rolls back local state.
- get_it + injectable composition root, async storage pre-resolved at startup.
- Pure-Dart domain with manual equality (no `equatable`).

## Task List

### Phase 1: Foundation

- [x] Task 1: Write the English `AGENTS.md` and `ARCHITECTURE.md`.
- [x] Task 2: Add dependencies and analyzer configuration.
- [x] Task 3: Implement `Failure`/exceptions and the `UseCase` contract with tests.
- [x] Task 4: Implement the domain entity and repository contract with tests.

### Checkpoint: Foundation

- [x] Domain compiles without Flutter/infrastructure imports.
- [x] Core tests pass.

### Phase 2: Data Slice

- [x] Task 5: Implement `TransactionModel` JSON mapping with round-trip tests.
- [x] Task 6: Implement the JSON local data source with persistence and corruption tests.
- [x] Task 7: Implement the repository with offline fallback tests.

### Checkpoint: Data Slice

- [x] Persistence survives a new instance.
- [x] Remote failure leaves records unsynced.

### Phase 3: Use Cases & Wiring

- [x] Task 8: Implement `GetTransactionsUseCase` with tests.
- [x] Task 9: Implement `AddTransactionUseCase` validation with tests.
- [x] Task 10: Wire get_it + injectable and the app shell.
- [x] Task 11: Run `flutter analyze` and `flutter test --coverage`.

### Checkpoint: Complete

- [x] All acceptance criteria met.
- [x] No skipped tests.
- [x] Analyzer clean.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Code generation breaks on the Dart beta | High | Manual get_it registration fallback in the composition root |
| JSON store corruption | Medium | Strict parse → `CacheFailure`; versioned payload; temp-file rename |
| Concurrent writes lose data | Medium | Async mutex serializes reads/writes |
| `double` precision in money | Medium | Round to 2 decimals now; migrate to minor units when the ledger slice lands |

## Open Questions

- Adopt integer minor units for amounts?
- Sync conflict policy (planned last-write-wins on `updatedAt`).
