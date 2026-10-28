# Plan 036: Import transactions from CSV

> **Executor instructions**: Parse tolerantly in pure Dart, dedupe before writing,
> and never create partial duplicates per row.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 015
- **Category**: direction
- **Planned at**: commit dd5ae34, 2026-10-27
- **Status**: DONE

## What shipped

- `TransactionCsvImporter` (pure Dart):
  - EN/ES headers and headerless rows;
  - RFC-4180 quotes, escaped quotes, newlines;
  - ISO and day-first dates, thousand/decimal separators (1.234,56);
  - parenthesized negative amounts, income/expense synonyms;
  - per-row errors with physical line numbers.
- `ImportTransactionsCsvUseCase`:
  - validates at least one row;
  - skips rows already in the ledger and duplicates inside the same file
    (date, amount, type, category, description);
  - imports through `AddTransactionUseCase` (UUID + sync queue + validation);
  - returns imported/skipped/failed counts and row errors.
- `/import-csv` screen (drawer) with format sample, multiline paste field,
  progress, localized result card; refreshes `TransactionBloc` after import.
- EN/ES copy.

## Notes

- Paste-first (no file picker) keeps the slice dependency-free; a native picker
  can reuse the same use case later.
- Ambiguous `MM/dd/yyyy` dates are treated as day-first; ISO `yyyy-MM-dd` is
  preferred.

## Tests

- Parser: headers, quotes, dates, decimals, invalid rows, negatives, blanks.
- Use case: import, existing/in-file duplicates, failures, empty CSV.
- Cubit: running/success/failure.
- Integration: paste two rows, import, re-import skips both.

## Done criteria

- [x] CSV import works with dedupe and validation.
- [x] UI reports imported/skipped/failed.
- [x] Analyze, coverage gate, and Linux integration pass.
