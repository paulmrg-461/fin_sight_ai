# Plan 030: Edit savings goals and show the monthly pace

> **Executor instructions**: Preserve contributions and the goal id on edit.
> Monthly pace is a pure entity calculation.

## Status

- **Priority**: P2
- **Effort**: S/M
- **Risk**: LOW
- **Depends on**: 026
- **Category**: direction
- **Planned at**: commit 4adab62, 2026-10-27
- **Status**: DONE

## What shipped

- `SavingsRepository.updateGoal` preserves id/contributions and re-enqueues sync;
  `UpdateSavingsGoalUseCase` validates name/target/id.
- `UpdateSavingsGoalEvent` + bloc handler reload the list.
- The goal dialog supports create **and** edit (prefilled name/target/date).
- Each goal with a future target date shows **Monthly to reach target**, computed
  by `SavingsGoalEntity.monthlyNeeded` (remaining / months, rounded).
- Card menu adds Edit alongside Delete.

## Tests

- Entity monthly pace (with/without date, completed).
- Repository edit keeps contributions; use-case validation; BLoC update.
- Integration: create goal, add money, edit the target, verify contributions
  survive.

## Done criteria

- [x] Goals can be edited without losing contributions.
- [x] Monthly pace appears when a deadline exists.
- [x] Analyze, coverage gate, and Linux integration pass.
