# Plan 015: Copy transactions as CSV

> **Executor instructions**: Export the currently visible list (date range,
> category chips, and search all apply). No new dependencies.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 008, 014
- **Category**: direction
- **Planned at**: commit e65ec1b, 2026-10-26
- **Status**: DONE

## Why this matters

Users need their ledger in a spreadsheet for taxes, budgeting, or sharing with
an accountant. The app had no way out of the local store.

## What shipped

- `TransactionCsv` (pure Dart): stable header, ISO dates, raw positive amounts,
  English type tokens, and RFC-4180-style escaping for commas, quotes, and
  line breaks.
- Transactions app-bar action copies the **visible** rows to the clipboard and
  confirms with a pluralized snackbar (“Copied 1 transaction…”).
- Action is disabled outside the loaded state.
- No platform plugin: works on desktop, mobile, and tests.

## Tests

- Pure CSV: header/rows, ISO dates, income/expense, empty wallet, escaping,
  empty list.
- Integration: copy one visible transaction, verify the snackbar and clipboard
  payload.

## Done criteria

- [x] CSV escapes correctly and contains a header.
- [x] Copy respects date/category/search filters.
- [x] Analyze, unit coverage, coverage gate, and Linux integration pass.
