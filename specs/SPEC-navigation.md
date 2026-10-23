# Spec: app shell navigation (bottom bar + drawer)

## Objective

Replace the crowded top app bars with a clear, global navigation model:

- **Bottom navigation bar** for the five primary destinations.
- **Hamburger drawer** for secondary features, settings, and theme.
- Each screen keeps only its own contextual actions in the app bar.

## Primary destinations (bottom bar)

| Index | Route | Label EN / ES |
| --- | --- | --- |
| 0 | `dashboard` | Dashboard / Inicio |
| 1 | `transactions` | Transactions / Transacciones |
| 2 | `budgets` | Budgets / Presupuestos |
| 3 | `scheduled-payments` | Scheduled / Programados |
| 4 | `money` | Money / Dinero |

Tapping a destination preserves the state of each branch (indexed stack).

## Drawer

- Header: app name, signed-in email when available, sync status chip.
- “Main” group: the five primary destinations (mirrors the bottom bar).
- “More” group:
  - Debts / Deudas
  - Categories / Categorías
  - Scan receipt / Escanear recibo
  - AI coach / Coach IA
- “Preferences”:
  - Settings / Ajustes
  - Theme toggle (light/dark) with the current mode
- The drawer closes before navigating.

Primary destinations switch branches; secondary destinations are pushed over
the shell so the back arrow returns to the previous tab.

## App bars

- Primary branch roots show a hamburger leading button that opens the drawer.
- Secondary routes keep the default back arrow and do **not** show the bottom
  bar.
- Remove global actions from screen app bars:
  - Dashboard: remove theme toggle and settings icons; keep period filter,
    sync status, and account button.
  - Money: remove the settings icon.
- Keep screen-specific actions: transaction filter/add, scheduled categories,
  budget add (FAB), etc.

## Behavior and state

- All existing route names and paths remain valid for deep links and tests.
- Dashboard quick actions:
  - primary destinations switch the shell branch;
  - secondary destinations push over the shell.
- Android back from a non-first branch returns to the dashboard branch before
  exiting, per `StatefulShellRoute` defaults.
- Login remains a full-screen route outside the shell.

## Accessibility

- Bottom destinations and drawer entries have labels and 48×48 dp targets.
- Hamburger tooltip is localized (`openMenu`).
- The selected destination is exposed by `NavigationBar`.

## Localization

New keys: `dashboard`, `mainMenu`, `more`, `preferences`, `openMenu`.
Reuse existing labels for features/settings.

## Tests

- Router: primary routes render inside the shell; secondary routes do not.
- Widget: bottom bar switches among all five destinations; drawer opens from a
  branch root and navigates to Debts/Settings; theme toggle works.
- Existing app/integration flows continue to pass, updating finders where a
  label now appears both in the bar and on screen.
