# Plan 016: Navigate budget months

> **Executor instructions**: Keep one budget per category per month; selecting a
> month must reload progress from local storage and never mutate other months.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 003, 008
- **Category**: direction
- **Planned at**: commit 5e3e73b, 2026-10-26
- **Status**: DONE

## Why this matters

Budgets were locked to the current month, so users could not review last
month's limits or plan the next one even though the data model stores a month
per budget.

## What shipped

- `ChangeBudgetMonth` event normalizes the requested month and reloads progress.
- `BudgetBloc` keeps `_selectedMonth` (initialized to the current month);
  `AddBudget` uses the selected month.
- `BudgetLoaded`/`BudgetEmpty` expose the selected month.
- `/budgets` shows a localized month selector with previous/next controls above
  the hero or empty state.
- Existing budgets keep their own month when edited.

## Tests

- BLoC: changing month reloads exactly that month and exposes it in the state.
- Integration: create a budget, move to the previous month (empty), return and
  see the budget again.

## Done criteria

- [x] Previous/next month reloads without touching other months.
- [x] Adding a budget targets the selected month.
- [x] Analyze, unit coverage, coverage gate, and Linux integration pass.
