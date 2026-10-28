# 042 — Move account and sync controls into the drawer

**Priority:** P2 · **Effort:** S · **Depends on:** 011 (navigation shell), 028 (sync diagnostics)

## Problem

The dashboard app bar carried four actions: search, account, sync, and period.
The account button became a sign-out icon whenever the user was authenticated,
and the sync chip showed a cloud plus badges. Both compete with the ledger
content, and sign-out is a rare, destructive action that should not sit next to
the search and period controls.

## Scope

- Remove the account control and the sync chip from the dashboard app bar.
- Add a labelled **Sync** row and an **Account** row to the navigation drawer.
- Keep the sync diagnostics dialog and the sign-out confirmation unchanged.
- Signed-out users open login from the drawer's **Sign in** row.
- Localize the new row labels with the existing strings.

## Out of scope

- Drawer redesign, grouping, or reordering other entries.
- Moving search or the period picker.
- A dedicated account screen.

## Design

- `AccountTile` replaces `AccountButton`. It renders a `ListTile`:
  - authenticated → **Sign out** with a logout icon, opens the existing
    confirmation dialog, closes the drawer, and dispatches `SignOutRequested`;
  - unauthenticated → **Sign in** with `signInToSync` as subtitle and pushes the
    login route.
  - `AuthLoading` → spinner row.
- `SyncStatusChip` gains an `expanded` flag. In expanded mode it renders a
  `ListTile` titled **Sync**, with the existing status text as subtitle and the
  same tap behaviour: open login, show entity failures, or trigger a manual
  sync. The icon button variant remains available.
- The drawer places both rows after the preferences section, separated by a
  divider, with the sync row first.
- The dashboard app bar keeps the menu, logo, search, and period picker.

## Tests

- `main_shell_test.dart`:
  - the dashboard app bar shows no logout or cloud icons;
  - the drawer shows **Sync** and **Sign out** when authenticated;
  - tapping **Sign out** opens the confirmation dialog;
  - the drawer shows **Sign in** when signed out.
- `app_flow_test.dart`: sign-in, sign-out, sign-out-erases-data, offline session,
  and the sync-offline diagnosis now go through the drawer. A `closeDrawer`
  helper drives `ScaffoldState` directly so the following steps keep working.

## Verification

```bash
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart
flutter test -d linux integration_test/app_flow_test.dart
```

## Risks

- Sign-in is less discoverable without the app-bar person icon. The drawer
  header still shows the signed-in email or "Sign in to sync", and the drawer
  row is a single tap away.
- Sign-out closes the drawer before clearing data so the confirmation feedback
  is not hidden behind it.
