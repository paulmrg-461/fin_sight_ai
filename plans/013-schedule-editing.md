# Plan 013: Edit scheduled payments in place

> **Executor instructions**: Follow the transactions/budgets editing pattern
> (plan 008). Do not change the deterministic generated-transaction id contract.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 008, 012
- **Category**: direction
- **Planned at**: commit da33db9, 2026-10-26
- **Status**: DONE

## Why this matters

Schedules could only be created or deleted. Fixing a typo in the amount, moving
the due day, or switching the wallet forced a delete plus a re-add, which lost
`createdAt`, `lastPaidAt`, and the sync identity, and produced two queue
operations.

## What shipped

- `ScheduledPaymentRepository.updatePayment` merges editable fields into the
  existing row, preserves `id`, `createdAt`, and `lastPaidAt`, stamps
  `updatedAt`, marks `isSynced = false`, and enqueues one upsert.
- `UpdateScheduledPaymentUseCase` validates name, amount, category, notes, and
  normalizes the due date to calendar midnight.
- `UpdateScheduledPayment` event/handler reloads the list without reprocessing
  due payments.
- `ScheduledPaymentForm(initial:)` prefills every field, shows
  “Edit scheduled payment” / “Save changes”, and dispatches the update.
- The card popup menu adds **Edit** next to pause/resume and delete.

## Tests

- Repository: in-place update, preserved audit dates, queue upsert, missing id.
- Use case: normalization, validation, repository failure.
- BLoC: update success/failure and no duplicate add/process.
- Integration: create a schedule, edit the amount, assert the same id and
  persisted amount.

## Done criteria

- [x] Editing keeps the same id and one queue operation.
- [x] Audit dates survive the edit.
- [x] Analyze, unit coverage, coverage gate, and Linux integration pass.
- [x] Docs/index updated.
