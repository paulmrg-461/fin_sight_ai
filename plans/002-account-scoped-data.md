# Plan 002: Scope local data to one account and clear it safely

> **Executor instructions**: Follow step by step; run every verification.
> Update `plans/README.md` when done. If a STOP condition occurs, stop and
> report.
>
> **Drift check**: `git diff --stat 4e42297..HEAD -- lib/features/auth lib/core/services lib/core/di lib/main.dart lib/features/sync/data/datasources test/features/auth`
> Compare the excerpts below with live code; mismatch = STOP.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: none
- **Category**: security
- **Planned at**: commit `4e42297`, 2026-10-23

## Why this matters

All Hive boxes are opened once under fixed names and `signOut()` only clears the
secure-storage token. If user A signs out and user B signs in on the same
device, B sees A's transactions/debts/budgets/receipts, and A's pending sync
queue is pushed under B's JWT into B's cloud account. That is a privacy
disclosure and permanent ledger contamination.

Policy for this plan: **one account per device**. Signing out requires explicit
confirmation and erases local data; before the first login after a legacy
upgrade, an account-scope check wipes data whose owner does not match the
stored session. The app still works fully offline while signed out; it simply
starts empty after an explicit sign-out.

## Current state

- `lib/features/auth/data/repositories/auth_repository_impl.dart:131-145` —
  `signOut()` clears `SessionStorage` only.
- `lib/core/di/injection.dart:47-72` — `StorageModule.provideAppBoxes()` opens
  every box with fixed names; `AppBoxes` holds them.
- `lib/features/auth/domain/entities/auth_session.dart:4-12` — `userId` exists
  but is unused for storage.
- `lib/features/sync/data/repositories/sync_repository_impl.dart:107-120` —
  pending operations are pushed with the current token.
- `lib/main.dart:63` — `AuthBloc` listener dispatches `SyncNow` on
  `AuthAuthenticated`.
- `lib/features/auth/presentation/widgets/account_button.dart` — sign-out
  button; no confirmation dialog.
- Existing tests: `test/features/auth/data/repositories/auth_repository_impl_test.dart`,
  `test/features/auth/presentation/bloc/auth_bloc_test.dart`.

Conventions: `Result<T>` at boundaries; `CacheFailure` for storage errors;
sealed `AuthState`; `@LazySingleton` injection. Follow
`lib/core/locale/hive_locale_repository.dart` for small settings-backed
repositories.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Generate | `dart run build_runner build --delete-conflicting-outputs` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues |
| Tests | `flutter test` | all pass |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |
| Coverage | `dart run tool/check_coverage.dart` | passed |

## Scope

**In scope**
- `lib/core/services/local_data_scope.dart` (new)
- `lib/core/services/app_boxes.dart`, `lib/core/di/injection.dart`
- `lib/features/auth/**` (repository, use cases, bloc, events/states, account button)
- `lib/main.dart`
- `test/features/auth/**`, `test/core/services/local_data_scope_test.dart` (new)
- `integration_test/app_flow_test.dart` (one account-switch flow)

**Out of scope**
- Sync pull/push semantics (plan 005), category ids (plan 006).
- Encrypting Hive (future work).

## Steps

### Step 1: Add `LocalDataScope`

Create `lib/core/services/local_data_scope.dart`:

```dart
abstract interface class LocalDataScope {
  Future<String?> getOwnerUserId();
  Future<void> setOwnerUserId(String? userId);
  Future<void> clearAllUserData(); // boxes + sync queue/meta, not preferences
}
```

Hive-backed implementation receives `AppBoxes` and uses the `settings` key
`owner_user_id`. `clearAllUserData()` clears:
`transactions`, `debts`, `receipts`, `budgets`, `wallets`, `walletTransfers`,
`categories`, `scheduledPayments`, `syncQueue`, `syncMeta`.
It must **not** clear `settings` currency/locale keys; only remove
`owner_user_id` when `setOwnerUserId(null)` is called explicitly.
Register it with a `@module` provider (add to `CoreModule` or a new
`LocalDataModule`) and regenerate DI.

**Verify**: `flutter analyze` → clean.

### Step 2: Enforce scope on sign-in and sign-out

1. Inject `LocalDataScope` into `AuthRepositoryImpl`.
2. After `_storage.write(session)` in `signIn`/`signUp`/`refresh` paths, call
   `setOwnerUserId(session.userId)`.
3. In `signOut()`, after clearing secure storage and before returning, call
   `clearAllUserData()` and `setOwnerUserId(null)`. If clearing fails, return
   `CacheFailure('Could not clear local data.', code: 'local_clear_failed')`
   and keep the session signed out only if storage clear succeeded.
4. Add an `AccountScopeService` in
   `lib/features/auth/data/services/account_scope_service.dart` (data layer,
   where importing `SessionStorage` and the Hive-backed `LocalDataScope` is
   legal) that takes both dependencies:
   - no stored session → `Right(false)`;
   - owner null → set to session.userId → `Right(false)`;
   - owner == session.userId → `Right(false)`;
   - owner != session.userId → `clearAllUserData()`, `setOwnerUserId(session.userId)`,
     `Right(true)`.
5. In `lib/main.dart`, immediately after `configureDependencies()` and **before**
   due-payment processing/BLoC creation, run
   `await getIt<AccountScopeService>().ensure();`. This ensures no feature bloc
   loads another account's data on startup. Do NOT place this orchestration in
   the domain layer: AGENTS.md forbids domain imports of data/infrastructure.

**Verify**: unit tests for both branches; `flutter test test/features/auth` green.

### Step 3: Confirm sign-out in the UI

In `account_button.dart`, before dispatching `SignOutRequested`, show an
`AlertDialog`:
- title: `l10n.signOutQuestion` ("Sign out and erase local data?");
- body: `l10n.signOutEraseBody` ("Local transactions and pending changes on this
  device will be deleted. Sync first if you need them.");
- actions: cancel / `l10n.signOut` (destructive style).
Add keys to both ARBs and regenerate localizations.

**Verify**: `flutter gen-l10n`; `flutter analyze`; widget/integration sign-out
still passes.

### Step 4: Avoid stale in-memory data after sign-out

In `lib/main.dart`, extend the existing `authBloc.stream.listen`:
- on `AuthUnauthenticated`, dispatch reloads to clear feature blocs:
  `LoadTransactions`, `LoadDebts`, `LoadReceipts`, `LoadDashboard`,
  `LoadBudgets`, `LoadWallets`, `LoadScheduledPayments`, `LoadCategories`.
These reads now see empty boxes, so the UI shows empty states. Do not close
blocs.

**Verify**: integration test in Step 5 shows empty states after sign-out.

### Step 5: Add tests

Unit:
- `test/core/services/local_data_scope_test.dart`: real temp Hive; write a
  record in each box, set owner, clear, assert all data boxes empty and
  settings preferences preserved.
- `test/features/auth/data/services/account_scope_service_test.dart`:
  `AccountScopeService` sets/clears owner and wipes on mismatch;
  `AuthRepositoryImpl.signOut` clears local data; signIn records owner.

Integration (`integration_test/app_flow_test.dart`):
- Sign in with fake auth, add a transaction, sign out (confirm), assert
  dashboard empty and transaction list empty; sign in again, assert the old
  record does not return.

## Test plan

Follow `test/features/auth/data/repositories/auth_repository_impl_test.dart`
for mock structure and `test/core/locale/hive_locale_repository_test.dart` for
temp-Hive setup.

## Done criteria

- [ ] `grep -rn "clearAllUserData\|owner_user_id" lib` shows the new service and
      its callers.
- [ ] `flutter analyze` exits 0; `flutter test --coverage` passes; coverage gate passes.
- [ ] Integration account-switch flow passes.
- [ ] No secret/PII is logged.
- [ ] `plans/README.md` updated.

## STOP conditions

- `AuthRepositoryImpl` has acquired additional session-persistence paths not
  listed above.
- Clearing boxes while a BLoC is mid-write throws; do not swallow it — report.
- The product decision "sign-out erases local data" conflicts with an existing
  spec/README promise; surface the conflict instead of choosing silently.

## Maintenance notes

- Any new Hive data box must be added to `clearAllUserData()`.
- If multi-account support on one device becomes a requirement, replace the
  wipe policy with per-user box namespaces; do not relax this plan without a
  migration.
- Reviewer should scrutinize the ordering in `main.dart`: scope check must run
  before any data-loading BLoC event.
