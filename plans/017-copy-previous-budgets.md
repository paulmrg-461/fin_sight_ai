# Plan 017: Copy last month's budgets

> **Executor instructions**: Only offer the action when the previous month has
> limits; copying must create new budgets for the selected month, never edit the
> source month.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 016
- **Category**: direction
- **Planned at**: commit c79884d, 2026-10-26
- **Status**: DONE

## Why this matters

Most monthly limits repeat month after month. After adding month navigation, an
empty month still forced users to re-enter every category by hand.

## What shipped

- When the selected month is empty, the bloc also reads the previous month and
  stores `previousBudgetCount` on `BudgetEmpty`.
- `CopyPreviousBudgets` recreates each previous limit for the selected month
  through `AddBudgetUseCase` (new ids, target month), then reloads.
- The empty state shows **Copy previous month** only when there is something to
  copy; the selected month's data is never modified.
- Copy failures surface through the normal budget failure state.

## Tests

- BLoC: empty month exposes the previous count; copying sends one add per limit
  with the selected month and reloads.
- Integration: add a budget in the previous month, move forward, copy it, and
  see the same limit in the selected month.

## Done criteria

- [x] Copy action appears only when the previous month has budgets.
- [x] Copied budgets belong to the selected month with new ids.
- [x] Analyze, unit coverage, coverage gate, and Linux integration pass.
