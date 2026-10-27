# Plan 029: Show the impact of extra debt payments

> **Executor instructions**: Reuse `DebtPayoffCalculator.buildPaymentPlan`; do
> not add another amortization implementation.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 023
- **Category**: direction
- **Planned at**: commit 4adab62, 2026-10-27
- **Status**: DONE

## What shipped

- `PayoffEstimate` now carries `interestSaved` and `monthsSaved` versus paying
  only the minimum.
- The bloc builds the baseline and custom plans with the same calculator at the
  same instant, so the comparison is deterministic.
- Debt details show a highlighted **Interest saved / Months earlier** card when
  a custom payment beats the minimum.
- Selecting the minimum produces no misleading “savings” card.

## Tests

- BLoC asserts both savings values are positive when paying above the minimum.
- Existing plan/calculator tests remain green.

## Done criteria

- [x] Extra payments show interest and time saved versus the minimum.
- [x] No impact card when there is nothing to save.
- [x] Analyze, coverage gate, and Linux integration pass.
