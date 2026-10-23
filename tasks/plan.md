# Implementation Plan: OCR, AI Coach, Dashboard, integration

## Overview

Deliver three new feature slices and an end-to-end integration suite on top of the existing Clean Architecture foundation.

## Architecture Decisions

- OCR behind `OcrDataSource`; ML Kit in production, fakes in tests.
- Groq behind `AiCoachDatasource`; prompts and response parsing are pure and testable.
- Dashboard aggregates through `TransactionRepository`; calculations live in a pure calculator.
- Integration tests use real Hive persistence with fake OCR/Groq/image picker.

## Task List

### Phase 1: OCR

- [x] `ReceiptEntity` / `ReceiptItem` and repository contract.
- [x] Scan/Save/Get use cases with validation.
- [x] `ReceiptParser`, `ReceiptModel`, ML Kit datasource, Hive data source, repository.
- [x] `OcrBloc`, `OcrScreen`, `ReceiptPreviewScreen`.
- [x] Receipt save creates an expense transaction.
- [x] Unit/data/BLoC tests.

### Phase 2: AI Coach

- [x] `FinancialInsightEntity` and repository contract.
- [x] Groq prompt templates and `GroqApiDatasource`.
- [x] `InsightParser` and repository implementation.
- [x] Insights/Analyze/Savings use cases.
- [x] `AiCoachBloc` with transaction-derived context.
- [x] `AiCoachScreen` and `InsightCard`.
- [x] Prompt, HTTP, parser, repository, use case, and BLoC tests.

### Phase 3: Dashboard

- [x] Dashboard entities and repository contract.
- [x] `DashboardCalculator` and repository aggregation.
- [x] Summary/Breakdown/Comparison use cases with range validation.
- [x] `DashboardBloc` with load, refresh, and range changes.
- [x] Summary cards, pie chart, bar chart, recent activity, pull-to-refresh, quick actions.
- [x] Calculation, repository, use case, and BLoC tests.

### Phase 4: Integration and delivery

- [x] Integration harness with real Hive and fake external services.
- [x] User flows: empty dashboard, add transaction, receipt scan, add debt, AI insights, date filter.
- [x] Persistence across app restart.
- [x] Performance benchmarks (launch/render).
- [x] `flutter analyze` clean, unit tests green.
- [x] Integration tests green on Linux.
- [x] Commit and push.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| ML Kit unavailable on desktop/web | Medium | Platform abstraction + handled `OcrException`; fakes in tests |
| Groq latency or outages | Medium | 15s timeout, stable error codes, retry UI |
| OCR misparses totals | Medium | Editable preview + save validation |
| Chart animations block tests | Low | Pump-until helpers instead of `pumpAndSettle` |
| Integer/float money drift | Medium | Round to 2 decimals; future minor-unit migration |
