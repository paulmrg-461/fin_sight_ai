# Plan 011: Add a bottom navigation bar and hamburger drawer

> **Executor instructions**: Follow step by step; run every verification; update
> the status row. STOP if GoRouter cannot keep existing route names inside a
> `StatefulShellRoute` without breaking deep links.
>
> **Drift check**: `git diff --stat da07d39..HEAD -- lib/app lib/core/routing lib/features/*/presentation/screens lib/l10n test/app integration_test`

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: 002, 004
- **Category**: direction / UX
- **Planned at**: commit `da07d39`, 2026-10-23

## Why this matters

The app bar has accumulated period, theme, settings, sync, account, filter and
add actions; users cannot tell global navigation from screen actions. This plan
moves global navigation to a standard bottom bar plus a hamburger drawer, keeps
contextual actions in the app bar, and preserves every existing route and state.

## Current state

- `lib/core/routing/app_router.dart` — flat `GoRouter` with 11 top-level routes.
- `lib/app/app.dart` — `MaterialApp.router` with `routerConfig: router`.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` — AppBar with
  title, period picker, theme toggle, settings, sync chip, account.
- `lib/features/wallets/presentation/screens/wallet_screen.dart` — AppBar with
  Money title and a settings icon.
- Branch screens: `TransactionScreen`, `BudgetScreen`,
  `ScheduledPaymentScreen`, `WalletScreen` (each owns a `Scaffold`/`AppBar`).
- Secondary screens: `DebtListScreen`, `CategoriesScreen`, `OcrScreen`,
  `AiCoachScreen`, `SettingsScreen`, `LoginScreen`.
- `lib/core/routing/app_routes.dart` — names/paths to preserve.

Conventions: Material 3, `NavigationBar`/`Drawer`, `Theme.of(context)` tokens,
ARB copy, `BlocBuilder` for account/sync state.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Generate l10n | `flutter gen-l10n` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues |
| Unit | `flutter test --coverage` | all pass |
| Coverage | `dart run tool/check_coverage.dart` | passed |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |

## Scope

**In scope**
- `lib/app/main_shell.dart` (new)
- `lib/core/routing/app_router.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` (+ generated)
- AppBars of: dashboard, transactions, budgets, scheduled payments, money
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` quick actions
- `test/app/app_test.dart`, `test/app/main_shell_test.dart` (new)
- `integration_test/app_flow_test.dart`
- `specs/SPEC-navigation.md`

**Out of scope**
- Redesigning screen bodies or feature state.
- Removing any route or feature.
- Adding authentication requirements to secondary routes.

## Steps

### Step 1: Add localization keys

Add to both ARBs and regenerate:
`dashboard` (Dashboard/Inicio), `mainMenu` (Main/Menú principal),
`more` (More/Más), `preferences` (Preferences/Preferencias),
`openMenu` (Open menu/Abrir menú).

**Verify**: `flutter gen-l10n`; `grep dashboard lib/l10n/app_localizations.dart`.

### Step 2: Create the shell

Create `lib/app/main_shell.dart` with:

1. `ShellScope extends InheritedWidget` exposing `openDrawer()` and
   `goToPrimary(String routeName)`; `ShellScope.maybeOf(context)`.
2. `AppMenuButton` — `IconButton(icon: menu, tooltip: l10n.openMenu, onPressed:
   ShellScope.maybeOf(context)?.openDrawer)`; falls back to
   `Scaffold.maybeOf(context)?.openDrawer()`.
3. `MainShell` — Stateful, owns `GlobalKey<ScaffoldState>` and receives
   `StatefulNavigationShell navigationShell` + `ThemeController`.
   - `Scaffold(key, drawer: AppDrawer(...), body: ShellScope(... navigationShell),
     bottomNavigationBar: NavigationBar(selectedIndex: navigationShell.currentIndex,
     onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation:
     i == navigationShell.currentIndex), destinations: [...5...]))`.
   - Destinations use `l10n.dashboard`, `transactions`, `budgets`,
     `scheduledPayments`, `money` with stable icons.
4. `AppDrawer`:
   - header with app name and `AuthBloc` email when authenticated;
   - `DrawerButton`/ListTiles for the five primary routes (call
     `goToPrimary`), then secondary routes (`context.pushNamed` after closing);
   - secondary: debts, categories, ocr, ai-coach, settings;
   - theme `SwitchListTile` using `ThemeController`;
   - optional sync chip at the bottom (reuse `SyncStatusChip`).
   - Close the drawer before navigating (`Navigator.of(context).pop()` or
     `scaffoldKey.currentState?.closeDrawer()`).

**Verify**: `flutter analyze`.

### Step 3: Refactor the router

In `app_router.dart`, wrap the five primary routes in
`StatefulShellRoute.indexedStack`:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) => MainShell(
    navigationShell: navigationShell,
    themeController: themeController,
  ),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: dashboardPath, name: dashboardName, builder: ...)]),
    // transactions, budgets, scheduled-payments, money
  ],
),
// existing secondary routes stay top-level:
// debts, categories, ocr, ai-coach, settings, login
```

Keep `buildRouter({themeController, receiptImagePicker})` and every route
name/path unchanged. `initialLocation` stays `/dashboard`.

**Verify**: `flutter analyze`; `flutter test test/app/app_test.dart`.

### Step 4: Declutter app bars

- Dashboard: add `leading: const AppMenuButton()`; remove the theme toggle and
  settings `IconButton`s. Keep period filter, sync chip, account.
- Transactions, Budgets, Scheduled payments, Money: add
  `leading: const AppMenuButton()` to their `AppBar`s.
- Money: remove the settings `IconButton`.
- Secondary screens: leave `AppBar` leading untouched (back arrow).
- Dashboard quick actions: use `ShellScope.maybeOf(context)?.goToPrimary(route)`
  for the five primary routes; keep `pushNamed` for secondary routes.

**Verify**: `flutter analyze`; no duplicate theme/settings actions remain
(`grep -n "switchToLight\|settings" dashboard_page.dart wallet_screen.dart`).

### Step 5: Tests

- `test/app/main_shell_test.dart` (new):
  - pump `FinSightApp` with mocked blocs and an in-memory router;
  - tap each bottom destination and assert the branch screen;
  - open the drawer from the dashboard, tap Debts, assert the debts screen and
    no bottom bar on that route; back returns to the shell;
  - toggle the theme from the drawer.
- Update `test/app/app_test.dart` finders where `Transactions`/`Budgets`/etc.
  now appear in both the bar and the screen. Use `find.descendant` or
  `find.widgetWithText(NavigationBar, ...)`.
- Integration: existing router navigation must still pass; add one flow that
  taps `Money` in the bottom bar and `Settings` in the drawer.
- Ensure login remains full-screen (no bottom bar).

## Test plan

Follow the mock/wiring pattern in `test/app/app_test.dart`. Use
`tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Money')))`
for destinations.

## Done criteria

- [ ] Bottom bar shows exactly five primary destinations and switches branches.
- [ ] Drawer opens from all five primary screens and closes on navigate.
- [ ] Secondary routes keep a back arrow and no bottom bar.
- [ ] No theme/settings global actions remain in branch app bars.
- [ ] Existing route names/paths unchanged.
- [ ] `flutter analyze`, unit coverage, coverage gate, Linux integration pass.
- [ ] `plans/README.md` updated.

## STOP conditions

- `StatefulShellRoute` cannot preserve an existing route name/path used by
  tests or deep links.
- A branch screen's `Scaffold`/`AppBar` cannot find `ShellScope`; report instead
  of duplicating global keys.
- The drawer's Settings push loses the shell stack on back.

## Maintenance notes

- New primary destinations require a branch, a destination, and a drawer entry.
- Secondary routes must stay outside the shell unless they need the bottom bar.
- Reviewer: verify the selected bottom index matches deep links and drawer
  navigation, and that branch state survives tab switches.
