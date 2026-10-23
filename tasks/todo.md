# Task List — FinSight AI

## Core and existing features

- [x] Core infrastructure (DI, routing, theme, env, domain base)
- [x] Transactions slice with Hive persistence and BLoC
- [x] Debts slice with payoff calculator and BLoC

## OCR

- [x] Receipt entities, repository, Scan/Save/Get use cases
- [x] Tolerant receipt parser + model
- [x] ML Kit data source + Hive data source + repository
- [x] OcrBloc + scan/save/load states
- [x] OCR screen + editable preview
- [x] Receipt → expense transaction
- [x] Unit, parser, data, and BLoC tests

## AI Coach

- [x] Financial insight entity + repository + use cases
- [x] Groq prompt templates + HTTP data source
- [x] Insight parser + repository implementation
- [x] AiCoachBloc with transaction context
- [x] Chat-like screen + InsightCard
- [x] Prompt, HTTP, parser, repository, use case, and BLoC tests

## Dashboard

- [x] Summary/breakdown/comparison entities + repository
- [x] Dashboard calculator + transaction aggregation
- [x] Dashboard use cases + range validation
- [x] DashboardBloc (load/refresh/range)
- [x] Summary cards, pie/bar charts, recent activity, quick actions, pull-to-refresh
- [x] Calculation, repository, use case, and BLoC tests

## Sync

- [x] SyncOperation + SyncQueue port
- [x] Hive queue + last-sync metadata
- [x] Supabase PostgREST datasource
- [x] Push/pull + last-write-wins conflicts
- [x] Offline reports and queue retries
- [x] SyncBloc + dashboard status chip + startup sync
- [x] Postgres schema + RLS migration
- [x] Queue, HTTP, repository, use case, BLoC, and enqueue tests

## Auth, tombstones, budgets, CI

- [x] Supabase Auth datasource + secure session storage
- [x] Auth repository/use cases/BLoC/login screen/account button
- [x] JWT-authenticated sync + offline/unauthenticated states
- [x] RLS verification SQL + script
- [x] Soft-delete tombstones for transactions and debts
- [x] Budgets/categories domain/data/BLoC/screen
- [x] GitHub Actions CI
- [x] Unit + integration tests updated

## Production polish

- [x] Persistent receipt images + orphan cleanup
- [x] Sync exponential backoff
- [x] Tombstone compaction (30 days)
- [x] Coverage gate script + CI step
- [x] Login/sync-chip UX polish
- [x] Widget/service tests for the new behavior

## Synced budgets

- [x] Sync fields + tombstone support
- [x] Queue upserts/deletes
- [x] PostgREST budget datasource + sync merge
- [x] Tombstone purge and resurrection protection
- [x] `0003_budgets.sql` + RLS
- [x] Tests

## Money and currency

- [x] Bank/cash wallets + default creation
- [x] Balance calculation, reconciliation, transfers
- [x] Money screen + route + dashboard action
- [x] Transaction wallet assignment + sync mapping
- [x] COP/USD setting, formatting, MoneyText, Settings screen
- [x] Unit, data, BLoC, and integration tests

## Integration

- [x] Integration harness with real Hive + fake OCR/Groq/picker
- [x] Complete user-flow tests
- [x] Persistence across restart
- [x] Launch and render benchmarks
- [x] Integration tests passing with `flutter test -d linux`

## Verification

- [x] `flutter analyze` — no issues
- [x] `flutter test --coverage` — 545 tests passing
- [x] Integration tests — 10 passing
- [x] Domain and data coverage ≥ 90%
- [x] Commit and push
