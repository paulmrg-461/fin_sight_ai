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

## Integration

- [x] Integration harness with real Hive + fake OCR/Groq/picker
- [x] Complete user-flow tests
- [x] Persistence across restart
- [x] Launch and render benchmarks
- [x] Integration tests passing with `flutter test -d linux`

## Verification

- [x] `flutter analyze` — no issues
- [x] `flutter test --coverage` — 374 tests passing
- [x] Integration tests — 7 passing
- [x] Domain and data coverage ≥ 90%
- [x] Commit and push
