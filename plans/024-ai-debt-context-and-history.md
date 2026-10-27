# Plan 024: Give the AI debt context and keep an insight history

> **Executor instructions**: Debt context is read-only prompt enrichment; never
> let a debt read failure break coaching. History is capped and user-owned.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 019, 020, 023
- **Category**: direction
- **Planned at**: commit 351961e, 2026-10-27
- **Status**: DONE

## Why this matters

The coach only saw transactions, so it could suggest saving while ignoring the
user's actual debt burden. And the offline cache kept only the latest batch, so
previous advice disappeared after a refresh.

## What shipped

- `AiCoachBloc` also reads active debts and appends this to the prompt context:
  count, total remaining, total minimum payments, and highest interest rate.
  A debt read failure is ignored.
- `InsightHistoryEntry` domain model with kind
  (`insights` / `analysis` / `suggestions`), timestamp, and contents.
- `InsightCache` now appends every successful generation to a per-language,
  newest-first history capped at 20 batches; the existing latest-insights cache
  remains for offline fallback.
- `AiCoachLoaded.history` drives a localized **History** expansion in the coach
  screen, showing date/time, trigger, and each saved insight.
- Cache clearing (sign-out) removes history too; corrupt entries are skipped.

## Tests

- Cache: newest-first history, kind, cap at 20, sign-out clearing.
- BLoC: debt summary reaches the prompt; history is exposed with fresh insights.
- Domain: history equality/hash and list comparison.

## Done criteria

- [x] AI context includes active debt totals and rates.
- [x] Every generation is stored in a capped history.
- [x] History renders in the coach screen.
- [x] Analyze, coverage gate, and Linux integration pass.
