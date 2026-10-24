# Spec: UI/UX polish

## Objective

Make FinSight AI feel like a finished, professional finance product: a coherent
design system, clear hierarchy, responsive layouts, and consistent states.

## Design system

- Brand palette: emerald `#10B981`, teal `#14B8A6`, sky `#38BDF8`, navy
  `#070D18`/`#0B1220`, light canvas `#F4F7FB`.
- Material 3 with custom text weights, 20 px cards, 16 px inputs, 14–16 px
  buttons, 74 px navigation bar, and rounded dialogs/sheets.
- Surface containers, outline variants, and page transitions are centralized in
  `AppTheme`; screens must not hardcode colors or spacing tokens.
- Reusable components:
  - `AppContent` — centers content and caps width on tablets/desktop.
  - `BrandGradientCard` — emerald hero surface for balances and totals.
  - `AppSectionHeader` — consistent section title/subtitle/action.
  - `AppEmptyState` / `AppErrorState` — consistent empty and error panels.

## Screen changes

- **Dashboard**: period pill, gradient balance hero with income/expense/savings
  stats, donut chart with total, localized comparison labels, quick actions as
  icon tiles, responsive content, reusable empty/error states.
- **Login**: full-screen brand gradient, centered card, logo/wordmark, error
  panel, privacy footer, close/back affordance.
- **Money**: gradient total hero with bank/cash breakdown, account section,
  proportion bars per account, responsive content.
- **Scheduled**: gradient expected-income hero, reusable empty/error states,
  responsive content.
- **Settings**: grouped cards for currency, language, and categories, plus a
  brand footer.
- **Navigation**: localized short “Scheduled” tab label, haptic tab selection,
  gradient drawer header with localized wordmark.

## Rules

- All copy comes from ARB (EN/ES).
- Keep 48×48 dp targets and semantic labels.
- Preserve existing BLoC states and routes.
- Use `Theme.of(context)` tokens; no hardcoded colors in screens (brand
  constants or theme-derived container colors are acceptable).
- Tests must not depend on exact chip widgets where tiles replaced them; use
  stable keys (`quick-action-<route>`).

## Verification

`flutter analyze`, unit/widget tests, coverage gate, and the Linux integration
suite must pass. Android debug build must continue to compile.
