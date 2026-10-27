# Plan 031: Global search across local finance data

> **Executor instructions**: Search the blocs already loaded by the shell; no new
> storage reads or dependencies.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 014, 026
- **Category**: direction
- **Planned at**: commit 6bbb08e, 2026-10-27
- **Status**: DONE

## What shipped

- `/search` screen opened from the dashboard search icon.
- One field searches the currently loaded:
  - transactions (description, category, amount);
  - debts (creditor);
  - savings goals (name);
  - scheduled payments (name/category);
  - receivables (debtor).
- Results are grouped with section headers, capped at 10 each, and navigate to
  their section on tap.
- Empty query shows guidance; no matches shows a separate state.
- Case-insensitive matching and clear button; EN/ES copy.

## Tests

- Integration: seed a transaction, debt, and goal, then search each one and the
  no-results state.

## Notes

- Search uses the states currently loaded by the root blocs, so a transaction
  date filter can narrow what the transaction bloc exposes.
- Budget entries are not included yet; budgets live by month and have dedicated
  navigation.

## Done criteria

- [x] Search finds transactions, debts, goals, schedules, and receivables.
- [x] Results navigate to their sections.
- [x] Analyze, coverage gate, and Linux integration pass.
