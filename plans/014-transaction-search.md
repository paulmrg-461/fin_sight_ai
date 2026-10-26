# Plan 014: Search transactions by text

> **Executor instructions**: Keep filtering client-side over the active period;
> do not add another Hive read per keystroke.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 008
- **Category**: direction
- **Planned at**: commit 89b181e, 2026-10-26
- **Status**: DONE

## Why this matters

The transaction list could only be narrowed by date range and category chips.
Finding a specific merchant or note required scrolling an ever-growing ledger.

## What shipped

- `SearchTransactions` event and in-memory filtering over the loaded period.
- The BLoC caches the period rows (`_periodTransactions`) so every keystroke
  filters the cache instead of re-reading Hive.
- Matches description, category, or the formatted amount, case-insensitively.
- Search composes with the date-range filter and survives add/edit/delete
  reloads; `LoadTransactions` clears both date and query.
- `TransactionScreen` owns the search controller, shows a clear button, and
  renders “No matching transactions” with a clear-search action.
- Empty/loaded states carry `query` so the field and empty copy stay in sync.

## Tests

- BLoC: filter by category, search inside a date range, no-match empty state,
  and restoring the cached period on clear without a second read.
- Integration: two transactions, search one, no-match state, clear restores.

## Done criteria

- [x] Search filters without extra storage reads.
- [x] Works together with the date filter.
- [x] Analyze, unit coverage, coverage gate, and Linux integration pass.
