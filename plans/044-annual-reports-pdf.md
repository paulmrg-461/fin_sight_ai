# 044 — Annual reports with PDF sharing

**Priority:** P2 · **Effort:** M · **Status:** DONE

## Changes

- `AnnualReport` groups a year into twelve `AnnualMonthSummary` buckets and reuses `DashboardCalculator` for totals and category breakdown.
- `ReportsBloc` adds a monthly/annual mode (`ShowMonthlyReport`, `ShowAnnualReport`, `ChangeReportYear`) with `ReportsAnnualLoaded` and `ReportsAnnualEmpty`.
- `AnnualReportPdfBuilder` renders a pure-Dart PDF (totals, monthly table, category table, page footer) using built-in Helvetica.
- `ReportExporter` gained `sharePdf`; `ShareReportExporter` writes the bytes to a temp file and shares `application/pdf`.
- Reports screen: Monthly/Annual segmented switch, year selector, annual summary, monthly breakdown list, and the annual share action.
- Tests: aggregation, PDF header, exporter bytes/MIME, bloc share flow, and an integration flow that validates `%PDF` bytes.
