# Plan 033: Surface budget alerts on the dashboard

> **Executor instructions**: Read `BudgetBloc`; do not add another query or
> notification pipeline for thresholds.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 017, 021
- **Category**: direction
- **Planned at**: commit c308ed6, 2026-10-27
- **Status**: DONE

## What shipped

- `BudgetAlertsCard` shows categories at **80% or more** of their monthly limit,
  sorted by usage, capped at three.
- Each row shows the category, percentage, progress bar (red when over), and
  spent/limit amounts; the card opens `/budgets`.
- Hidden when no category is close to its limit.
- Fed by the existing `BudgetBloc` state; no new storage reads.

## Tests

- Widget: threshold filtering, over-limit styling, tap, and hidden state.

## Done criteria

- [x] Dashboard warns near/over-budget categories.
- [x] No extra queries or notification spam.
- [x] Analyze, coverage gate, and Linux integration pass.
