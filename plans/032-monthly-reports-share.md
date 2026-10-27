# Plan 032: Monthly reports with native CSV sharing

> **Executor instructions**: Reuse `DashboardCalculator` and `TransactionCsv`.
> Sharing is behind `ReportExporter` so tests never open a share sheet.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 010, 015
- **Category**: direction
- **Planned at**: commit 63dfd18, 2026-10-27
- **Status**: DONE

## What shipped

- `/reports` (drawer → Reports) with previous/next month navigation.
- Monthly summary (balance, income, expenses, month-over-month change) and
  category breakdown bars, derived from one current + one previous range read via
  `DashboardCalculator`.
- `ReportsBloc` states: loading, loaded, empty, failure; share status.
- **Share CSV** builds `TransactionCsv` for the month, writes it to a temp file,
  and opens the native share sheet (`share_plus`).
- `ReportExporter` interface + `ShareReportExporter` (injectable) keep the share
  sheet out of tests; fake exporter drives integration.
- Share success/failure SnackBars, localized; empty month has guidance.
- EN/ES copy; route from drawer.

## Tests

- BLoC load/empty/change month/share success/share failure/dismiss.
- MonthlyReport equality; exporter default platform path and failure mapping.
- Integration: two transactions produce a report, share records the CSV, and
  the previous month shows the empty state.

## Done criteria

- [x] Monthly report renders summary and breakdown.
- [x] CSV sharing works behind a testable interface.
- [x] Analyze, coverage gate, and Linux integration pass.
