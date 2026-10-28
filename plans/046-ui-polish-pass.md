# 046 — UI polish pass across modules

**Priority:** P2 · **Effort:** M · **Status:** DONE

## Goal

Make the app feel like one designed product: shared surfaces, consistent
progress visuals, calmer hierarchy, and less plain list content.

## Shared design system

- `AppEmptyState`/`AppErrorState`: glowing icon halo, gradient card wash,
  larger titles, readable line height.
- `AppSectionHeader`: gradient accent bar and tighter title/subtitle rhythm.
- Theme: consistent segmented buttons, extended FAB, popup menus, 66 px app
  bars, stadium nav indicator, and more comfortable list-tile padding.
- New `AppProgressBar`: animated, rounded, gradient fill with a track and
  optional semantics; used by budgets, savings, debts, receivables, wallets,
  and dashboard budget alerts.

## Module changes

- Transactions: grouped by day with localized Today/Yesterday headers, a divider,
  and the day's net amount; transactions are sorted newest-first inside groups.
- Budgets: icon badge per category, spent/limit stack, percentage pill
  (emerald → warning → danger), animated progress, and a remaining/over icon.
- Annual reports: each month shows income/expense labels above a pair of
  proportional mini bars, making the year's trend glanceable.
- Reports: month/year text uses Material localizations (no intl locale init).
- All progress surfaces now share height, radius, animation, and semantics.

## Verification

- `flutter analyze`, `flutter test --coverage`, coverage gate, 38 Linux
  integration flows.
- Goldens regenerated and verified twice for stability: drawer, empty state,
  budget alerts.
- New widget test covers transaction day grouping and daily nets.
