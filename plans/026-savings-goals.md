# Plan 026: Savings goals with dashboard and AI context

> **Executor instructions**: Local-first storage, pure domain math, and no
> writes outside the feature. Dashboard and AI read through existing blocs/use
> cases.

## Status

- **Priority**: P2
- **Effort**: L
- **Risk**: LOW
- **Depends on**: 016, 020, 023
- **Category**: direction
- **Planned at**: commit 8be302d, 2026-10-27
- **Status**: DONE

## Why this matters

Users could budget spending and pay down debt but had no way to track money
being saved toward a goal, and the AI could not see that progress.

## What shipped

- Domain: `SavingsGoalEntity` + `SavingsContribution` with saved/remaining/
  progress/completion, repository contract, and create/contribute/delete use
  cases with validation and currency rounding.
- Data: Hive `savings_goals` box (cleared with account data), JSON model,
  defensive parsing, repository error mapping.
- UI: `/savings` screen with total-saved hero, goal cards, progress, target
  dates, create dialog, add-money dialog, and confirmed delete; drawer entry.
- Dashboard: savings summary card (saved/target, goal count, next target date)
  fed by `SavingsBloc`, hidden when empty.
- AI: `CoachContextBuilder` includes goal count and saved/target totals for both
  insights and free-form chat.
- All copy EN/ES; amounts via `MoneyText`.

## Scope notes

- Savings goals are synced by plan 027 (`0007_savings_goals.sql`).
- Contributions are deposits (no withdrawals); deleting a goal removes its
  history on device.

## Tests

- Domain: progress/equality, use-case validation/rounding, repository failures.
- Data: JSON round-trip/corruption, Hive add/contribute/delete, error mapping.
- BLoC: load/empty/create/contribute/delete/failure.
- AI: goal totals reach the prompt.
- Integration: create a goal and add money; persisted amounts asserted.

## Done criteria

- [x] Users can create goals, add money, and see progress.
- [x] Dashboard and AI reflect savings progress.
- [x] Analyze, coverage gate, and Linux integration pass.
