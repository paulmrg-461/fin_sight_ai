# Plan 022: Duplicate a transaction

> **Executor instructions**: Copies are new records with a fresh id and today's
> date; the original must never be modified.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 008
- **Category**: direction
- **Planned at**: commit dc565ee, 2026-10-26
- **Status**: DONE

## Why this matters

Recurring one-off expenses (same lunch, same fare) had to be re-entered field by
field even though the edit form already had every value.

## What shipped

- Editing a transaction now shows **Save as copy** below **Save changes**.
- Copying dispatches `AddTransaction` with the current form values, no id, and
  today's calendar date.
- The original row and its receipt path are untouched; the copy gets a fresh id
  and joins the normal sync queue.

## Tests

- Integration: edit a transaction, save as copy, assert two rows with distinct
  ids and the same amount.
- Existing edit/delete/undo flows stay green.

## Done criteria

- [x] Copy creates a new record with a new id.
- [x] Copy uses today's date and keeps the other fields.
- [x] Analyze, coverage gate, and Linux integration pass.
