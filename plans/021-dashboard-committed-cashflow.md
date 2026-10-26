# Plan 021: Show committed cashflow on the dashboard

> **Executor instructions**: Reuse `GetCommittedCashflowUseCase`; never add a
> second calculation. Refresh the dashboard when the user returns to the tab.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 009, 012, 016
- **Category**: direction
- **Planned at**: commit 6fff33b, 2026-10-26
- **Status**: DONE

## Why this matters

The committed projection lived only inside `/scheduled`. The home screen — the
one users open every day — never answered “how much of my money is already
committed this month?”.

## What shipped

- `DashboardBloc` injects `GetCommittedCashflowUseCase` and adds the 30-day
  projection to `DashboardLoaded.committed30`.
- Projection failures hide the card; they never fail the dashboard.
- `Committed30DaysCard` shows the total plus the next three commitments and
  opens `/scheduled` on tap.
- The dashboard refreshes when the user taps its bottom-navigation tab, so
  schedules/debts added elsewhere appear immediately. Startup still loads the
  dashboard first (no extra eager reads).
- The card only renders when the projection has payments.

## Tests

- BLoC: committed projection is exposed when available.
- Widget: total, three-row preview, and tap navigation.
- Integration: a debt minimum appears on the dashboard; existing schedule flows
  stay green.

## Done criteria

- [x] Dashboard shows committed 30-day outflows without extra startup work.
- [x] Returning to the tab refreshes projections.
- [x] Analyze, unit coverage, coverage gate, and Linux integration pass.
