# 043 — Chart semantics, sync conflict feedback, and goldens

**Priority:** P2 · **Effort:** S · **Status:** DONE

## Changes

- `CategoryPieChart` announces the category percentages; `MonthlyComparisonChart` announces what it compares. Both exclude the fl_chart canvas from semantics and keep the readable totals.
- `MainShell` listens for a sync that resolved conflicts and shows a snackbar with the count (`syncConflictsResolved`), localized in English and Spanish.
- New goldens: `AppDrawer` (authenticated) and `AppEmptyState`.
- Tests: `charts_accessibility_test.dart`, the snackbar case in `main_shell_test.dart`, and stable golden runs.
